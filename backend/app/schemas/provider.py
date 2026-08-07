from typing import List

from pydantic import BaseModel


class ProviderInfo(BaseModel):
    id: str
    name: str
    enabled: bool
    status: str
    description: str
    capabilities: List[str]


class ProviderListResponse(BaseModel):
    selected: str
    providers: List[ProviderInfo]

