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


def test_database_url_normalization() -> None:
    s1 = Settings(
        env="dev",
        database_url="postgres://user:pass@aws-0-eu-west-2.pooler.supabase.com:6543/postgres",
    )
    assert s1.database_url.startswith("postgresql+asyncpg://")

    s2 = Settings(
        env="dev",
        database_url="postgresql://user:pass@aws-0-eu-west-2.pooler.supabase.com:5432/postgres",
    )
    assert s2.database_url.startswith("postgresql+asyncpg://")


def test_session_engine_kwargs_for_supabase() -> None:
    from app.db.session import _engine_kwargs

    pg_kwargs = _engine_kwargs("postgresql+asyncpg://user:pass@pooler.supabase.com:6543/postgres")
    assert pg_kwargs["pool_pre_ping"] is True
    assert pg_kwargs["pool_recycle"] == 300
    assert pg_kwargs["connect_args"]["ssl"] == "require"
    assert pg_kwargs["connect_args"]["statement_cache_size"] == 0
    assert pg_kwargs["connect_args"]["prepared_statement_cache_size"] == 0

    sqlite_kwargs = _engine_kwargs("sqlite+aiosqlite:///:memory:")
    assert sqlite_kwargs["pool_pre_ping"] is True
    assert sqlite_kwargs["pool_recycle"] == 300
    assert "connect_args" not in sqlite_kwargs
