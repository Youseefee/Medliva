import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdTimestampMixin


class CaregiverLinkStatus(enum.StrEnum):
    PENDING = "pending"
    ACTIVE = "active"
    REVOKED = "revoked"


class CaregiverLink(Base, IdTimestampMixin):
    __tablename__ = "caregiver_links"
    __table_args__ = (
        UniqueConstraint("caregiver_id", "patient_id", name="uq_caregiver_links_pair"),
    )

    caregiver_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=True
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    pairing_code: Mapped[str | None] = mapped_column(String(6), index=True, nullable=True)
    pairing_code_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    status: Mapped[CaregiverLinkStatus] = mapped_column(
        Enum(CaregiverLinkStatus, name="caregiver_link_status", native_enum=False),
        default=CaregiverLinkStatus.PENDING,
        nullable=False,
    )
    permissions_mask: Mapped[int] = mapped_column(Integer, default=255, nullable=False)
    linked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
