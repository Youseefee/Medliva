import urllib.parse
from datetime import UTC, datetime, timedelta
from typing import Any

from app.models.medication import Medication, Schedule


def calculate_medication_forecast(
    medication: Medication, schedules: list[Schedule]
) -> dict[str, Any]:
    active_schedules = [s for s in schedules if s.is_active]
    daily_dose = sum(s.dose_amount for s in active_schedules)

    days_remaining = int(medication.stock_count / daily_dose) if daily_dose > 0 else 999

    today = datetime.now(UTC).date()
    is_low_stock = days_remaining <= medication.alert_threshold_days
    is_expired = bool(medication.expiry_date and medication.expiry_date < today)
    is_expiring_soon = bool(
        medication.expiry_date
        and not is_expired
        and medication.expiry_date <= (today + timedelta(days=30))
    )

    estimated_empty_date = today + timedelta(days=days_remaining) if days_remaining < 999 else None

    return {
        "medication_id": str(medication.id),
        "name": medication.name,
        "stock_count": medication.stock_count,
        "daily_consumption": daily_dose,
        "days_remaining": days_remaining,
        "estimated_empty_date": estimated_empty_date.isoformat() if estimated_empty_date else None,
        "is_low_stock": is_low_stock,
        "is_expired": is_expired,
        "is_expiring_soon": is_expiring_soon,
        "alert_threshold_days": medication.alert_threshold_days,
        "expiry_date": medication.expiry_date.isoformat() if medication.expiry_date else None,
    }


def generate_refill_order_text(
    patient_name: str,
    items: list[dict[str, Any]],
    address: str | None = None,
    note: str | None = None,
) -> str:
    lines = [
        f"السلام عليكم، أود طلب نواقص أدوية للمريض: {patient_name}",
        "الأدوية المطلوبة:",
    ]
    for item in items:
        lines.append(f"• {item.get('name')}: {item.get('quantity', 1)} عبوة")

    if address:
        lines.append(f"العنوان: {address}")
    if note:
        lines.append(f"ملاحظات: {note}")

    lines.append("شكراً جزيلاً.")
    return "\n".join(lines)


def generate_whatsapp_refill_url(pharmacy_phone: str, message_text: str) -> str:
    # Clean phone (remove +, spaces, leading zeroes)
    clean_phone = pharmacy_phone.replace("+", "").replace(" ", "").replace("-", "")
    if clean_phone.startswith("0"):
        clean_phone = "20" + clean_phone[1:]  # Egypt default if starts with 0

    encoded_text = urllib.parse.quote(message_text)
    return f"https://wa.me/{clean_phone}?text={encoded_text}"
