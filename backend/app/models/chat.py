from dataclasses import dataclass, asdict, field
from datetime import datetime, timezone
from typing import Any, Dict, List
from uuid import uuid4


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class ChatMessage:
    role: str
    content: str
    created_at: str = field(default_factory=now_iso)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class ChatRecord:
    id: str = field(default_factory=lambda: str(uuid4()))
    query: str = ""
    answer: str = ""
    provider: str = "gemini"
    disease_context: str = ""
    created_at: str = field(default_factory=now_iso)
    messages: List[ChatMessage] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        payload = asdict(self)
        payload["messages"] = [message.to_dict() for message in self.messages]
        return payload

