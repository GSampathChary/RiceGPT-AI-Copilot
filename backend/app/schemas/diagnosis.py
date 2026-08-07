from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class DiagnosisExplanation(BaseModel):
    disease: str
    symptoms: str = ""
    cause: str = ""
    treatment: str = ""
    prevention: str = ""
    recommended_fungicide: str = ""
    organic_solution: str = ""
    farmer_tips: str = ""
    fertilizer_recommendation: str = ""


class DiagnosisResponse(BaseModel):
    id: str
    disease: str
    confidence: float
    provider: str
    model_path: str = ""
    created_at: str
    explanation: DiagnosisExplanation
    suggestions: List[str] = Field(default_factory=list)
    image_name: str = ""


class DiagnosisHistoryItem(BaseModel):
    id: str
    image_name: str
    disease: str
    confidence: float
    provider: str
    created_at: str


class DiagnosisHistoryResponse(BaseModel):
    items: List[DiagnosisHistoryItem]

