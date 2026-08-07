from __future__ import annotations

import asyncio
import base64
import json
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

from .base_provider import BaseAIProvider


class GeminiProvider(BaseAIProvider):
    provider_id = "gemini"
    display_name = "Gemini"

    @property
    def enabled(self) -> bool:
        return bool(self.api_key)

    async def generate_text(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        if not self.api_key:
            raise RuntimeError("Gemini API key is not configured.")

        return await asyncio.to_thread(self._generate_text_sync, prompt, system_prompt, temperature)

    async def analyze_image(
        self,
        prompt: str,
        image_bytes: bytes,
        mime_type: str = "image/jpeg",
        system_prompt: str = "",
        temperature: float = 0.2,
    ) -> str:
        if not self.api_key:
            raise RuntimeError("Gemini API key is not configured.")

        return await asyncio.to_thread(
            self._analyze_image_sync,
            prompt,
            image_bytes,
            mime_type,
            system_prompt,
            temperature,
        )

    def _generate_text_sync(self, prompt: str, system_prompt: str, temperature: float) -> str:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?{urlencode({'key': self.api_key})}"
        payload = {
            "systemInstruction": {"parts": [{"text": system_prompt}]} if system_prompt else None,
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": 1024,
            },
        }
        body = json.dumps({k: v for k, v in payload.items() if v is not None}).encode("utf-8")
        request = Request(url, data=body, headers={"Content-Type": "application/json"}, method="POST")
        try:
            with urlopen(request, timeout=60) as response:
                data = json.loads(response.read().decode("utf-8"))
        except HTTPError as exc:
            raise RuntimeError(f"Gemini request failed: {exc.code} {exc.reason}") from exc
        except URLError as exc:
            raise RuntimeError(f"Gemini request failed: {exc.reason}") from exc

        candidates = data.get("candidates", [])
        if not candidates:
            raise RuntimeError("Gemini returned no candidates.")
        parts = candidates[0].get("content", {}).get("parts", [])
        return "\n".join(part.get("text", "") for part in parts).strip()

    def _analyze_image_sync(
        self,
        prompt: str,
        image_bytes: bytes,
        mime_type: str,
        system_prompt: str,
        temperature: float,
    ) -> str:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?{urlencode({'key': self.api_key})}"
        payload = {
            "systemInstruction": {"parts": [{"text": system_prompt}]} if system_prompt else None,
            "contents": [
                {
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": mime_type or "image/jpeg",
                                "data": base64.b64encode(image_bytes).decode("utf-8"),
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": 1024,
            },
        }
        body = json.dumps({k: v for k, v in payload.items() if v is not None}).encode("utf-8")
        request = Request(url, data=body, headers={"Content-Type": "application/json"}, method="POST")
        try:
            with urlopen(request, timeout=60) as response:
                data = json.loads(response.read().decode("utf-8"))
        except HTTPError as exc:
            raise RuntimeError(f"Gemini image request failed: {exc.code} {exc.reason}") from exc
        except URLError as exc:
            raise RuntimeError(f"Gemini image request failed: {exc.reason}") from exc

        candidates = data.get("candidates", [])
        if not candidates:
            raise RuntimeError("Gemini returned no candidates.")
        parts = candidates[0].get("content", {}).get("parts", [])
        return "\n".join(part.get("text", "") for part in parts if part.get("text")).strip()
