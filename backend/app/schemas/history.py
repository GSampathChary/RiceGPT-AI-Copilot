from typing import List

from pydantic import BaseModel

from .chat import ChatHistoryItem
from .diagnosis import DiagnosisHistoryItem


class HistoryBundleResponse(BaseModel):
    chats: List[ChatHistoryItem]
    diagnoses: List[DiagnosisHistoryItem]

