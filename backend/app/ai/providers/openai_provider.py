from __future__ import annotations

from .base_provider import BaseAIProvider


class OpenAIProvider(BaseAIProvider):
    provider_id = "openai"
    display_name = "OpenAI"

    async def generate_text(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        raise RuntimeError("OpenAI provider is available in architecture only. Configure it later if needed.")

