"""Add domain models for caregiver, medications, vitals, prescriptions, emergency, reports, and devices.

Revision ID: 0003_domain_models
Revises: 0002_refresh_sessions
Create Date: 2026-10-23 13:25:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003_domain_models"
down_revision: str | None = "0002_refresh_sessions"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "drug_catalog",
        sa.Column("trade_name", sa.String(length=150), nullable=False),
        sa.Column("active_ingredient", sa.String(length=150), nullable=True),
        sa.Column("strength", sa.String(length=50), nullable=True),
        sa.Column("form", sa.String(length=50), nullable=True),
        sa.Column("manufacturer", sa.String(length=100), nullable=True),
        sa.Column("price_egp", sa.Float(), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.PrimaryKeyConstraint("id", name=op.f("pk_drug_catalog")),
    )
    op.create_index(
        op.f("ix_drug_catalog_trade_name"), "drug_catalog", ["trade_name"], unique=False
    )

    op.create_table(
        "alerts",
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column(
            "type",
            sa.Enum(
                "MISSED_DOSE",
                "CRITICAL_VITAL",
                "LOW_STOCK",
                "EXPIRY",
                "SOS",
                name="alert_type",
                native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column("tier", sa.Integer(), nullable=False),
        sa.Column("payload_json", sa.Text(), nullable=True),
        sa.Column(
            "sent_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("acknowledged_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_alerts_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_alerts")),
    )
    op.create_index(op.f("ix_alerts_patient_id"), "alerts", ["patient_id"], unique=False)

    op.create_table(
        "caregiver_links",
        sa.Column("caregiver_id", sa.Uuid(), nullable=True),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("pairing_code", sa.String(length=6), nullable=True),
        sa.Column("pairing_code_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "status",
            sa.Enum(
                "PENDING",
                "ACTIVE",
                "REVOKED",
                name="caregiver_link_status",
                native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column("permissions_mask", sa.Integer(), nullable=False),
        sa.Column("linked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["caregiver_id"],
            ["users.id"],
            name=op.f("fk_caregiver_links_caregiver_id_users"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_caregiver_links_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_caregiver_links")),
        sa.UniqueConstraint("caregiver_id", "patient_id", name="uq_caregiver_links_pair"),
    )
    op.create_index(
        op.f("ix_caregiver_links_caregiver_id"), "caregiver_links", ["caregiver_id"], unique=False
    )
    op.create_index(
        op.f("ix_caregiver_links_pairing_code"), "caregiver_links", ["pairing_code"], unique=False
    )
    op.create_index(
        op.f("ix_caregiver_links_patient_id"), "caregiver_links", ["patient_id"], unique=False
    )

    op.create_table(
        "devices",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("fcm_token", sa.String(length=255), nullable=False),
        sa.Column("platform", sa.String(length=20), nullable=False),
        sa.Column("app_version", sa.String(length=20), nullable=True),
        sa.Column(
            "last_seen",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name=op.f("fk_devices_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_devices")),
    )
    op.create_index(op.f("ix_devices_fcm_token"), "devices", ["fcm_token"], unique=True)
    op.create_index(op.f("ix_devices_user_id"), "devices", ["user_id"], unique=False)

    op.create_table(
        "emergency_contacts",
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("relationship", sa.String(length=50), nullable=True),
        sa.Column("is_primary", sa.Boolean(), nullable=False),
        sa.Column("notify_sms", sa.Boolean(), nullable=False),
        sa.Column("notify_call", sa.Boolean(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_emergency_contacts_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_emergency_contacts")),
    )
    op.create_index(
        op.f("ix_emergency_contacts_patient_id"),
        "emergency_contacts",
        ["patient_id"],
        unique=False,
    )

    op.create_table(
        "medications",
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("drug_catalog_id", sa.Uuid(), nullable=True),
        sa.Column("name", sa.String(length=150), nullable=False),
        sa.Column("trade_name", sa.String(length=150), nullable=True),
        sa.Column("active_ingredient", sa.String(length=150), nullable=True),
        sa.Column("form", sa.String(length=50), nullable=False),
        sa.Column("strength", sa.String(length=50), nullable=True),
        sa.Column("pill_image_url", sa.String(length=500), nullable=True),
        sa.Column("stock_count", sa.Integer(), nullable=False),
        sa.Column("alert_threshold_days", sa.Integer(), nullable=False),
        sa.Column("expiry_date", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["drug_catalog_id"],
            ["drug_catalog.id"],
            name=op.f("fk_medications_drug_catalog_id_drug_catalog"),
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_medications_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_medications")),
    )
    op.create_index(op.f("ix_medications_patient_id"), "medications", ["patient_id"], unique=False)

    op.create_table(
        "prescriptions",
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("image_url", sa.String(length=500), nullable=True),
        sa.Column("doctor_name", sa.String(length=150), nullable=True),
        sa.Column("raw_extracted_json", sa.Text(), nullable=True),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("verified_by", sa.Uuid(), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_prescriptions_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["verified_by"],
            ["users.id"],
            name=op.f("fk_prescriptions_verified_by_users"),
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_prescriptions")),
    )
    op.create_index(
        op.f("ix_prescriptions_patient_id"), "prescriptions", ["patient_id"], unique=False
    )

    op.create_table(
        "report_shares",
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("scope", sa.String(length=50), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("views_count", sa.Integer(), nullable=False),
        sa.Column("revoked", sa.Boolean(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_report_shares_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_report_shares")),
    )
    op.create_index(
        op.f("ix_report_shares_patient_id"), "report_shares", ["patient_id"], unique=False
    )
    op.create_index(
        op.f("ix_report_shares_token_hash"), "report_shares", ["token_hash"], unique=True
    )

    op.create_table(
        "vitals_logs",
        sa.Column("client_uuid", sa.String(length=64), nullable=True),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column(
            "type",
            sa.Enum("BP", "GLUCOSE", "PULSE", name="vital_type", native_enum=False),
            nullable=False,
        ),
        sa.Column("value_primary", sa.Float(), nullable=False),
        sa.Column("value_secondary", sa.Float(), nullable=True),
        sa.Column("meal_context", sa.String(length=50), nullable=True),
        sa.Column(
            "band",
            sa.Enum("NORMAL", "BORDERLINE", "CRITICAL", name="vital_band", native_enum=False),
            nullable=False,
        ),
        sa.Column("raw_transcript", sa.Text(), nullable=True),
        sa.Column(
            "recorded_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_vitals_logs_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_vitals_logs")),
    )
    op.create_index(
        op.f("ix_vitals_logs_client_uuid"), "vitals_logs", ["client_uuid"], unique=True
    )
    op.create_index(
        op.f("ix_vitals_logs_patient_id"), "vitals_logs", ["patient_id"], unique=False
    )
    op.create_index(
        op.f("ix_vitals_logs_recorded_at"), "vitals_logs", ["recorded_at"], unique=False
    )

    op.create_table(
        "schedules",
        sa.Column("medication_id", sa.Uuid(), nullable=False),
        sa.Column("time_of_day", sa.Time(), nullable=False),
        sa.Column("days_mask", sa.Integer(), nullable=False),
        sa.Column("dose_amount", sa.Float(), nullable=False),
        sa.Column(
            "meal_relation",
            sa.Enum(
                "BEFORE_MEAL",
                "AFTER_MEAL",
                "WITH_MEAL",
                "INDEPENDENT",
                name="meal_relation",
                native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column("instructions_ar", sa.String(length=255), nullable=True),
        sa.Column("start_date", sa.Date(), nullable=True),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["medication_id"],
            ["medications.id"],
            name=op.f("fk_schedules_medication_id_medications"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_schedules")),
    )
    op.create_index(
        op.f("ix_schedules_medication_id"), "schedules", ["medication_id"], unique=False
    )

    op.create_table(
        "intake_logs",
        sa.Column("client_uuid", sa.String(length=64), nullable=False),
        sa.Column("schedule_id", sa.Uuid(), nullable=False),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("scheduled_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("actual_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "status",
            sa.Enum(
                "TAKEN",
                "SNOOZED",
                "MISSED",
                "SKIPPED",
                name="intake_status",
                native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column("reason", sa.String(length=255), nullable=True),
        sa.Column("logged_offline", sa.Boolean(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["users.id"],
            name=op.f("fk_intake_logs_patient_id_users"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["schedule_id"],
            ["schedules.id"],
            name=op.f("fk_intake_logs_schedule_id_schedules"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_intake_logs")),
    )
    op.create_index(op.f("ix_intake_logs_client_uuid"), "intake_logs", ["client_uuid"], unique=True)
    op.create_index(op.f("ix_intake_logs_patient_id"), "intake_logs", ["patient_id"], unique=False)
    op.create_index(
        op.f("ix_intake_logs_schedule_id"), "intake_logs", ["schedule_id"], unique=False
    )
    op.create_index(
        op.f("ix_intake_logs_scheduled_time"), "intake_logs", ["scheduled_time"], unique=False
    )

    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column(
            "role",
            existing_type=sa.VARCHAR(length=20),
            type_=sa.Enum("PATIENT", "CAREGIVER", "ADMIN", name="user_role", native_enum=False),
            existing_nullable=False,
            existing_server_default=sa.text("'patient'"),
        )


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column(
            "role",
            existing_type=sa.Enum(
                "PATIENT", "CAREGIVER", "ADMIN", name="user_role", native_enum=False
            ),
            type_=sa.VARCHAR(length=20),
            existing_nullable=False,
            existing_server_default=sa.text("'patient'"),
        )

    op.drop_index(op.f("ix_intake_logs_scheduled_time"), table_name="intake_logs")
    op.drop_index(op.f("ix_intake_logs_schedule_id"), table_name="intake_logs")
    op.drop_index(op.f("ix_intake_logs_patient_id"), table_name="intake_logs")
    op.drop_index(op.f("ix_intake_logs_client_uuid"), table_name="intake_logs")
    op.drop_table("intake_logs")
    op.drop_index(op.f("ix_schedules_medication_id"), table_name="schedules")
    op.drop_table("schedules")
    op.drop_index(op.f("ix_vitals_logs_recorded_at"), table_name="vitals_logs")
    op.drop_index(op.f("ix_vitals_logs_patient_id"), table_name="vitals_logs")
    op.drop_index(op.f("ix_vitals_logs_client_uuid"), table_name="vitals_logs")
    op.drop_table("vitals_logs")
    op.drop_index(op.f("ix_report_shares_token_hash"), table_name="report_shares")
    op.drop_index(op.f("ix_report_shares_patient_id"), table_name="report_shares")
    op.drop_table("report_shares")
    op.drop_index(op.f("ix_prescriptions_patient_id"), table_name="prescriptions")
    op.drop_table("prescriptions")
    op.drop_index(op.f("ix_medications_patient_id"), table_name="medications")
    op.drop_table("medications")
    op.drop_index(op.f("ix_emergency_contacts_patient_id"), table_name="emergency_contacts")
    op.drop_table("emergency_contacts")
    op.drop_index(op.f("ix_devices_user_id"), table_name="devices")
    op.drop_index(op.f("ix_devices_fcm_token"), table_name="devices")
    op.drop_table("devices")
    op.drop_index(op.f("ix_caregiver_links_patient_id"), table_name="caregiver_links")
    op.drop_index(op.f("ix_caregiver_links_pairing_code"), table_name="caregiver_links")
    op.drop_index(op.f("ix_caregiver_links_caregiver_id"), table_name="caregiver_links")
    op.drop_table("caregiver_links")
    op.drop_index(op.f("ix_alerts_patient_id"), table_name="alerts")
    op.drop_table("alerts")
    op.drop_index(op.f("ix_drug_catalog_trade_name"), table_name="drug_catalog")
    op.drop_table("drug_catalog")
