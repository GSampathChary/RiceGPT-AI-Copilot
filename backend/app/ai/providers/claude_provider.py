from __future__ import annotations

from .base_provider import BaseAIProvider


class ClaudeProvider(BaseAIProvider):
    provider_id = "claude"
    display_name = "Claude"

    async def generate_text(self, prompt: str, system_prompt: str = "", temperature: float = 0.2) -> str:
        raise RuntimeError("Claude provider is available in architecture only. Configure it later if needed.")

