"""Clinical triage rule engine following AHA and WHO guidelines."""

from typing import Literal

VitalBand = Literal["normal", "borderline", "critical"]


def triage_bp(systolic: float, diastolic: float | None = None) -> tuple[VitalBand, str]:
    dia = diastolic or 80.0

    if systolic >= 180 or systolic <= 90 or dia >= 120 or dia <= 50:
        return (
            "critical",
            "ضغط الدم في نطاق حرج (خطر). يرجى التواصل مع الطبيب أو التوجه للطوارئ فوراً.",
        )
    if systolic >= 130 or dia > 80:
        return (
            "borderline",
            "ضغط الدم مرتفع قليلاً عن المعدل المثالي. يرجى الاسترخاء وإعادة القياس لاحقاً.",
        )

    return (
        "normal",
        "ضغط الدم طبيعي وممتاز.",
    )


def triage_glucose(value: float, meal_context: str | None = None) -> tuple[VitalBand, str]:
    ctx = (meal_context or "random").lower()

    if ctx in ("fasting", "صايم", "صائم"):
        if value < 70 or value > 250:
            return (
                "critical",
                "مستوى سكر الدم الصائم في نطاق حرج. يرجى التدخل السريع ومراجعة الطبيب.",
            )
        if value > 110:
            return (
                "borderline",
                "مستوى السكر الصائم مرتفع قليلاً عن المعدل الطبيعي.",
            )
        return (
            "normal",
            "مستوى سكر الدم الصائم في المعدل الطبيعي الممتاز.",
        )

    if ctx in ("post_prandial", "فاطر", "بعد_الاكل"):
        if value < 70 or value > 300:
            return (
                "critical",
                "مستوى سكر الدم بعد الأكل في نطاق حرج.",
            )
        if value > 140:
            return (
                "borderline",
                "مستوى سكر الدم بعد الأكل مرتفع قليلاً.",
            )
        return (
            "normal",
            "مستوى سكر الدم بعد الأكل في المعدل الطبيعي.",
        )

    # Random / general
    if value < 70 or value > 250:
        return ("critical", "مستوى السكر في نطاق حرج.")
    if value > 140:
        return ("borderline", "مستوى السكر مرتفع نسبياً.")
    return ("normal", "مستوى السكر طبيعي.")


def triage_pulse(bpm: float) -> tuple[VitalBand, str]:
    if bpm < 50 or bpm > 120:
        return (
            "critical",
            "معدل ضربات القلب حرج (بطيء جداً أو سريع جداً). يرجى مراجعة الطبيب.",
        )
    if bpm < 60 or bpm > 100:
        return (
            "borderline",
            "معدل ضربات القلب خارج النطاق الطبيعي قليلاً.",
        )
    return (
        "normal",
        "معدل ضربات القلب طبيعي ومستقر.",
    )
