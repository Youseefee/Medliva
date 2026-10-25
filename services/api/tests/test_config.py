import pytest

from app.core.config import Settings


def test_production_rejects_insecure_defaults() -> None:
    with pytest.raises(ValueError, match="Invalid production configuration"):
        Settings(_env_file=None, env="prod")


def test_production_accepts_explicit_secure_configuration() -> None:
    settings = Settings(
        env="prod",
        database_url="postgresql+asyncpg://user:password@localhost/medliva",
        supabase_url="https://example.supabase.co",
        supabase_publishable_key="sb_publishable_example",
        cors_origins=["https://portal.example.com"],
    )

    assert settings.is_prod is True
    assert settings.cors_origins == ["https://portal.example.com"]
