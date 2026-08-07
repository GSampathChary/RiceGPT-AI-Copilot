from __future__ import annotations

import json
import re
from pathlib import Path
from typing import List, Optional, Tuple

from app.ai.manager import ProviderManager
from app.config.settings import Settings
from app.models.chat import ChatMessage, ChatRecord
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.history_service import HistoryService


class ChatService:
    def __init__(self, settings: Settings, provider_manager: ProviderManager, history_service: HistoryService) -> None:
        self.settings = settings
        self.provider_manager = provider_manager
        self.history_service = history_service
        self.system_prompt = self._load_prompt("system_prompt.txt")
        self.rice_prompt = self._load_prompt("rice_expert.txt")
        self.diseases = self._load_json_knowledge("diseases.json")
        self.faq = self._load_json_knowledge("faq.json")
        self.fertilizers = self._load_json_knowledge("fertilizers.json")
        self.pests = self._load_json_knowledge("pests.json")
        self.expert_tables = self._load_json_knowledge("expert_system_tables.json")

    def _load_prompt(self, name: str) -> str:
        path = self.settings.prompts_dir / name
        if path.exists():
            return path.read_text(encoding="utf-8")
        return ""

    def _load_json_knowledge(self, name: str) -> list:
        path = self.settings.knowledge_dir / name
        if path.exists():
            try:
                return json.loads(path.read_text(encoding="utf-8"))
            except Exception:
                return []
        return []

    def _flatten_row(self, row: dict) -> str:
        return " ".join(str(value) for key, value in row.items() if key != "row" and str(value).strip())

    def _best_expert_row(self, message: str) -> str:
        tokens = {token for token in re.findall(r"[a-zA-Z]+", message.lower()) if len(token) > 2}
        best = None
        best_score = 0
        for sheet in self.expert_tables:
            for row in sheet.get("rows", []):
                haystack = self._flatten_row(row).lower()
                if not haystack:
                    continue
                score = sum(1 for token in tokens if token in haystack)
                if score > best_score:
                    best_score = score
                    best = (sheet.get("sheet", "Workbook"), row)
        if best and best_score > 0:
            sheet_name, row = best
            return f"Expert table match from {sheet_name} row {row.get('row')}: {self._flatten_row(row)}"
        return ""

    def _build_context(self, message: str) -> List[str]:
        tokens = {token for token in re.findall(r"[a-zA-Z]+", message.lower()) if len(token) > 2}
        matches = []
        for item in self.diseases:
            haystack = " ".join(str(item.get(key, "")) for key in ("name", "aliases", "symptoms", "treatment", "prevention", "cause")).lower()
            if any(token in haystack for token in tokens):
                matches.append(item)
        evidence = []
        if matches:
            first = matches[0]
            evidence.extend(
                [
                    f"Relevant disease knowledge: {first.get('name', 'Rice disease')}.",
                    f"Symptoms: {first.get('symptoms', '')}.",
                    f"Cause: {first.get('cause', '')}.",
                    f"Treatment: {first.get('treatment', '')}.",
                    f"Prevention: {first.get('prevention', '')}.",
                ]
            )
        for item in self.faq:
            question = str(item.get("question", "")).lower()
            answer = str(item.get("answer", ""))
            if any(token in question for token in tokens) or any(token in answer.lower() for token in tokens):
                evidence.append(f"FAQ match: {item.get('question', '')} -> {item.get('answer', '')}")
                break
        for item in self.fertilizers:
            haystack = " ".join(str(item.get(key, "")) for key in ("name", "use", "note")).lower()
            if any(token in haystack for token in tokens):
                evidence.append(f"Fertilizer note: {item.get('name', '')} - {item.get('use', '')}. {item.get('note', '')}")
                break
        for item in self.pests:
            haystack = " ".join(str(item.get(key, "")) for key in ("name", "symptoms", "management")).lower()
            if any(token in haystack for token in tokens):
                evidence.append(f"Pest note: {item.get('name', '')}. Symptoms: {item.get('symptoms', '')}. Management: {item.get('management', '')}")
                break
        table_match = self._best_expert_row(message)
        if table_match:
            evidence.append(table_match)
        if not evidence:
            evidence.append("No exact local match found. Provide general rice agriculture guidance.")
        return evidence

    def _local_summary(self, message: str, context: List[str]) -> str:
        lower = message.lower()
        if "yellow" in lower or "yellowing" in lower:
            return (
                "Yellow rice leaves usually point to nitrogen deficiency, water stress, or root problems. "
                "Check field drainage, apply a balanced nitrogen fertilizer if the soil is poor, and inspect roots for rot. "
                "If the yellowing starts from older leaves, nutrient deficiency is more likely; if it spreads in patches, investigate disease or flooding."
            )
        if "brown spot" in lower:
            return (
                "Brown spot is a fungal disease that creates oval brown lesions on leaves and can reduce yield. "
                "Use healthy seed, balanced fertilization, avoid prolonged leaf wetness, and remove infected crop residue. "
                "If pressure is high, a fungicide recommended by your local agriculture officer can be used according to the label."
            )
        if "blast" in lower:
            return (
                "Rice blast is one of the most common rice diseases. It causes spindle-shaped lesions on leaves and can affect the neck and panicle during flowering. "
                "Use resistant varieties, avoid excess nitrogen, keep spacing good for airflow, and apply a recommended fungicide if the infection is active."
            )
        if "water" in lower or "irrigation" in lower:
            return (
                "Rice water management works best when the field stays consistently moist, but not stagnant for too long. "
                "Young seedlings need careful shallow irrigation, while established crops can benefit from alternate wetting and drying in many systems."
            )
        if "fertilizer" in lower:
            return (
                "For rice, the best fertilizer plan depends on soil test results. In general, split nitrogen applications work better than a single heavy dose. "
                "Phosphorus supports root growth and potassium helps stress tolerance. Share your growth stage and I can suggest a stage-wise plan."
            )
        return "Here is a practical rice farming answer."

    def _fallback_answer(self, message: str, context: List[str]) -> str:
        summary = self._local_summary(message, context)
        context_block = "\n".join(f"- {line}" for line in context)
        if context_block.strip():
            return f"{summary}\n\nLocal notes:\n{context_block}"
        return summary

    async def ask(self, request: ChatRequest) -> ChatResponse:
        provider = self.provider_manager.get(request.provider)
        context = self._build_context(request.message)
        local_answer = self._fallback_answer(request.message, context)
        prompt = (
            f"{self.rice_prompt}\n\n"
            f"Farmer question: {request.message}\n\n"
            f"Context:\n" + "\n".join(f"- {line}" for line in context) + "\n\n"
            f"Local answer draft:\n{local_answer}\n\n"
            "Reply in simple English and keep the answer practical, concise, and farmer-friendly."
        )

        answer = local_answer
        if provider.enabled:
            try:
                gemini_answer = await provider.generate_text(
                    prompt=prompt,
                    system_prompt=self.system_prompt or "You are a rice agriculture expert.",
                    temperature=0.2,
                )
                answer = f"{local_answer}\n\nGemini insight:\n{gemini_answer}"
            except Exception:
                answer = local_answer

        conversation_id = request.conversation_id or ""
        record = ChatRecord(
            query=request.message,
            answer=answer,
            provider=provider.provider_id,
            disease_context="\n".join(context),
            messages=[ChatMessage(role=item.role, content=item.content, created_at=item.created_at or "") for item in request.history]
            + [ChatMessage(role="user", content=request.message), ChatMessage(role="assistant", content=answer)],
        )
        self.history_service.add_chat(record)

        suggestions = [
            "What fertilizer should I use for rice?",
            "Why are my rice leaves yellow?",
            "How do I treat brown spot?",
            "What water level is best for paddy?",
        ]
        return ChatResponse(
            id=record.id,
            answer=answer,
            provider=provider.provider_id,
            created_at=record.created_at,
            conversation_id=conversation_id or record.id,
            suggested_questions=suggestions,
            source_context="\n".join(context),
        )
