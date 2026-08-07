from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path
from typing import List, Optional


def _load_env_file(path: Path) -> dict[str, str]:
    if not path.exists():
      return {}
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        values[key] = value
    return values


class Settings:
    def __init__(self) -> None:
        project_root = Path(__file__).resolve().parents[2]
        env_path = project_root / ".env"
        file_values = _load_env_file(env_path)

        def get(name: str, default: Optional[str] = None) -> Optional[str]:
            return os.getenv(name, file_values.get(name, default))

        self.app_name: str = get("APP_NAME", "RiceGPT AI") or "RiceGPT AI"
        self.api_v1_prefix: str = "/api"
        self.environment: str = get("ENVIRONMENT", "development") or "development"
        self.debug: bool = str(get("DEBUG", "true")).lower() in {"1", "true", "yes", "on"}
        self.log_level: str = get("LOG_LEVEL", "INFO") or "INFO"
        self.cors_origins: str = get("CORS_ORIGINS", "*") or "*"
        self.server_host: str = get("SERVER_HOST", "0.0.0.0") or "0.0.0.0"
        self.server_port: int = int(get("SERVER_PORT", "8000") or "8000")

        self.storage_dir: Path = project_root / "storage"
        self.uploads_dir: Path = self.storage_dir / "uploads"
        self.history_file: Path = self.storage_dir / "history.json"
        self.knowledge_dir: Path = project_root / "app" / "knowledge"
        self.prompts_dir: Path = project_root / "app" / "ai" / "prompts"

        self.selected_provider: str = get("SELECTED_PROVIDER", "gemini") or "gemini"
        self.gemini_api_key: Optional[str] = get("GEMINI_API_KEY")
        self.gemini_model: str = get("GEMINI_MODEL", "gemini-1.5-flash") or "gemini-1.5-flash"
        self.openai_api_key: Optional[str] = get("OPENAI_API_KEY")
        self.openai_model: str = get("OPENAI_MODEL", "gpt-4o-mini") or "gpt-4o-mini"
        self.claude_api_key: Optional[str] = get("CLAUDE_API_KEY")
        self.claude_model: str = get("CLAUDE_MODEL", "claude-3-5-sonnet-latest") or "claude-3-5-sonnet-latest"
        self.grok_api_key: Optional[str] = get("GROK_API_KEY")
        self.grok_model: str = get("GROK_MODEL", "grok-2-latest") or "grok-2-latest"
        self.deepseek_api_key: Optional[str] = get("DEEPSEEK_API_KEY")
        self.deepseek_model: str = get("DEEPSEEK_MODEL", "deepseek-chat") or "deepseek-chat"
        self.ollama_base_url: str = get("OLLAMA_BASE_URL", "http://localhost:11434") or "http://localhost:11434"
        self.ollama_model: str = get("OLLAMA_MODEL", "llama3.1") or "llama3.1"

        model_path_value = get("MODEL_PATH")
        self.model_path: Optional[Path] = Path(model_path_value) if model_path_value else self.default_model_path
        self.model_type: str = get("MODEL_TYPE", "auto") or "auto"
        self.model_labels: str = get(
            "MODEL_LABELS",
            (
                "Aquatic_weeds_Azolla,"
                "Aquatic_weeds_Marselia quadrifoliata,"
                "Aquatic_weeds_Monochoria,"
                "Aquatic_weeds_Pistia,"
                "Broad_Leaves_Alternanathera species,"
                "Broad_Leaves_Ammania Basifera,"
                "Broad_Leaves_Eclipta alba,"
                "Disease_BLB,"
                "Disease_Blast,"
                "Disease_Brown spot,"
                "Disease_False smut,"
                "Disease_SHBL,"
                "Grass_Echinochloa colona,"
                "Grass_Echinochloa crusgalli,"
                "Grass_Leptochloa,"
                "Grass_Paspalum,"
                "Healthy,"
                "Insect_BPH,"
                "Insect_Gall midge,"
                "Insect_Hispa,"
                "Insect_Leaf folder,"
                "Insect_Yellow stem borer,"
                "Iron Toxicity,"
                "Nemotode_below ground,"
                "Nitrogen deficency,"
                "Phosphorus deficency,"
                "Potassium deficency,"
                "Salinity,"
                "Sedge_Cyperus Iria,"
                "Sedge_Cyperus Rotondus,"
                "Sedge_Cyperus diformis,"
                "Sedge_Fimbristylis species"
            ),
        ) or ""
        self.model_input_size: int = int(get("MODEL_INPUT_SIZE", "384") or "384")
        self.confidence_threshold: float = float(get("CONFIDENCE_THRESHOLD", "0.65") or "0.65")

        self.request_timeout_seconds: int = int(get("REQUEST_TIMEOUT_SECONDS", "60") or "60")
        self.default_language: str = get("DEFAULT_LANGUAGE", "en") or "en"
        self.app_version: str = get("APP_VERSION", "1.0.0") or "1.0.0"

    @property
    def label_list(self) -> List[str]:
        return [item.strip() for item in self.model_labels.split(",") if item.strip()]

    @property
    def default_model_path(self) -> Optional[Path]:
        candidates = [
            self.storage_dir.parent / "models" / "rice_disease_model.pth",
            self.storage_dir.parent / "models" / "rice_disease_model.pt",
            self.storage_dir.parent / "models" / "rice_disease_model.keras",
            self.storage_dir.parent / "models" / "rice_disease_model.h5",
            self.storage_dir.parent / "models" / "rice_disease_savedmodel",
        ]
        for candidate in candidates:
            if candidate.exists():
                return candidate
        return None


@lru_cache
def get_settings() -> Settings:
    return Settings()
