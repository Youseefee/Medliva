import re
from typing import Any

from rapidfuzz import fuzz, process

from app.services.triage import triage_bp, triage_glucose, triage_pulse

# Common Egyptian medication database seeds for matching
COMMON_EGYPTIAN_DRUGS = [
    {
        "trade_name": "Glucophage 500mg",
        "active_ingredient": "Metformin",
        "form": "قرص",
        "strength": "500mg",
        "default_times": ["08:30", "20:30"],
        "meal_relation": "after_meal",
    },
    {
        "trade_name": "Glucophage 1000mg",
        "active_ingredient": "Metformin",
        "form": "قرص",
        "strength": "1000mg",
        "default_times": ["09:00", "21:00"],
        "meal_relation": "after_meal",
    },
    {
        "trade_name": "Concor 5mg",
        "active_ingredient": "Bisoprolol",
        "form": "قرص",
        "strength": "5mg",
        "default_times": ["08:00"],
        "meal_relation": "before_meal",
    },
    {
        "trade_name": "Concor 2.5mg",
        "active_ingredient": "Bisoprolol",
        "form": "قرص",
        "strength": "2.5mg",
        "default_times": ["08:00"],
        "meal_relation": "before_meal",
    },
    {
        "trade_name": "Augmentin 1g",
        "active_ingredient": "Amoxicillin / Clavulanate",
        "form": "قرص",
        "strength": "1000mg",
        "default_times": ["09:00", "21:00"],
        "meal_relation": "after_meal",
    },
    {
        "trade_name": "Panadol Extra",
        "active_ingredient": "Paracetamol / Caffeine",
        "form": "قرص",
        "strength": "500mg",
        "default_times": ["12:00"],
        "meal_relation": "after_meal",
    },
    {
        "trade_name": "Aspirin Protect 100mg",
        "active_ingredient": "Acetylsalicylic acid",
        "form": "قرص",
        "strength": "100mg",
        "default_times": ["13:00"],
        "meal_relation": "after_meal",
    },
    {
        "trade_name": "Plavix 75mg",
        "active_ingredient": "Clopidogrel",
        "form": "قرص",
        "strength": "75mg",
        "default_times": ["14:00"],
        "meal_relation": "independent",
    },
    {
        "trade_name": "Lipitor 20mg",
        "active_ingredient": "Atorvastatin",
        "form": "قرص",
        "strength": "20mg",
        "default_times": ["21:00"],
        "meal_relation": "after_meal",
    },
    {
        "trade_name": "Januvia 100mg",
        "active_ingredient": "Sitagliptin",
        "form": "قرص",
        "strength": "100mg",
        "default_times": ["08:30"],
        "meal_relation": "with_meal",
    },
]

ARABIC_NUMBER_WORDS = {
    "صفر": 0,
    "واحد": 1,
    "اتنين": 2,
    "اثنين": 2,
    "تلاتة": 3,
    "ثلاثة": 3,
    "اربعة": 4,
    "أربعة": 4,
    "خمسة": 5,
    "ستة": 6,
    "سبعة": 7,
    "تمانية": 8,
    "ثمانية": 8,
    "تسعة": 9,
    "عشرة": 10,
    "عشرين": 20,
    "تلاتين": 30,
    "ثلاثين": 30,
    "اربعين": 40,
    "أربعين": 40,
    "خمسين": 50,
    "ستين": 60,
    "سبعين": 70,
    "تمانين": 80,
    "ثمانين": 80,
    "تسعين": 90,
    "مية": 100,
    "مئة": 100,
    "مائة": 100,
    "ميتين": 200,
    "مئتين": 200,
    "تلتمية": 300,
    "ثلاثمائة": 300,
}


def normalize_arabic_spoken_numbers(text: str) -> str:
    cleaned = text
    # Replace compound numbers like "مية وخمسة وتلاتين" -> 135
    # Replace "على" or "فوق" with slash "/"
    cleaned = re.sub(r"\s+(على|فوق|من)\s+", " / ", cleaned)

    # Convert common spoken phrases:
    compound_patterns = [
        ("مية وخمسة وتلاتين", "135"),
        ("مية وعشرين", "120"),
        ("مية وتلاتين", "130"),
        ("مية واربعين", "140"),
        ("مية وخمسين", "150"),
        ("مية وستين", "160"),
        ("مية وسبعين", "170"),
        ("مية وتمانين", "180"),
        ("مية وتسعين", "190"),
        ("خمسة وتسعين", "95"),
        ("خمسة وتمانين", "85"),
        ("خمسة وسبعين", "75"),
        ("تسعين", "90"),
        ("تمانين", "80"),
        ("ثمانين", "80"),
        ("سبعين", "70"),
        ("ستين", "60"),
        ("خمسين", "50"),
        ("اربعين", "40"),
        ("تلاتين", "30"),
        ("عشرين", "20"),
        ("مية", "100"),
    ]

    for pattern, rep in compound_patterns:
        cleaned = cleaned.replace(pattern, rep)

    return cleaned


def parse_voice_vitals(transcript: str) -> dict[str, Any]:
    normalized = normalize_arabic_spoken_numbers(transcript)

    # Detect context
    is_bp = any(w in normalized for w in ["ضغط", "الضغط", "ضغطى", "ضغط الدم"])
    is_glucose = any(w in normalized for w in ["سكر", "السكر", "سكرى", "تحليل السكر"])
    is_pulse = any(w in normalized for w in ["نبض", "النبض", "ضربات"])

    # Extract meal context
    meal_context = None
    if any(w in normalized for w in ["صايم", "صائم", "الصبح"]):
        meal_context = "fasting"
    elif any(w in normalized for w in ["فاطر", "بعد الاكل", "بعد الأكل"]):
        meal_context = "post_prandial"

    # 1. Blood pressure: look for pattern X / Y or X على Y
    bp_match = re.search(r"(\d{2,3})\s*(?:/|\s+على\s+|\s+فوق\s+)\s*(\d{2,3})", normalized)
    if bp_match or is_bp:
        if bp_match:
            sys_val = float(bp_match.group(1))
            dia_val = float(bp_match.group(2))
        else:
            nums = [float(n) for n in re.findall(r"\d+", normalized)]
            sys_val = nums[0] if len(nums) > 0 else 120.0
            dia_val = nums[1] if len(nums) > 1 else 80.0

        band, message = triage_bp(sys_val, dia_val)
        return {
            "type": "bp",
            "value_primary": sys_val,
            "value_secondary": dia_val,
            "meal_context": meal_context,
            "band": band,
            "message_ar": message,
            "transcript": transcript,
        }

    # 2. Glucose
    if is_glucose or meal_context:
        nums = [float(n) for n in re.findall(r"\d+", normalized)]
        val = nums[0] if nums else 110.0
        band, message = triage_glucose(val, meal_context)
        return {
            "type": "glucose",
            "value_primary": val,
            "value_secondary": None,
            "meal_context": meal_context or "random",
            "band": band,
            "message_ar": message,
            "transcript": transcript,
        }

    # 3. Pulse
    if is_pulse:
        nums = [float(n) for n in re.findall(r"\d+", normalized)]
        val = nums[0] if nums else 75.0
        band, message = triage_pulse(val)
        return {
            "type": "pulse",
            "value_primary": val,
            "value_secondary": None,
            "meal_context": None,
            "band": band,
            "message_ar": message,
            "transcript": transcript,
        }

    # Fallback: check if numbers exist
    nums = [float(n) for n in re.findall(r"\d+", normalized)]
    if len(nums) >= 2:
        sys_val, dia_val = nums[0], nums[1]
        band, message = triage_bp(sys_val, dia_val)
        return {
            "type": "bp",
            "value_primary": sys_val,
            "value_secondary": dia_val,
            "meal_context": meal_context,
            "band": band,
            "message_ar": message,
            "transcript": transcript,
        }
    if len(nums) == 1:
        val = nums[0]
        if val > 150:
            # likely glucose
            band, message = triage_glucose(val, meal_context)
            return {
                "type": "glucose",
                "value_primary": val,
                "value_secondary": None,
                "meal_context": meal_context or "random",
                "band": band,
                "message_ar": message,
                "transcript": transcript,
            }
        else:
            band, message = triage_pulse(val)
            return {
                "type": "pulse",
                "value_primary": val,
                "value_secondary": None,
                "meal_context": None,
                "band": band,
                "message_ar": message,
                "transcript": transcript,
            }

    # Default fallback
    band, message = triage_bp(120, 80)
    return {
        "type": "bp",
        "value_primary": 120.0,
        "value_secondary": 80.0,
        "meal_context": None,
        "band": band,
        "message_ar": message,
        "transcript": transcript,
    }


def match_drug_in_catalog(
    raw_name: str, catalog: list[dict[str, Any]] | None = None
) -> tuple[dict[str, Any] | None, float]:
    candidates = catalog or COMMON_EGYPTIAN_DRUGS
    trade_names = [c["trade_name"] for c in candidates]

    result = process.extractOne(
        raw_name,
        trade_names,
        scorer=fuzz.token_sort_ratio,
        score_cutoff=60.0,
    )
    if result:
        best_name, score, idx = result
        return candidates[idx], score / 100.0
    return None, 0.0


def scan_prescription_mock(text_or_hint: str = "") -> list[dict[str, Any]]:
    # Simulated OCR extraction with intelligent fuzzy matching against Egyptian drug catalog
    extracted = []
    sample_items = [
        ("Glucophage 500mg", 500, 2, "after_meal", ["08:30", "20:30"], 60),
        ("Concor 5mg", 5, 1, "before_meal", ["08:00"], 30),
    ]

    for name_candidate, dose_mg, freq, meal, times, stock in sample_items:
        match, conf = match_drug_in_catalog(name_candidate)
        extracted.append({
            "drug_trade_name": match["trade_name"] if match else name_candidate,
            "dosage_mg": dose_mg,
            "frequency_per_day": freq,
            "meal_relation": meal,
            "times": times,
            "inventory_pills": stock,
            "confidence_score": max(conf, 0.94),
            "active_ingredient": match.get("active_ingredient") if match else None,
        })

    return extracted
