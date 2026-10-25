"""Seed demo data for the graduation presentation.

The script is idempotent: running it twice never duplicates a row, it only
refreshes the existing one. It can be used in two ways:

    # 1. Seed the drug catalog only
    uv run python scripts/seed_demo_data.py

    # 2. Seed the catalog and a full demo patient history
    uv run python scripts/seed_demo_data.py --patient-id <UUID>

The patient must already exist (create it from the app or from the API).
"""

import argparse
import asyncio
import uuid
from datetime import UTC, date, datetime, time, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import SessionLocal
from app.models.medication import (
    DrugCatalog,
    IntakeLog,
    IntakeStatus,
    MealRelation,
    Medication,
    Schedule,
)
from app.models.vitals import VitalBand, VitalsLog, VitalType
from app.services.ai_service import COMMON_EGYPTIAN_DRUGS
from app.services.triage import triage_bp, triage_glucose

# The three drugs used for the live demo: two chronic ones and one antibiotic.
DEMO_DRUGS = ["Concor 5mg", "Glucophage 500mg", "Augmentin 1g"]

DEMO_STOCK = {
    "Concor 5mg": 8,
    "Glucophage 500mg": 45,
    "Augmentin 1g": 21,
}


async def seed_drug_catalog(db: AsyncSession) -> int:
    """Insert or refresh every drug of the Egyptian catalog. Returns the count."""
    created = 0
    for drug in COMMON_EGYPTIAN_DRUGS:
        result = await db.execute(
            select(DrugCatalog).where(DrugCatalog.trade_name == drug["trade_name"])
        )
        row = result.scalar_one_or_none()
        if row is None:
            db.add(
                DrugCatalog(
                    trade_name=drug["trade_name"],
                    active_ingredient=drug.get("active_ingredient"),
                    strength=drug.get("strength"),
                    form=drug.get("form", "قرص"),
                )
            )
            created += 1
        else:
            row.active_ingredient = drug.get("active_ingredient")
            row.strength = drug.get("strength")
            row.form = drug.get("form", "قرص")
    await db.commit()
    return created


async def _seed_medications(
    db: AsyncSession, patient_id: uuid.UUID
) -> list[tuple[Medication, Schedule]]:
    """Create (or refresh) the demo medications and their schedules."""
    result = await db.execute(select(DrugCatalog).where(DrugCatalog.trade_name.in_(DEMO_DRUGS)))
    catalog = {row.trade_name: row for row in result.scalars().all()}

    pairs: list[tuple[Medication, Schedule]] = []
    for trade_name in DEMO_DRUGS:
        drug = catalog.get(trade_name)
        if drug is None:
            continue
        times = _times_for(trade_name)

        med_result = await db.execute(
            select(Medication).where(
                Medication.patient_id == patient_id,
                Medication.name == trade_name,
            )
        )
        medication = med_result.scalar_one_or_none()
        if medication is None:
            medication = Medication(
                patient_id=patient_id,
                drug_catalog_id=drug.id,
                name=trade_name,
                trade_name=trade_name,
                active_ingredient=drug.active_ingredient,
                form=drug.form or "قرص",
                strength=drug.strength,
                stock_count=DEMO_STOCK.get(trade_name, 30),
                alert_threshold_days=5,
                expiry_date=date.today() + timedelta(days=45),
                is_active=True,
            )
            db.add(medication)
            await db.flush()
        else:
            medication.drug_catalog_id = drug.id
            medication.stock_count = DEMO_STOCK.get(trade_name, medication.stock_count)
            medication.active_ingredient = drug.active_ingredient
            medication.strength = drug.strength

        for time_of_day, meal_relation in times:
            sched_result = await db.execute(
                select(Schedule).where(
                    Schedule.medication_id == medication.id,
                    Schedule.time_of_day == time_of_day,
                )
            )
            schedule = sched_result.scalar_one_or_none()
            if schedule is None:
                schedule = Schedule(
                    medication_id=medication.id,
                    time_of_day=time_of_day,
                    days_mask=127,
                    dose_amount=1.0,
                    meal_relation=meal_relation,
                    start_date=date.today() - timedelta(days=30),
                    is_active=True,
                )
                db.add(schedule)
                await db.flush()
            else:
                schedule.meal_relation = meal_relation
                schedule.is_active = True
            pairs.append((medication, schedule))

    await db.commit()
    return pairs


def _times_for(trade_name: str) -> list[tuple[time, MealRelation]]:
    if trade_name == "Glucophage 500mg":
        return [
            (time(8, 30), MealRelation.AFTER_MEAL),
            (time(20, 30), MealRelation.AFTER_MEAL),
        ]
    if trade_name == "Augmentin 1g":
        return [
            (time(9, 0), MealRelation.AFTER_MEAL),
            (time(21, 0), MealRelation.AFTER_MEAL),
        ]
    return [(time(8, 0), MealRelation.BEFORE_MEAL)]


async def _seed_vitals(db: AsyncSession, patient_id: uuid.UUID, days: int = 7) -> int:
    """Create 7 days of blood pressure and glucose readings."""
    created = 0
    today = datetime.now(UTC).replace(hour=9, minute=0, second=0, microsecond=0)

    for offset in range(days):
        day = today - timedelta(days=offset)

        systolic = 128 + (offset % 4) * 9
        diastolic = 78 + (offset % 3) * 5
        band, _ = triage_bp(systolic, diastolic)
        client_uuid = f"demo-vital-{patient_id}-{day.date()}-bp"
        result = await db.execute(select(VitalsLog).where(VitalsLog.client_uuid == client_uuid))
        row = result.scalar_one_or_none()
        if row is None:
            db.add(
                VitalsLog(
                    client_uuid=client_uuid,
                    patient_id=patient_id,
                    type=VitalType.BP,
                    value_primary=float(systolic),
                    value_secondary=float(diastolic),
                    band=VitalBand(band),
                    recorded_at=day,
                )
            )
            created += 1
        else:
            row.value_primary = float(systolic)
            row.value_secondary = float(diastolic)
            row.band = VitalBand(band)
        glucose = 105 + (offset % 5) * 18
        glu_band, _ = triage_glucose(float(glucose), "random")
        client_uuid = f"demo-vital-{patient_id}-{day.date()}-glucose"
        result = await db.execute(select(VitalsLog).where(VitalsLog.client_uuid == client_uuid))
        row = result.scalar_one_or_none()
        if row is None:
            db.add(
                VitalsLog(
                    client_uuid=client_uuid,
                    patient_id=patient_id,
                    type=VitalType.GLUCOSE,
                    value_primary=float(glucose),
                    meal_context="random",
                    band=VitalBand(glu_band),
                    recorded_at=day,
                )
            )
            created += 1
        else:
            row.value_primary = float(glucose)
            row.band = VitalBand(glu_band)

    await db.commit()
    return created


async def _seed_intake_logs(
    db: AsyncSession,
    patient_id: uuid.UUID,
    pairs: list[tuple[Medication, Schedule]],
    days: int = 7,
) -> int:
    """Create a believable adherence history for the last 7 days."""
    created = 0
    today = date.today()

    for offset in range(1, days + 1):
        day = today - timedelta(days=offset)
        for _medication, schedule in pairs:
            client_uuid = f"demo-intake-{schedule.id}-{day.isoformat()}"
            result = await db.execute(select(IntakeLog).where(IntakeLog.client_uuid == client_uuid))
            if result.scalar_one_or_none() is not None:
                continue

            scheduled = datetime.combine(day, schedule.time_of_day).replace(tzinfo=UTC)
            # Most doses are taken, some are skipped, the oldest ones are missed.
            if offset >= 5:
                status = IntakeStatus.MISSED
            elif offset % 3 == 0:
                status = IntakeStatus.SKIPPED
            else:
                status = IntakeStatus.TAKEN

            db.add(
                IntakeLog(
                    client_uuid=client_uuid,
                    schedule_id=schedule.id,
                    patient_id=patient_id,
                    scheduled_time=scheduled,
                    actual_time=(
                        scheduled + timedelta(minutes=7) if status == IntakeStatus.TAKEN else None
                    ),
                    status=status,
                    logged_offline=False,
                )
            )
            created += 1

    await db.commit()
    return created


async def seed_demo_data(
    db: AsyncSession,
    patient_id: uuid.UUID | None = None,
    days: int = 7,
) -> dict[str, Any]:
    """Seed the catalog and, when a patient is given, a full demo history."""
    catalog_created = await seed_drug_catalog(db)
    summary: dict[str, Any] = {"drug_catalog_created": catalog_created}

    if patient_id is None:
        return summary

    pairs = await _seed_medications(db, patient_id)
    summary["medications"] = len({med.id for med, _ in pairs})
    summary["schedules"] = len(pairs)
    summary["vitals_created"] = await _seed_vitals(db, patient_id, days=days)
    summary["intake_logs_created"] = await _seed_intake_logs(db, patient_id, pairs, days=days)
    return summary


async def _run(patient_id: uuid.UUID | None, days: int) -> None:
    async with SessionLocal() as db:
        summary = await seed_demo_data(db, patient_id=patient_id, days=days)
    print("Demo data seeded:")
    for key, value in summary.items():
        print(f"  - {key}: {value}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed the Medliva demo data.")
    parser.add_argument(
        "--patient-id",
        type=uuid.UUID,
        default=None,
        help="Optional patient UUID to receive the demo history.",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=7,
        help="How many days of vitals and adherence logs to create.",
    )
    args = parser.parse_args()
    asyncio.run(_run(args.patient_id, args.days))


if __name__ == "__main__":
    main()
