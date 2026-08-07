from __future__ import annotations

from typing import Dict, List

from app.ai.manager import ProviderManager


class ProviderService:
    def __init__(self, manager: ProviderManager) -> None:
        self.manager = manager

    def list_providers(self) -> List[dict]:
        return self.manager.cards()

