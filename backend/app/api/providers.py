from fastapi import APIRouter, Depends

from app.config.settings import Settings, get_settings
from app.schemas.provider import ProviderListResponse, ProviderInfo
from app.services.provider_service import ProviderService
from app.deps import get_provider_service


router = APIRouter(prefix="/providers", tags=["providers"])


@router.get("", response_model=ProviderListResponse)
async def list_providers(service: ProviderService = Depends(get_provider_service), settings: Settings = Depends(get_settings)):
    cards = [ProviderInfo(**card) for card in service.list_providers()]
    return ProviderListResponse(selected=settings.selected_provider, providers=cards)
