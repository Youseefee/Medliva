from functools import lru_cache
from pathlib import Path
from typing import Literal

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
    cors_origins: list[str] = ["*"]

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
    # In dev, the OTP is returned in the response instead of being sent by SMS.
    otp_return_in_response: bool = True

    @property
    def is_prod(self) -> bool:
        return self.env == "prod"


@lru_cache
def get_settings() -> Settings:
    return Settings()
