from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List, Optional

from app.config.settings import Settings
from app.ai.providers.base_provider import BaseAIProvider
from app.ai.providers.claude_provider import ClaudeProvider
from app.ai.providers.deepseek_provider import DeepSeekProvider
from app.ai.providers.gemini_provider import GeminiProvider
from app.ai.providers.grok_provider import GrokProvider
from app.ai.providers.ollama_provider import OllamaProvider
from app.ai.providers.openai_provider import OpenAIProvider


class ProviderManager:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.providers: Dict[str, BaseAIProvider] = {
            "gemini": GeminiProvider(api_key=settings.gemini_api_key, model=settings.gemini_model),
            "openai": OpenAIProvider(api_key=settings.openai_api_key, model=settings.openai_model),
            "claude": ClaudeProvider(api_key=settings.claude_api_key, model=settings.claude_model),
            "grok": GrokProvider(api_key=settings.grok_api_key, model=settings.grok_model),
            "deepseek": DeepSeekProvider(api_key=settings.deepseek_api_key, model=settings.deepseek_model),
            "ollama": OllamaProvider(base_url=settings.ollama_base_url, model=settings.ollama_model),
        }

    def get(self, provider_id: Optional[str] = None) -> BaseAIProvider:
        key = (provider_id or self.settings.selected_provider or "gemini").lower()
        if key not in self.providers:
            key = "gemini"
        return self.providers[key]

    def cards(self) -> List[dict]:
        cards = []
        for provider_id, provider in self.providers.items():
            cards.append(
                {
                    "id": provider_id,
                    "name": provider.display_name,
                    "enabled": provider.enabled,
                    "status": provider.status,
                    "description": self._description(provider_id),
                    "capabilities": provider.capabilities,
                }
            )
        return cards

    def _description(self, provider_id: str) -> str:
        descriptions = {
            "gemini": "Primary model used for farmer-friendly explanations and rice guidance.",
            "openai": "Architecture-ready provider for GPT models.",
            "claude": "Architecture-ready provider for Claude models.",
            "grok": "Architecture-ready provider for Grok models.",
            "deepseek": "Architecture-ready provider for DeepSeek models.",
            "ollama": "Local model runner for offline experimentation.",
        }
        return descriptions.get(provider_id, "")

