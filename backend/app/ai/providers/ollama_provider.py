from __future__ import annotations

import asyncio
import json
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

from .base_provider import BaseAIProvider


class OllamaProvider(BaseAIProvider):
    provider_id = "ollama"
    display_name = "Ollama"

    def __init__(self, base_url: str, model: str) -> None:
        super().__init__(api_key=None, model=model)
        self.base_url = base_url.rstrip("/")

    @property
    def enabled(self) -> bool:
        return True

    @property
    def status(self) -> str:
        return "ready"

    async def generate_text(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        return await asyncio.to_thread(self._generate_text_sync, prompt, system_prompt, temperature)

    def _generate_text_sync(self, prompt: str, system_prompt: str, temperature: float) -> str:
        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt} if system_prompt else None,
                {"role": "user", "content": prompt},
            ],
            "stream": False,
            "options": {"temperature": temperature},
        }
        payload["messages"] = [item for item in payload["messages"] if item is not None]
        body = json.dumps(payload).encode("utf-8")
        request = Request(
            f"{self.base_url}/api/chat",
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urlopen(request, timeout=60) as response:
                data = json.loads(response.read().decode("utf-8"))
        except HTTPError as exc:
            raise RuntimeError(f"Ollama request failed: {exc.code} {exc.reason}") from exc
        except URLError as exc:
            raise RuntimeError(f"Ollama request failed: {exc.reason}") from exc
        return data.get("message", {}).get("content", "").strip()
