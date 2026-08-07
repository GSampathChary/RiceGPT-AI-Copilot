from dataclasses import dataclass, asdict, field
from datetime import datetime, timezone
from typing import Any, Dict
from uuid import uuid4


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class DiagnosisRecord:
    id: str = field(default_factory=lambda: str(uuid4()))
    image_name: str = ""
    disease: str = ""
    confidence: float = 0.0
    explanation: Dict[str, Any] = field(default_factory=dict)
    provider: str = "gemini"
    model_path: str = ""
    created_at: str = field(default_factory=now_iso)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

