from fastapi import APIRouter, Depends, Query

from app.config.settings import Settings, get_settings
from app.deps import get_chat_service
from app.services.chat_service import ChatService


router = APIRouter(prefix="/library", tags=["library"])


@router.get("/diseases")
async def list_diseases(q: str | None = Query(default=None), settings: Settings = Depends(get_settings), service: ChatService = Depends(get_chat_service)):
    items = service.diseases
    if q:
        query = q.lower()
        items = [
            item
            for item in items
            if query in str(item.get("name", "")).lower()
            or query in str(item.get("symptoms", "")).lower()
            or query in str(item.get("cause", "")).lower()
        ]
    return {"items": items}
