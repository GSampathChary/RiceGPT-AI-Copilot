from fastapi import APIRouter, Depends

import json
from pathlib import Path

from app.config.settings import Settings, get_settings


router = APIRouter(prefix="/labels", tags=["labels"])


def _humanize(label: str) -> str:
    text = label.replace("_", " ").strip()
    text = text.replace("deficency", "deficiency")
    text = text.replace("  ", " ")
    return text


def _category(label: str) -> str:
    prefix = label.split("_", 1)[0]
    mapping = {
        "Aquatic": "Aquatic weeds",
        "Broad": "Broad leaves",
        "Disease": "Disease",
        "Grass": "Grass weeds",
        "Healthy": "Crop condition",
        "Insect": "Insect pests",
        "Iron": "Abiotic stress",
        "Nemotode": "Nematode",
        "Nitrogen": "Nutrient stress",
        "Phosphorus": "Nutrient stress",
        "Potassium": "Nutrient stress",
        "Salinity": "Abiotic stress",
        "Sedge": "Sedge weeds",
    }
    return mapping.get(prefix, "Other")


@router.get("")
async def list_labels(settings: Settings = Depends(get_settings)):
    catalog = settings.knowledge_dir / "model_labels.json"
    if catalog.exists():
        try:
            return {"items": json.loads(catalog.read_text(encoding="utf-8"))}
        except Exception:
            pass
    labels = []
    for label in settings.label_list:
        labels.append(
            {
                "label": label,
                "display_name": _humanize(label),
                "category": _category(label),
            }
        )
    return {"items": labels}
