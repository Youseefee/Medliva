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
    project_name: str = "CareElder API"
    api_prefix: str = "/api/v1"
    cors_origins: list[str] = ["http://localhost:3000"]

    # Supabase Postgres (asyncpg driver)
    database_url: str = "sqlite+aiosqlite:///./careelder_dev.db"
    redis_url: str | None = None

    # Auth
    jwt_secret: str = "change_me_dev_only_secret_key_32chars!!"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 30

    # OTP
    otp_length: int = 6
    otp_ttl_seconds: int = 300
    otp_resend_cooldown_seconds: int = 60
    otp_max_attempts: int = 5
    otp_max_requests_per_hour: int = 5
    # In local development this can be enabled instead of configuring an SMS provider.
    otp_return_in_response: bool = False

    @model_validator(mode="after")
    def validate_production_security(self) -> Self:
        if not self.is_prod:
            return self

        problems: list[str] = []
        if len(self.jwt_secret) < 32 or self.jwt_secret.startswith("change_me"):
            problems.append("JWT_SECRET must be a non-default secret with at least 32 characters")
        if self.otp_return_in_response:
            problems.append("OTP_RETURN_IN_RESPONSE must be false in production")
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
