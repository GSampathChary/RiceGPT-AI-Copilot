from dataclasses import dataclass, asdict
from typing import Any, Dict, List


@dataclass
class ProviderCard:
    id: str
    name: str
    enabled: bool
    status: str
    description: str
    capabilities: List[str]

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

