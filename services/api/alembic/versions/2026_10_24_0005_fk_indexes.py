"""Add indexes for medication and prescription foreign keys.

Revision ID: 0005_fk_indexes
Revises: 0004_public_rls
Create Date: 2026-10-24 00:45:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0005_fk_indexes"
down_revision: str | None = "0004_public_rls"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_index("ix_medications_drug_catalog_id", "medications", ["drug_catalog_id"])
    op.create_index("ix_prescriptions_verified_by", "prescriptions", ["verified_by"])


def downgrade() -> None:
    op.drop_index("ix_prescriptions_verified_by", table_name="prescriptions")
    op.drop_index("ix_medications_drug_catalog_id", table_name="medications")
