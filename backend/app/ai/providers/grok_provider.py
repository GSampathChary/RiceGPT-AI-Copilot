from __future__ import annotations

from .base_provider import BaseAIProvider


class GrokProvider(BaseAIProvider):
    provider_id = "grok"
    display_name = "Grok"

    async def generate_text(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        raise RuntimeError("Grok provider is available in architecture only. Configure it later if needed.")

