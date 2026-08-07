from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class ChatMessageSchema(BaseModel):
    role: str = Field(pattern="^(user|assistant|system)$")
    content: str
    created_at: str | None = None


class ChatRequest(BaseModel):
    message: str
    provider: str = "gemini"
    conversation_id: Optional[str] = None
    history: List[ChatMessageSchema] = Field(default_factory=list)
    language: str = "en"


class ChatResponse(BaseModel):
    id: str
    answer: str
    provider: str
    created_at: str
    conversation_id: str
    suggested_questions: List[str] = Field(default_factory=list)
    source_context: str = ""


class ChatHistoryItem(BaseModel):
    id: str
    query: str
    answer: str
    provider: str
    disease_context: str = ""
    created_at: str


class ChatHistoryResponse(BaseModel):
    items: List[ChatHistoryItem]

