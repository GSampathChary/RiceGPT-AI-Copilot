from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional


class BaseAIProvider(ABC):
    provider_id: str = "base"
    display_name: str = "Base Provider"

    def __init__(self, api_key: Optional[str] = None, model: str = "") -> None:
        self.api_key = api_key
        self.model = model

    @property
    def enabled(self) -> bool:
        return bool(self.api_key)

    @property
    def status(self) -> str:
        return "ready" if self.enabled else "not configured"

    @property
    def capabilities(self) -> List[str]:
        return ["chat", "diagnosis"]

    @abstractmethod
    async def generate_text(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        raise NotImplementedError

    async def explain_prediction(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        return await self.generate_text(prompt=prompt, system_prompt=system_prompt, temperature=temperature)

    async def analyze_image(
        self,
        prompt: str,
        image_bytes: bytes,
        mime_type: str = "image/jpeg",
        system_prompt: str = "",
        temperature: float = 0.2,
    ) -> str:
        return await self.generate_text(prompt=prompt, system_prompt=system_prompt, temperature=temperature)
