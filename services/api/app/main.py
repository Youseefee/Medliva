from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_v1_router
from app.core.config import get_settings
from app.core.errors import register_error_handlers
from app.db.base import Base
from app.db.session import engine


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    # In local development with SQLite, automatically create tables if they don't exist
    if "sqlite" in settings.database_url:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=settings.project_name,
        openapi_url=None if settings.is_prod else f"{settings.api_prefix}/openapi.json",
        docs_url=None if settings.is_prod else "/docs",
        redoc_url=None if settings.is_prod else "/redoc",
        lifespan=lifespan,
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_origin_regex=(
            None if settings.is_prod else r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"
        ),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Standardized Error Handling
    register_error_handlers(app)

    # Health check
    @app.get("/health", tags=["system"])
    async def health_check() -> dict[str, str]:
        return {
            "status": "ok",
            "app": settings.project_name,
            "env": settings.env,
        }

    # API v1
    app.include_router(api_v1_router, prefix=settings.api_prefix)

    return app


app = create_app()
