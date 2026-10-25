"""Shared adherence computations used by the caregiver and alert endpoints."""

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, time, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.medication import IntakeLog, IntakeStatus, Medication, Schedule

# A dose counts as missed 15 minutes after its scheduled time.
MISSED_DOSE_GRACE_MINUTES = 15


@dataclass(frozen=True)
class MissedDose:
    """A dose that was neither taken nor skipped before the grace period ended."""

    schedule_id: uuid.UUID
    medication_id: uuid.UUID
    medication_name: str
    time_of_day: str
    scheduled_time: datetime


async def compute_patient_adherence_and_alerts(
    patient_id: uuid.UUID,
    db: AsyncSession,
    now_utc: datetime,
) -> tuple[int, int, list[MissedDose]]:
    """Return (taken today, missed today, missed dose details) for a patient."""
    med_stmt = select(Medication).where(
        Medication.patient_id == patient_id,
        Medication.is_active == True,  # noqa: E712
    )
    med_res = await db.execute(med_stmt)
    medications = {m.id: m for m in med_res.scalars().all()}
    if not medications:
        return 0, 0, []

    sched_stmt = select(Schedule).where(
        Schedule.medication_id.in_(list(medications.keys())),
        Schedule.is_active == True,  # noqa: E712
    )
    sched_res = await db.execute(sched_stmt)
    schedules = sched_res.scalars().all()

    today_date = now_utc.date()
    start_of_today = datetime.combine(today_date, time.min).replace(tzinfo=UTC)
    end_of_today = datetime.combine(today_date, time.max).replace(tzinfo=UTC)

    logs_stmt = select(IntakeLog).where(
        IntakeLog.patient_id == patient_id,
        IntakeLog.scheduled_time >= start_of_today,
        IntakeLog.scheduled_time <= end_of_today,
    )
    logs_res = await db.execute(logs_stmt)
    logs_by_schedule = {log.schedule_id: log for log in logs_res.scalars().all()}

    taken_count = 0
    missed_doses: list[MissedDose] = []

    for sched in sorted(schedules, key=lambda s: s.time_of_day):
        med = medications[sched.medication_id]
        scheduled_dt = datetime.combine(today_date, sched.time_of_day).replace(tzinfo=UTC)
        log = logs_by_schedule.get(sched.id)

        if log:
            if log.status == IntakeStatus.TAKEN:
                taken_count += 1
            elif log.status == IntakeStatus.MISSED:
                missed_doses.append(
                    MissedDose(
                        schedule_id=sched.id,
                        medication_id=med.id,
                        medication_name=med.name,
                        time_of_day=sched.time_of_day.strftime("%H:%M"),
                        scheduled_time=scheduled_dt,
                    )
                )
        elif now_utc >= scheduled_dt + timedelta(minutes=MISSED_DOSE_GRACE_MINUTES):
            missed_doses.append(
                MissedDose(
                    schedule_id=sched.id,
                    medication_id=med.id,
                    medication_name=med.name,
                    time_of_day=sched.time_of_day.strftime("%H:%M"),
                    scheduled_time=scheduled_dt,
                )
            )

    return taken_count, len(missed_doses), missed_doses
