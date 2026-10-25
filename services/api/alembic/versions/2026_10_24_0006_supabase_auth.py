"""Move account identity to Supabase Auth and remove legacy SMS settings.

Revision ID: 0006_supabase_auth
Revises: 0005_fk_indexes
Create Date: 2026-10-24 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0006_supabase_auth"
down_revision: str | None = "0005_fk_indexes"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _table_names() -> set[str]:
    return set(sa.inspect(op.get_bind()).get_table_names())


def _columns(table_name: str) -> set[str]:
    return {column["name"] for column in sa.inspect(op.get_bind()).get_columns(table_name)}


def upgrade() -> None:
    tables = _table_names()
    if "refresh_sessions" in tables:
        if "ix_refresh_sessions_user_id" in {
            index["name"] for index in sa.inspect(op.get_bind()).get_indexes("refresh_sessions")
        }:
            op.drop_index("ix_refresh_sessions_user_id", table_name="refresh_sessions")
        op.drop_table("refresh_sessions")

    if "otp_challenges" in tables:
        if "ix_otp_challenges_phone" in {
            index["name"] for index in sa.inspect(op.get_bind()).get_indexes("otp_challenges")
        }:
            op.drop_index("ix_otp_challenges_phone", table_name="otp_challenges")
        op.drop_table("otp_challenges")

    if "users" in tables:
        user_columns = _columns("users")
        if "email" not in user_columns:
            op.add_column("users", sa.Column("email", sa.String(length=320), nullable=True))
            op.create_index("ix_users_email", "users", ["email"], unique=True)
        if "phone" in user_columns and not next(
            column["nullable"]
            for column in sa.inspect(op.get_bind()).get_columns("users")
            if column["name"] == "phone"
        ):
            with op.batch_alter_table("users") as batch_op:
                batch_op.alter_column(
                    "phone",
                    existing_type=sa.String(length=20),
                    nullable=True,
                )

    if "emergency_contacts" in tables and "notify_sms" in _columns("emergency_contacts"):
        with op.batch_alter_table("emergency_contacts") as batch_op:
            batch_op.drop_column("notify_sms")


def downgrade() -> None:
    tables = _table_names()
    if "users" in tables and "phone" in _columns("users"):
        phone_column = next(
            column
            for column in sa.inspect(op.get_bind()).get_columns("users")
            if column["name"] == "phone"
        )
        if phone_column["nullable"]:
            with op.batch_alter_table("users") as batch_op:
                batch_op.alter_column(
                    "phone",
                    existing_type=sa.String(length=20),
                    nullable=False,
                )

    if "users" in tables and "email" not in _columns("users"):
        op.add_column("users", sa.Column("email", sa.String(length=320), nullable=True))
        op.create_index("ix_users_email", "users", ["email"], unique=True)

    if "otp_challenges" not in tables:
        op.create_table(
            "otp_challenges",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("phone", sa.String(length=20), nullable=False),
            sa.Column("code_hash", sa.String(length=64), nullable=False),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("attempts", sa.Integer(), server_default="0", nullable=False),
            sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.func.now(),
                nullable=False,
            ),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                server_default=sa.func.now(),
                nullable=False,
            ),
            sa.PrimaryKeyConstraint("id", name=op.f("pk_otp_challenges")),
        )
        op.create_index("ix_otp_challenges_phone", "otp_challenges", ["phone"])

    if "refresh_sessions" not in tables:
        op.create_table(
            "refresh_sessions",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("jti", sa.String(length=64), nullable=False),
            sa.Column("token_hash", sa.String(length=64), nullable=False),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.func.now(),
                nullable=False,
            ),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                server_default=sa.func.now(),
                nullable=False,
            ),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id", name=op.f("pk_refresh_sessions")),
            sa.UniqueConstraint("jti", name=op.f("uq_refresh_sessions_jti")),
            sa.UniqueConstraint("token_hash", name=op.f("uq_refresh_sessions_token_hash")),
        )
        op.create_index("ix_refresh_sessions_user_id", "refresh_sessions", ["user_id"])

    if "emergency_contacts" in tables and "notify_sms" not in _columns("emergency_contacts"):
        with op.batch_alter_table("emergency_contacts") as batch_op:
            batch_op.add_column(
                sa.Column("notify_sms", sa.Boolean(), server_default=sa.true(), nullable=False)
            )

    if "users" in tables:
        user_columns = _columns("users")
        if "email" in user_columns:
            op.drop_index("ix_users_email", table_name="users")
            op.drop_column("users", "email")
