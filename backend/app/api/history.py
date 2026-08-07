from fastapi import APIRouter, Depends, HTTPException

from app.deps import get_history_service
from app.schemas.history import HistoryBundleResponse
from app.schemas.chat import ChatHistoryResponse, ChatHistoryItem
from app.schemas.diagnosis import DiagnosisHistoryResponse, DiagnosisHistoryItem
from app.services.history_service import HistoryService


router = APIRouter(prefix="/history", tags=["history"])


@router.get("", response_model=HistoryBundleResponse)
async def get_history(service: HistoryService = Depends(get_history_service)):
    chats = [ChatHistoryItem(**item) for item in service.list_chats()]
    diagnoses = [DiagnosisHistoryItem(**item) for item in service.list_diagnoses()]
    return HistoryBundleResponse(chats=chats, diagnoses=diagnoses)


@router.delete("")
async def clear_history(service: HistoryService = Depends(get_history_service)):
    service.clear()
    return {"status": "cleared"}


@router.delete("/chats/{record_id}")
async def delete_chat(record_id: str, service: HistoryService = Depends(get_history_service)):
    if not service.delete_chat(record_id):
        raise HTTPException(status_code=404, detail="Chat record not found")
    return {"status": "deleted"}


@router.delete("/diagnoses/{record_id}")
async def delete_diagnosis(record_id: str, service: HistoryService = Depends(get_history_service)):
    if not service.delete_diagnosis(record_id):
        raise HTTPException(status_code=404, detail="Diagnosis record not found")
    return {"status": "deleted"}
