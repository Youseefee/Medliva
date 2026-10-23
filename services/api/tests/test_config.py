import pytest

from app.core.config import Settings


def test_production_rejects_insecure_defaults() -> None:
    with pytest.raises(ValueError, match="Invalid production configuration"):
        Settings(env="prod")


def test_production_accepts_explicit_secure_configuration() -> None:
    settings = Settings(
        env="prod",
        database_url="postgresql+asyncpg://user:password@localhost/careelder",
        jwt_secret="a" * 64,
        cors_origins=["https://portal.example.com"],
        otp_return_in_response=False,
    )

    assert settings.is_prod is True
    assert settings.cors_origins == ["https://portal.example.com"]
