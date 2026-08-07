from fastapi import APIRouter, Depends, File, Form, UploadFile

from app.deps import get_diagnosis_service
from app.schemas.diagnosis import DiagnosisResponse
from app.services.diagnosis_service import DiagnosisService


router = APIRouter(prefix="/diagnosis", tags=["diagnosis"])


@router.post("", response_model=DiagnosisResponse)
async def diagnose(
    file: UploadFile = File(...),
    provider: str = Form("gemini"),
    service: DiagnosisService = Depends(get_diagnosis_service),
):
    return await service.diagnose(file, provider_id=provider)
