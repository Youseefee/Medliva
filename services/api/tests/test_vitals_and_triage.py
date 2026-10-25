import pytest
from httpx import AsyncClient

from app.services.ai_service import parse_voice_vitals
from app.services.triage import triage_bp, triage_glucose, triage_pulse


def test_clinical_triage_bp():
    band, msg = triage_bp(120, 80)
    assert band == "normal"

    band, msg = triage_bp(135, 85)
    assert band == "borderline"

    band, msg = triage_bp(185, 110)
    assert band == "critical"
    assert "خطر" in msg or "حرج" in msg


def test_clinical_triage_glucose():
    band, msg = triage_glucose(95, "fasting")
    assert band == "normal"

    band, msg = triage_glucose(125, "fasting")
    assert band == "borderline"

    band, msg = triage_glucose(280, "fasting")
    assert band == "critical"

    band, msg = triage_glucose(130, "post_prandial")
    assert band == "normal"

    band, msg = triage_glucose(170, "post_prandial")
    assert band == "borderline"


def test_clinical_triage_pulse():
    band, msg = triage_pulse(72)
    assert band == "normal"

    band, msg = triage_pulse(105)
    assert band == "borderline"

    band, msg = triage_pulse(45)
    assert band == "critical"


def test_egyptian_arabic_voice_vitals_parsing():
    parsed = parse_voice_vitals("الضغط النهارده مية وخمسة وتلاتين على خمسة وتمانين")
    assert parsed["type"] == "bp"
    assert parsed["value_primary"] == 135.0
    assert parsed["value_secondary"] == 85.0
    assert parsed["band"] == "borderline"

    parsed_glucose = parse_voice_vitals("السكر صايم 105")
    assert parsed_glucose["type"] == "glucose"
    assert parsed_glucose["value_primary"] == 105.0
    assert parsed_glucose["meal_context"] == "fasting"
    assert parsed_glucose["band"] == "normal"


@pytest.mark.asyncio
async def test_vitals_api_endpoints(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201011112222", name="مريض تجريبي")
    patient_id = str(patient.id)
    headers = {"Authorization": f"Bearer {patient.id}"}

    # 1. Parse voice vitals
    voice_res = await client.post(
        "/api/v1/ai/parse-voice-vitals",
        json={"transcript": "الضغط مية وعشرين على تمانين"},
        headers=headers,
    )
    assert voice_res.status_code == 200
    assert voice_res.json()["band"] == "normal"

    # 2. Record vital
    create_res = await client.post(
        f"/api/v1/patients/{patient_id}/vitals",
        json={
            "type": "bp",
            "value_primary": 140.0,
            "value_secondary": 90.0,
            "raw_transcript": "الضغط 140 على 90",
        },
        headers=headers,
    )
    assert create_res.status_code == 201
    assert create_res.json()["band"] == "borderline"

    # 3. List vitals
    list_res = await client.get(f"/api/v1/patients/{patient_id}/vitals", headers=headers)
    assert list_res.status_code == 200
    data = list_res.json()
    assert len(data) == 1
    assert data[0]["value_primary"] == 140.0
