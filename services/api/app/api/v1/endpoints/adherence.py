import uuid
from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.core.errors import AppError
from app.db.session import get_db
from app.models.emergency import Alert, AlertType
from app.models.medication import IntakeLog, IntakeStatus, Medication, Schedule
from app.models.user import User
from app.models.vitals import VitalsLog, VitalType
from app.schemas.adherence import (
    IntakeLogCreate,
    IntakeLogOut,
    SyncBatchRequest,
    SyncBatchResponse,
)
from app.services.triage import triage_bp, triage_glucose, triage_pulse

router = APIRouter(tags=["adherence"])


@router.post("/adherence/log", response_model=IntakeLogOut)
async def log_adherence(
    payload: IntakeLogCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> IntakeLogOut:
    sched = await db.get(Schedule, payload.schedule_id)
    if not sched:
        raise AppError(404, "SCHEDULE_NOT_FOUND", "الجدول الزمني غير موجود")

    med = await db.get(Medication, sched.medication_id)
    if not med:
        raise AppError(404, "MEDICATION_NOT_FOUND", "الدواء غير موجود")

    await check_patient_access(med.patient_id, current_user, db)

    # Check for idempotent submission by client_uuid
    stmt = select(IntakeLog).where(IntakeLog.client_uuid == payload.client_uuid)
    res = await db.execute(stmt)
    existing_log = res.scalar_one_or_none()

    if existing_log:
        return IntakeLogOut.model_validate(existing_log)

    status_enum = IntakeStatus(payload.status)
    actual_time = payload.actual_time or (
        datetime.now(UTC) if status_enum == IntakeStatus.TAKEN else None
    )

    log = IntakeLog(
        client_uuid=payload.client_uuid,
        schedule_id=sched.id,
        patient_id=med.patient_id,
        scheduled_time=payload.scheduled_time,
        actual_time=actual_time,
        status=status_enum,
        reason=payload.reason,
        logged_offline=payload.logged_offline,
    )
    db.add(log)

    # Deduct stock if taken
    if status_enum == IntakeStatus.TAKEN:
        med.stock_count = max(0, int(med.stock_count - sched.dose_amount))
        # Trigger low stock alert if threshold crossed
        if med.stock_count <= med.alert_threshold_days:
            low_alert = Alert(
                patient_id=med.patient_id,
                type=AlertType.LOW_STOCK,
                tier=1,
                payload_json=(
                    f'{{"medication_id": "{med.id}", "name": "{med.name}", '
                    f'"stock_count": {med.stock_count}}}'
                ),
            )
            db.add(low_alert)

    await db.commit()
    await db.refresh(log)

    return IntakeLogOut.model_validate(log)


@router.post("/sync/batch", response_model=SyncBatchResponse)
async def sync_batch(
    payload: SyncBatchRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SyncBatchResponse:
    synced_uuids: list[str] = []

    for item in payload.items:
        if item.entity == "intake_log":
            # Idempotency check
            stmt = select(IntakeLog).where(IntakeLog.client_uuid == item.client_uuid)
            res = await db.execute(stmt)
            if res.scalar_one_or_none():
                synced_uuids.append(item.client_uuid)
                continue

            schedule_id = uuid.UUID(str(item.payload["schedule_id"]))
            sched = await db.get(Schedule, schedule_id)
            if not sched:
                continue

            med = await db.get(Medication, sched.medication_id)
            if not med:
                continue

            scheduled_time = datetime.fromisoformat(item.payload["scheduled_time"])
            actual_time_raw = item.payload.get("actual_time")
            actual_time = datetime.fromisoformat(actual_time_raw) if actual_time_raw else None
            status_enum = IntakeStatus(item.payload.get("status", "taken"))

            log = IntakeLog(
                client_uuid=item.client_uuid,
                schedule_id=sched.id,
                patient_id=med.patient_id,
                scheduled_time=scheduled_time,
                actual_time=actual_time,
                status=status_enum,
                reason=item.payload.get("reason"),
                logged_offline=True,
            )
            db.add(log)

            if status_enum == IntakeStatus.TAKEN:
                med.stock_count = max(0, int(med.stock_count - sched.dose_amount))

            synced_uuids.append(item.client_uuid)

        elif item.entity == "vitals_log":
            # Idempotency check
            stmt = select(VitalsLog).where(VitalsLog.client_uuid == item.client_uuid)
            res = await db.execute(stmt)
            if res.scalar_one_or_none():
                synced_uuids.append(item.client_uuid)
                continue

            patient_id = (
                uuid.UUID(str(item.payload.get("patient_id")))
                if item.payload.get("patient_id")
                else current_user.id
            )
            vital_type = VitalType(item.payload["type"])
            p_val = float(item.payload["value_primary"])
            s_val = (
                float(item.payload["value_secondary"])
                if item.payload.get("value_secondary") is not None
                else None
            )
            meal_ctx = item.payload.get("meal_context")

            if vital_type == VitalType.BP:
                band, _ = triage_bp(p_val, s_val)
            elif vital_type == VitalType.GLUCOSE:
                band, _ = triage_glucose(p_val, meal_ctx)
            else:
                band, _ = triage_pulse(p_val)

            vlog = VitalsLog(
                client_uuid=item.client_uuid,
                patient_id=patient_id,
                type=vital_type,
                value_primary=p_val,
                value_secondary=s_val,
                meal_context=meal_ctx,
                band=band,
                raw_transcript=item.payload.get("raw_transcript"),
            )
            db.add(vlog)
            synced_uuids.append(item.client_uuid)

    await db.commit()
    return SyncBatchResponse(processed=len(synced_uuids), synced_client_uuids=synced_uuids)
