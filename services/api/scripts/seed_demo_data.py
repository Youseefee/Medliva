# ruff: noqa: E402
"""Seed demo data for the graduation presentation.

The script is idempotent: running it twice never duplicates a row, it only
refreshes the existing one. It can be used in several convenient ways:

    # 1. Seed the Egyptian drug catalog only:
    uv run python scripts/seed_demo_data.py

    # 2. Seed catalog + automatically attach demo history to first patient in DB:
    uv run python scripts/seed_demo_data.py --auto-patient

    # 3. Seed catalog + attach demo history by patient email:
    uv run python scripts/seed_demo_data.py --patient-email user@example.com

    # 4. Seed catalog + attach demo history to a specific UUID:
    uv run python scripts/seed_demo_data.py --patient-id <UUID>
"""

import argparse
import asyncio
import json
import sys
import uuid
from datetime import UTC, date, datetime, time, timedelta
from pathlib import Path
from typing import Any

# Ensure services/api is on sys.path so the script can be invoked cleanly
API_ROOT = Path(__file__).resolve().parent.parent
if str(API_ROOT) not in sys.path:
    sys.path.insert(0, str(API_ROOT))

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import SessionLocal
from app.models.emergency import Alert, AlertType
from app.models.medication import (
    DrugCatalog,
    IntakeLog,
    IntakeStatus,
    MealRelation,
    Medication,
    Schedule,
)
from app.models.user import User, UserRole
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


async def resolve_patient(
    db: AsyncSession,
    patient_id: uuid.UUID | None = None,
    patient_email: str | None = None,
    auto_patient: bool = False,
) -> User | None:
    """Resolve target patient by ID, email, or automatically picking the first patient."""
    if patient_id is not None:
        user = await db.get(User, patient_id)
        if user is None:
            raise ValueError(f"Patient with ID '{patient_id}' not found in database.")
        return user

    if patient_email is not None:
        result = await db.execute(
            select(User).where(func.lower(User.email) == patient_email.lower().strip()).limit(1)
        )
        user = result.scalar_one_or_none()
        if user is None:
            raise ValueError(f"Patient with email '{patient_email}' not found in database.")
        return user

    if auto_patient:
        result = await db.execute(
            select(User)
            .where(User.role == UserRole.PATIENT)
            .order_by(User.created_at.asc())
            .limit(1)
        )
        user = result.scalar_one_or_none()
        if user is None:
            result = await db.execute(select(User).order_by(User.created_at.asc()).limit(1))
            user = result.scalar_one_or_none()
        if user is None:
            raise ValueError("No user accounts found in database. Please register a patient first.")
        return user

    return None


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
        client_uuid = f"demo-v-{patient_id}-{day.date()}-bp"
        result = await db.execute(
            select(VitalsLog).where(
                (VitalsLog.client_uuid == client_uuid)
                | (VitalsLog.client_uuid == f"demo-vital-{patient_id}-{day.date()}-bp")
            )
        )
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
            row.client_uuid = client_uuid
            row.value_primary = float(systolic)
            row.value_secondary = float(diastolic)
            row.band = VitalBand(band)

        glucose = 105 + (offset % 5) * 18
        glu_band, _ = triage_glucose(float(glucose), "random")
        client_uuid = f"demo-v-{patient_id}-{day.date()}-glu"
        result = await db.execute(
            select(VitalsLog).where(
                (VitalsLog.client_uuid == client_uuid)
                | (VitalsLog.client_uuid == f"demo-vital-{patient_id}-{day.date()}-glucose")
            )
        )
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
            row.client_uuid = client_uuid
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
            client_uuid = f"demo-in-{schedule.id}-{day.isoformat()}"
            result = await db.execute(
                select(IntakeLog).where(
                    (IntakeLog.client_uuid == client_uuid)
                    | (IntakeLog.client_uuid == f"demo-intake-{schedule.id}-{day.isoformat()}")
                )
            )
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


async def _seed_alerts(
    db: AsyncSession,
    patient_id: uuid.UUID,
    pairs: list[tuple[Medication, Schedule]],
) -> int:
    """Create (or refresh) representative demo alerts for notifications and live presentation."""
    concor_med = next(
        (med for med, _ in pairs if "Concor" in med.name), pairs[0][0] if pairs else None
    )
    concor_id = str(concor_med.id) if concor_med else str(patient_id)

    now = datetime.now(UTC)
    demo_alerts_defs = [
        (
            uuid.uuid5(uuid.NAMESPACE_URL, f"medliva:demo-alert:{patient_id}:low_stock"),
            AlertType.LOW_STOCK,
            1,
            {
                "medication_id": concor_id,
                "medication_name": "Concor 5mg",
                "stock_count": DEMO_STOCK.get("Concor 5mg", 8),
                "note": "المخزون أوشك على النفاد (متبقي 8 أقراص فقط)",
            },
            now - timedelta(hours=2),
        ),
        (
            uuid.uuid5(uuid.NAMESPACE_URL, f"medliva:demo-alert:{patient_id}:critical_vital"),
            AlertType.CRITICAL_VITAL,
            2,
            {
                "type": "bp",
                "value_primary": 185.0,
                "value_secondary": 110.0,
                "note": "قراءة ضغط دم حرجة مسجلة: 185/110 مم زئبق",
            },
            now - timedelta(hours=6),
        ),
        (
            uuid.uuid5(uuid.NAMESPACE_URL, f"medliva:demo-alert:{patient_id}:missed_dose"),
            AlertType.MISSED_DOSE,
            1,
            {
                "medication_name": "Glucophage 500mg",
                "time_of_day": "20:30",
                "note": "جرعة فائتة لم يتم تأكيد تناولها في الموعد المحدد",
            },
            now - timedelta(hours=14),
        ),
    ]

    created = 0
    for alert_id, alert_type, tier, payload, sent_at in demo_alerts_defs:
        result = await db.execute(select(Alert).where(Alert.id == alert_id))
        row = result.scalar_one_or_none()
        payload_json = json.dumps(payload, ensure_ascii=False)
        if row is None:
            db.add(
                Alert(
                    id=alert_id,
                    patient_id=patient_id,
                    type=alert_type,
                    tier=tier,
                    payload_json=payload_json,
                    sent_at=sent_at,
                )
            )
            created += 1
        else:
            row.type = alert_type
            row.tier = tier
            row.payload_json = payload_json
            row.sent_at = sent_at

    await db.commit()
    return created


async def seed_demo_data(
    db: AsyncSession,
    patient_id: uuid.UUID | None = None,
    days: int = 7,
    *,
    patient_email: str | None = None,
    auto_patient: bool = False,
) -> dict[str, Any]:
    """Seed the catalog and, when a patient is given or resolved, a full demo history."""
    catalog_created = await seed_drug_catalog(db)
    total_catalog = await db.scalar(select(func.count()).select_from(DrugCatalog))
    summary: dict[str, Any] = {
        "drug_catalog_created": catalog_created,
        "total_catalog_drugs": total_catalog or 0,
    }

    patient = await resolve_patient(
        db,
        patient_id=patient_id,
        patient_email=patient_email,
        auto_patient=auto_patient,
    )

    if patient is None:
        return summary

    pairs = await _seed_medications(db, patient.id)
    vitals_created = await _seed_vitals(db, patient.id, days=days)
    intake_logs_created = await _seed_intake_logs(db, patient.id, pairs, days=days)
    alerts_created = await _seed_alerts(db, patient.id, pairs)

    total_vitals = await db.scalar(
        select(func.count()).select_from(VitalsLog).where(VitalsLog.patient_id == patient.id)
    )
    total_intakes = await db.scalar(
        select(func.count()).select_from(IntakeLog).where(IntakeLog.patient_id == patient.id)
    )
    total_alerts = await db.scalar(
        select(func.count()).select_from(Alert).where(Alert.patient_id == patient.id)
    )

    summary.update(
        {
            "patient_id": patient.id,
            "patient_name": patient.name or "بدون اسم",
            "patient_email": patient.email or "بدون بريد",
            "patient_phone": patient.phone,
            "medications": len({med.id for med, _ in pairs}),
            "schedules": len(pairs),
            "vitals_created": vitals_created,
            "total_vitals": total_vitals or 0,
            "intake_logs_created": intake_logs_created,
            "total_intake_logs": total_intakes or 0,
            "alerts_created": alerts_created,
            "total_alerts": total_alerts or 0,
        }
    )
    return summary


def print_summary(summary: dict[str, Any]) -> None:
    """Print a clean, structured summary of seeded data for the user."""
    print("\n" + "=" * 68)
    print("             Medliva Demo Data Seed Summary (Supabase)")
    print("=" * 68)
    print(" [Catalog]")
    print(f"   - Newly Added Drugs      : {summary.get('drug_catalog_created', 0)}")
    total_drugs = summary.get("total_catalog_drugs", len(COMMON_EGYPTIAN_DRUGS))
    print(f"   - Total Egyptian Catalog : {total_drugs} drugs")

    if "patient_id" in summary:
        print("\n [Demo Patient]")
        print(f"   - Patient UUID           : {summary['patient_id']}")
        print(f"   - Name                   : {summary.get('patient_name', 'N/A')}")
        print(f"   - Email                  : {summary.get('patient_email', 'N/A')}")
        if summary.get("patient_phone"):
            print(f"   - Phone                  : {summary['patient_phone']}")

        print("\n [Clinical & Adherence Records]")
        meds_count = summary.get("medications", 0)
        drugs_list = ", ".join(DEMO_DRUGS)
        print(f"   - Active Medications     : {meds_count} ({drugs_list})")
        print(f"   - Daily Schedules        : {summary.get('schedules', 0)} times/day")
        print(
            f"   - Vitals Readings        : {summary.get('total_vitals', 0)} readings "
            f"({summary.get('vitals_created', 0)} new)"
        )
        print(
            f"   - Intake History Logs    : {summary.get('total_intake_logs', 0)} logs "
            f"({summary.get('intake_logs_created', 0)} new)"
        )
        print(
            f"   - Alerts Generated       : {summary.get('total_alerts', 0)} alerts "
            f"({summary.get('alerts_created', 0)} new)"
        )
    else:
        print("\n [Demo Patient]")
        print("   - No patient specified. Catalog only seeded.")
        print("   - Tip: Run with --auto-patient to seed records for the first patient:")
        print("       uv run python scripts/seed_demo_data.py --auto-patient")
        print("   - Or specify by email / UUID:")
        print("       uv run python scripts/seed_demo_data.py --patient-email user@example.com")

    print("=" * 68)
    print("Seeding completed successfully.\n")


async def _run(
    patient_id: uuid.UUID | None,
    patient_email: str | None,
    auto_patient: bool,
    days: int,
) -> None:
    async with SessionLocal() as db:
        summary = await seed_demo_data(
            db,
            patient_id=patient_id,
            days=days,
            patient_email=patient_email,
            auto_patient=auto_patient,
        )
    print_summary(summary)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Seed Medliva demo data (Egyptian catalog + patient) into Supabase."
    )
    parser.add_argument(
        "--auto-patient",
        action="store_true",
        help="Automatically select the first patient found in the users table.",
    )
    parser.add_argument(
        "--patient-id",
        type=uuid.UUID,
        default=None,
        help="Optional patient UUID to receive the demo history.",
    )
    parser.add_argument(
        "--patient-email",
        type=str,
        default=None,
        help="Optional patient email to look up and receive the demo history.",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=7,
        help="How many days of vitals and adherence logs to create (default: 7).",
    )
    args = parser.parse_args()
    asyncio.run(_run(args.patient_id, args.patient_email, args.auto_patient, args.days))


if __name__ == "__main__":
    main()
