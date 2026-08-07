from __future__ import annotations

from functools import lru_cache

from app.ai.manager import ProviderManager
from app.config.settings import get_settings
from app.services.chat_service import ChatService
from app.services.diagnosis_service import DiagnosisService
from app.services.history_service import HistoryService
from app.services.provider_service import ProviderService


@lru_cache
def get_provider_manager() -> ProviderManager:
    return ProviderManager(get_settings())


@lru_cache
def get_history_service() -> HistoryService:
    settings = get_settings()
    settings.storage_dir.mkdir(parents=True, exist_ok=True)
    settings.uploads_dir.mkdir(parents=True, exist_ok=True)
    return HistoryService(settings.history_file)


@lru_cache
def get_provider_service() -> ProviderService:
    return ProviderService(get_provider_manager())


@lru_cache
def get_chat_service() -> ChatService:
    settings = get_settings()
    return ChatService(settings, get_provider_manager(), get_history_service())


@lru_cache
def get_diagnosis_service() -> DiagnosisService:
    settings = get_settings()
    return DiagnosisService(settings, get_provider_manager(), get_history_service())

