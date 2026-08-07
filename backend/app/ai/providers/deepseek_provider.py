from __future__ import annotations

from .base_provider import BaseAIProvider


class DeepSeekProvider(BaseAIProvider):
    provider_id = "deepseek"
    display_name = "DeepSeek"

    async def generate_text(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        raise RuntimeError("DeepSeek provider is available in architecture only. Configure it later if needed.")

