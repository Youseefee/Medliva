"""Enable row-level security on the public schema tables.

Revision ID: 0004_public_rls
Revises: 0003_domain_models
Create Date: 2026-10-24 00:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0004_public_rls"
down_revision: str | None = "0003_domain_models"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

PUBLIC_TABLES = (
    "users",
    "otp_challenges",
    "refresh_sessions",
    "drug_catalog",
    "alerts",
    "caregiver_links",
    "devices",
    "emergency_contacts",
    "medications",
    "prescriptions",
    "report_shares",
    "vitals_logs",
    "schedules",
    "intake_logs",
    "alembic_version",
)


def _set_row_level_security(action: str) -> None:
    if op.get_bind().dialect.name != "postgresql":
        return

    for table in PUBLIC_TABLES:
        op.execute(f"ALTER TABLE public.{table} {action} ROW LEVEL SECURITY")


def upgrade() -> None:
    _set_row_level_security("ENABLE")


def downgrade() -> None:
    _set_row_level_security("DISABLE")
