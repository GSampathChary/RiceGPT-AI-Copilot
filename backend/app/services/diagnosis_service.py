from __future__ import annotations

import json
import os
from urllib.parse import urlparse
from urllib.request import urlopen
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from uuid import uuid4

from fastapi import UploadFile

from app.ai.manager import ProviderManager
from app.ai.inference.image_processor import load_image_from_bytes
from app.ai.inference.keras_predict import KerasPredictor
from app.ai.inference.tensorflow_predict import TensorflowPredictor
from app.config.settings import Settings
from app.models.diagnosis import DiagnosisRecord
from app.schemas.diagnosis import DiagnosisExplanation, DiagnosisResponse
from app.services.history_service import HistoryService


class DiagnosisService:
    def __init__(self, settings: Settings, provider_manager: ProviderManager, history_service: HistoryService) -> None:
        self.settings = settings
        self.provider_manager = provider_manager
        self.history_service = history_service
        self.diseases = self._load_library("diseases.json")
        self._prepare_model_artifact()
        self.predictor = self._create_predictor()

    def _prepare_model_artifact(self) -> None:
        if self.settings.model_path and self.settings.model_path.exists():
            return
        if not self.settings.model_download_url:
            return
        target = self._download_model(self.settings.model_download_url)
        if target:
            self.settings.model_path = target

    def _download_model(self, url: str) -> Optional[Path]:
        parsed = urlparse(url)
        filename = Path(parsed.path).name or "rice_disease_model.pth"
        target_dir = self.settings.storage_dir / "models"
        target_dir.mkdir(parents=True, exist_ok=True)
        target = target_dir / filename
        if target.exists() and target.stat().st_size > 0:
            return target
        try:
            with urlopen(url, timeout=self.settings.request_timeout_seconds) as response:
                target.write_bytes(response.read())
            return target
        except Exception:
            return None

    def _load_library(self, filename: str) -> list:
        path = self.settings.knowledge_dir / filename
        if not path.exists():
            return []
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return []

    def _create_predictor(self):
        if not self.settings.model_path:
            return None
        model_path = Path(self.settings.model_path)
        labels = self.settings.label_list
        suffix = model_path.suffix.lower()
        if suffix in {".h5", ".keras"}:
            return KerasPredictor(model_path=model_path, labels=labels, input_size=self.settings.model_input_size)
        if suffix in {".pb", ".savedmodel", ".tf"}:
            return TensorflowPredictor(model_path=model_path, labels=labels, input_size=self.settings.model_input_size)
        if suffix in {".pt", ".pth"}:
            return TorchPredictor(model_path=model_path, labels=labels, input_size=self.settings.model_input_size)
        return KerasPredictor(model_path=model_path, labels=labels, input_size=self.settings.model_input_size)

    def _match_disease(self, label: str) -> Dict[str, Any]:
        for item in self.diseases:
            names = [item.get("name", "")] + item.get("aliases", [])
            if any(label.lower() in str(name).lower() or str(name).lower() in label.lower() for name in names):
                return item
        return {
            "name": label,
            "symptoms": "Review the leaves, stems, and panicles for visible stress symptoms.",
            "cause": "The exact cause depends on the crop stage and field conditions.",
            "treatment": "Follow local agriculture guidance and apply a suitable treatment only after confirmation.",
            "prevention": "Use clean seed, balanced nutrition, and good field sanitation.",
            "recommended_fungicide": "Use a fungicide recommended by your local agriculture expert if the disease is confirmed.",
            "organic_solution": "Neem-based or bio-control options can support integrated disease management.",
            "farmer_tips": "Keep records of weather, fertilizer, and irrigation to spot patterns quickly.",
            "fertilizer_recommendation": "Use balanced nutrition and avoid excess nitrogen.",
        }

    def _heuristic_fallback(self) -> Tuple[str, float]:
        if self.diseases:
            top = next((item for item in self.diseases if str(item.get("name", "")).lower() == "healthy"), self.diseases[0])
            return top.get("name", "Unknown disease"), 0.55
        return "Rice leaf disease", 0.50

    async def diagnose(self, upload: UploadFile, provider_id: str = "gemini") -> DiagnosisResponse:
        payload = await upload.read()
        _ = load_image_from_bytes(payload)

        label = ""
        confidence = 0.0
        model_path = str(self.settings.model_path or "")
        predictor = self.predictor
        inference_provider_id = "fallback"
        local_prediction_failed = False

        if predictor is not None:
            try:
                saved_path = Path(self._save_upload(upload.filename or "leaf.jpg", payload))
                label, confidence = predictor.predict(saved_path)
                inference_provider_id = predictor.__class__.__name__.replace("Predictor", "").lower() or "model"
            except Exception:
                local_prediction_failed = True
        else:
            local_prediction_failed = True

        if local_prediction_failed:
            gemini = self.provider_manager.get("gemini")
            if gemini.enabled:
                label, confidence, explanation = await self._diagnose_with_gemini(
                    gemini,
                    payload,
                    upload.filename or "leaf.jpg",
                )
                disease_info = self._match_disease(label)
                inference_provider_id = "gemini"
                model_path = ""
                record = DiagnosisRecord(
                    image_name=upload.filename or "leaf.jpg",
                    disease=label,
                    confidence=confidence,
                    explanation=explanation.model_dump(),
                    provider=inference_provider_id,
                    model_path=model_path,
                )
                self.history_service.add_diagnosis(record)
                return DiagnosisResponse(
                    id=record.id,
                    disease=label,
                    confidence=confidence,
                    provider=record.provider,
                    model_path=model_path,
                    created_at=record.created_at,
                    explanation=explanation,
                    suggestions=[
                        "Gemini reviewed the image because the local model was unavailable.",
                        "Try a clearer leaf photo with daylight and a plain background.",
                        "Capture the whole leaf and the damaged area in one image.",
                        "If you have a trained Torch model later, place it in backend/models.",
                    ],
                    image_name=record.image_name,
                )
            label, confidence = self._heuristic_fallback()

        disease_info = self._match_disease(label)
        explanation_provider = self.provider_manager.get(provider_id)
        low_confidence = confidence < self.settings.confidence_threshold
        review_by_gemini = False

        if low_confidence:
            gemini = self.provider_manager.get("gemini")
            if gemini.enabled:
                explanation_provider = gemini
                review_by_gemini = True

        explanation = await self._build_explanation(
            explanation_provider,
            label,
            confidence,
            disease_info,
            image_bytes=payload if review_by_gemini else None,
            mime_type=upload.content_type or "image/jpeg",
            low_confidence=low_confidence,
        )

        record = DiagnosisRecord(
            image_name=upload.filename or "leaf.jpg",
            disease=label,
            confidence=confidence,
            explanation=explanation.model_dump(),
            provider="gemini" if review_by_gemini else inference_provider_id,
            model_path=model_path,
        )
        self.history_service.add_diagnosis(record)

        return DiagnosisResponse(
            id=record.id,
            disease=label,
            confidence=confidence,
            provider=record.provider,
            model_path=model_path,
            created_at=record.created_at,
            explanation=explanation,
            suggestions=[
                "Check if the problem has spread to adjacent leaves.",
                "Reduce excess nitrogen until the crop stabilizes.",
                "Remove heavily infected leaves when practical.",
                "Follow local fungicide instructions if disease pressure is high.",
                "If the model confidence is low, the result is reviewed by Gemini before showing here.",
            ],
            image_name=record.image_name,
        )

    def _save_upload(self, filename: str, payload: bytes) -> str:
        self.settings.uploads_dir.mkdir(parents=True, exist_ok=True)
        safe_name = f"{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}_{uuid4().hex}_{Path(filename).name}"
        path = self.settings.uploads_dir / safe_name
        path.write_bytes(payload)
        return str(path)

    async def _build_explanation(
        self,
        provider,
        label: str,
        confidence: float,
        disease_info: dict,
        *,
        image_bytes: Optional[bytes] = None,
        mime_type: str = "image/jpeg",
        low_confidence: bool = False,
    ) -> DiagnosisExplanation:
        base = DiagnosisExplanation(
            disease=label,
            symptoms=str(disease_info.get("symptoms", "")),
            cause=str(disease_info.get("cause", "")),
            treatment=str(disease_info.get("treatment", "")),
            prevention=str(disease_info.get("prevention", "")),
            recommended_fungicide=str(disease_info.get("recommended_fungicide", "Use a fungicide recommended by local agriculture officers if needed.")),
            organic_solution=str(disease_info.get("organic_solution", "Use organic and biological options as part of integrated management.")),
            farmer_tips=str(disease_info.get("farmer_tips", "Monitor weather, soil moisture, and fertilizer balance.")),
            fertilizer_recommendation=str(disease_info.get("fertilizer_recommendation", "Follow a soil-test-based fertilizer plan.")),
        )
        prompt_parts = [
            "You are an agriculture expert specializing in rice cultivation.",
            f"The predicted disease is: {label}",
            f"Confidence: {round(confidence * 100, 2)}%",
        ]
        if low_confidence:
            prompt_parts.append(
                "The model confidence is low, so carefully review the attached rice leaf image and correct the result if needed."
            )
        prompt_parts.extend(
            [
                "Generate a farmer-friendly explanation in simple English with these sections:",
                "Disease, Symptoms, Cause, Treatment, Recommended Fungicide, Organic Solution, Prevention, Farmer Tips, Fertilizer Recommendation.",
                "Keep the answer practical and avoid medical uncertainty language.",
                f"Reference notes: {json.dumps(disease_info, ensure_ascii=False)}",
            ]
        )
        prompt = "\n".join(prompt_parts)
        if provider.enabled:
            try:
                if image_bytes is not None and hasattr(provider, "analyze_image"):
                    response = await provider.analyze_image(
                        prompt=prompt,
                        image_bytes=image_bytes,
                        mime_type=mime_type,
                        system_prompt="You are a rice agriculture expert.",
                        temperature=0.2,
                    )
                else:
                    response = await provider.explain_prediction(
                        prompt=prompt,
                        system_prompt="You are a rice agriculture expert.",
                        temperature=0.2,
                    )
                parsed = self._parse_explanation(response, label, disease_info)
                return self._merge_explanations(base, parsed)
            except Exception:
                pass
        return base

    async def _diagnose_with_gemini(
        self,
        provider,
        image_bytes: bytes,
        filename: str,
    ) -> Tuple[str, float, DiagnosisExplanation]:
        label_choices = ", ".join(self.settings.label_list)
        prompt = (
            "You are a rice crop disease diagnosis assistant.\n"
            f"Inspect the attached image named {filename} and return a JSON object only.\n"
            "Use this schema exactly:\n"
            "{"
            '"disease": string, '
            '"confidence": number between 0 and 1, '
            '"symptoms": string, '
            '"cause": string, '
            '"treatment": string, '
            '"prevention": string, '
            '"recommended_fungicide": string, '
            '"organic_solution": string, '
            '"farmer_tips": string, '
            '"fertilizer_recommendation": string'
            "}\n"
            f"Prefer one of these local labels if possible: {label_choices}\n"
            "If the exact label is unclear, choose the closest match and lower the confidence.\n"
            "Keep all values concise and farmer-friendly."
        )
        response = await provider.analyze_image(
            prompt=prompt,
            image_bytes=image_bytes,
            mime_type="image/jpeg",
            system_prompt="You are a rice agriculture expert.",
            temperature=0.2,
        )
        parsed = self._parse_gemini_diagnosis(response)
        if parsed is None:
            base_label = self._extract_label_from_text(response) or self._heuristic_fallback()[0]
            disease_info = self._match_disease(base_label)
            explanation = await self._build_explanation(provider, base_label, 0.5, disease_info)
            return base_label, 0.5, explanation

        disease = parsed.get("disease") or self._heuristic_fallback()[0]
        confidence_value = parsed.get("confidence")
        confidence = float(confidence_value) if isinstance(confidence_value, (int, float, str)) else 0.5
        confidence = max(0.0, min(1.0, confidence))
        disease_info = self._match_disease(disease)
        explanation = DiagnosisExplanation(
            disease=disease,
            symptoms=str(parsed.get("symptoms") or disease_info.get("symptoms", "")),
            cause=str(parsed.get("cause") or disease_info.get("cause", "")),
            treatment=str(parsed.get("treatment") or disease_info.get("treatment", "")),
            prevention=str(parsed.get("prevention") or disease_info.get("prevention", "")),
            recommended_fungicide=str(
                parsed.get("recommended_fungicide") or disease_info.get("recommended_fungicide", "")
            ),
            organic_solution=str(parsed.get("organic_solution") or disease_info.get("organic_solution", "")),
            farmer_tips=str(parsed.get("farmer_tips") or disease_info.get("farmer_tips", "")),
            fertilizer_recommendation=str(
                parsed.get("fertilizer_recommendation") or disease_info.get("fertilizer_recommendation", "")
            ),
        )
        return disease, confidence, explanation

    def _parse_gemini_diagnosis(self, response: str) -> Optional[dict]:
        text = response.strip()
        if not text:
            return None
        if text.startswith("```"):
            text = text.strip("`")
            if text.lower().startswith("json"):
                text = text[4:].strip()
        try:
            data = json.loads(text)
            return data if isinstance(data, dict) else None
        except Exception:
            return None

    def _extract_label_from_text(self, response: str) -> str:
        first_line = next((line.strip() for line in response.splitlines() if line.strip()), "")
        if ":" in first_line:
            return first_line.split(":", 1)[-1].strip()
        return first_line[:80]

    def _merge_explanations(self, base: DiagnosisExplanation, parsed: DiagnosisExplanation) -> DiagnosisExplanation:
        data = base.model_dump()
        parsed_data = parsed.model_dump()
        for key, value in parsed_data.items():
            if isinstance(value, str) and value.strip():
                data[key] = value.strip()
        return DiagnosisExplanation(**data)

    def _parse_explanation(self, text: str, label: str, disease_info: dict) -> DiagnosisExplanation:
        sections = {
            "disease": label,
            "symptoms": disease_info.get("symptoms", ""),
            "cause": disease_info.get("cause", ""),
            "treatment": disease_info.get("treatment", ""),
            "prevention": disease_info.get("prevention", ""),
            "recommended_fungicide": disease_info.get("recommended_fungicide", ""),
            "organic_solution": disease_info.get("organic_solution", ""),
            "farmer_tips": disease_info.get("farmer_tips", ""),
            "fertilizer_recommendation": disease_info.get("fertilizer_recommendation", ""),
        }
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        mapping = {
            "symptoms": ("symptom", "sign"),
            "cause": ("cause",),
            "treatment": ("treatment", "control"),
            "prevention": ("prevention", "prevent"),
            "recommended_fungicide": ("fungicide",),
            "organic_solution": ("organic", "bio"),
            "farmer_tips": ("tip", "advice"),
            "fertilizer_recommendation": ("fertilizer", "nutrition"),
        }
        current = None
        buffer = []
        for line in lines:
            normalized = line.lower().rstrip(":")
            matched = None
            for key, aliases in mapping.items():
                if any(normalized.startswith(alias) for alias in aliases):
                    matched = key
                    break
            if matched:
                if current and buffer:
                    sections[current] = " ".join(buffer).strip()
                current = matched
                buffer = [line.split(":", 1)[-1].strip() if ":" in line else ""]
            elif current:
                buffer.append(line)
        if current and buffer:
            sections[current] = " ".join(buffer).strip()
        return DiagnosisExplanation(**sections)


class TorchPredictor:
    def __init__(self, model_path: Path, labels: list[str], input_size: int = 224) -> None:
        self.model_path = model_path
        self.labels = labels
        self.input_size = input_size
        self.model = None
        self._transform = None

    def load(self) -> None:
        try:
            import torch
            from torchvision import models, transforms

            loaded = torch.load(str(self.model_path), map_location="cpu")
            if not isinstance(loaded, dict) or "model_state_dict" not in loaded:
                raise RuntimeError(f"Unsupported PyTorch checkpoint type: {type(loaded)!r}")

            config = loaded.get("config") or {}
            class_info = loaded.get("class_info") or {}
            class_names = class_info.get("class_names")
            if isinstance(class_names, list) and class_names:
                self.labels = [str(item) for item in class_names]

            num_classes = int(class_info.get("num_classes") or len(self.labels) or 32)
            self.input_size = int(config.get("img_size") or self.input_size or 384)

            backbone = models.efficientnet_v2_s(weights=None)
            in_features = backbone.classifier[1].in_features
            backbone.classifier[1] = torch.nn.Linear(in_features, num_classes)

            class EfficientNetWrapper(torch.nn.Module):
                def __init__(self, wrapped_backbone):
                    super().__init__()
                    self.backbone = wrapped_backbone

                def forward(self, x):
                    return self.backbone(x)

            self.model = EfficientNetWrapper(backbone)
            self.model.load_state_dict(loaded["model_state_dict"], strict=True)
            self.model.eval()
            self._transform = transforms.Compose(
                [
                    transforms.Resize((self.input_size, self.input_size)),
                    transforms.ToTensor(),
                    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
                ]
            )
        except Exception as exc:
            raise RuntimeError(f"Failed to load PyTorch model at {self.model_path}: {exc}") from exc

    def _image_to_tensor(self, image_path: Path):
        import torch
        from PIL import Image

        if self._transform is None:
            raise RuntimeError("Torch preprocess transform is not initialized.")
        image = Image.open(image_path).convert("RGB")
        tensor = self._transform(image)
        return tensor.unsqueeze(0)

    def predict(self, image_path: Path) -> Tuple[str, float]:
        if self.model is None:
            self.load()
        if self.model is None:
            raise RuntimeError("PyTorch model is not loaded.")
        try:
            import torch

            tensor = self._image_to_tensor(image_path)
            with torch.inference_mode():
                output = self.model(tensor)
                if isinstance(output, tuple):
                    output = output[0]
                if isinstance(output, list):
                    output = output[0]
                if output.dim() == 1:
                    output = output.unsqueeze(0)
                probs = torch.softmax(output.float(), dim=1)[0]
                confidence, index = torch.max(probs, dim=0)
                label = self.labels[int(index)] if int(index) < len(self.labels) else f"Class {int(index)}"
                return label, float(confidence.item())
        except Exception as exc:
            raise RuntimeError(f"PyTorch inference failed: {exc}") from exc
