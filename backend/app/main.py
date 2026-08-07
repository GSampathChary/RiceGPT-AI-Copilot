from __future__ import annotations

import logging
from functools import lru_cache
from pathlib import Path

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from app.api import chat as chat_router
from app.api import diagnosis as diagnosis_router
from app.api import health as health_router
from app.api import history as history_router
from app.api import library as library_router
from app.api import labels as labels_router
from app.api import providers as providers_router
from app.config.settings import Settings, get_settings
from app.deps import get_chat_service, get_diagnosis_service, get_history_service, get_provider_service, get_provider_manager


logger = logging.getLogger("ricegpt")


def create_app() -> FastAPI:
    settings = get_settings()
    logging.basicConfig(level=getattr(logging, settings.log_level.upper(), logging.INFO))

    app = FastAPI(title=settings.app_name, version=settings.app_version, debug=settings.debug)
    origins = ["*"] if settings.cors_origins == "*" else [origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health_router.router)
    app.include_router(chat_router.router, prefix=settings.api_v1_prefix)
    app.include_router(diagnosis_router.router, prefix=settings.api_v1_prefix)
    app.include_router(history_router.router, prefix=settings.api_v1_prefix)
    app.include_router(providers_router.router, prefix=settings.api_v1_prefix)
    app.include_router(library_router.router, prefix=settings.api_v1_prefix)
    app.include_router(labels_router.router, prefix=settings.api_v1_prefix)

    @app.on_event("startup")
    async def startup() -> None:
        settings.storage_dir.mkdir(parents=True, exist_ok=True)
        settings.uploads_dir.mkdir(parents=True, exist_ok=True)
        logger.info("RiceGPT AI started with provider=%s", settings.selected_provider)

    @app.get("/")
    async def root():
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "status": "running",
            "docs": "/docs",
        }

    return app


app = create_app()


if __name__ == "__main__":
    runtime_settings = get_settings()
    uvicorn.run(
        "app.main:app",
        host=runtime_settings.server_host,
        port=runtime_settings.server_port,
        reload=runtime_settings.debug,
    )
