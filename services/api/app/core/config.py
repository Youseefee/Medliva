from functools import lru_cache
from pathlib import Path
from typing import Literal, Self

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

API_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = API_DIR.parents[1]


class Settings(BaseSettings):
    """App settings, loaded from env vars, then infra/.env, then services/api/.env."""

    model_config = SettingsConfigDict(
        env_file=(REPO_ROOT / "infra" / ".env", API_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    env: Literal["dev", "test", "prod"] = "dev"
    project_name: str = "Medliva API"
    api_prefix: str = "/api/v1"
    cors_origins: list[str] = ["http://localhost:3000"]

    # Supabase Postgres (asyncpg driver)
    database_url: str = "sqlite+aiosqlite:///./medliva_dev.db"
    redis_url: str | None = None

    # Supabase Auth
    supabase_url: str = ""
    supabase_publishable_key: str = ""

    # Optional Gemini API key for real prescription vision OCR
    gemini_api_key: str = ""

    @model_validator(mode="after")
    def validate_production_security(self) -> Self:
        if not self.is_prod:
            return self

        problems: list[str] = []
        if not self.supabase_url.startswith("https://"):
            problems.append("SUPABASE_URL must be an https URL")
        if not self.supabase_publishable_key:
            problems.append("SUPABASE_PUBLISHABLE_KEY is required")
        if not self.cors_origins or "*" in self.cors_origins:
            problems.append("CORS_ORIGINS must contain explicit trusted origins in production")
        if self.database_url.startswith("sqlite"):
            problems.append("DATABASE_URL must use PostgreSQL in production")

        if problems:
            raise ValueError("Invalid production configuration: " + "; ".join(problems))
        return self

    @property
    def is_prod(self) -> bool:
        return self.env == "prod"


@lru_cache
def get_settings() -> Settings:
    return Settings()
