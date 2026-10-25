import pytest
from httpx import AsyncClient

from app.services.gemini_vision import extract_json_array, looks_like_image


@pytest.mark.asyncio
async def test_scan_prescription_without_api_key_uses_the_text_fallback(
    client: AsyncClient, user_factory
):
    patient = await user_factory(phone="+201011100011", name="مريض الوصفة")
    headers = {"Authorization": f"Bearer {patient.id}"}

    files = {
        "file": (
            "prescription.txt",
            b"Concor 5mg\nGlucophage 500mg",
            "text/plain",
        )
    }
    res = await client.post("/api/v1/ai/scan-prescription", headers=headers, files=files)
    assert res.status_code == 200

    data = res.json()
    assert data["source"] == "text"
    names = {m["drug_trade_name"] for m in data["medications"]}
    assert names == {"Concor 5mg", "Glucophage 500mg"}
    assert data["confidence"] > 0.5


@pytest.mark.asyncio
async def test_scan_prescription_with_an_image_and_no_api_key_does_not_invent_medications(
    client: AsyncClient, user_factory
):
    patient = await user_factory(phone="+201011100022", name="مريض صورة")
    headers = {"Authorization": f"Bearer {patient.id}"}

    files = {"file": ("rx.jpg", b"\xff\xd8\xff\xe0not-a-real-jpeg", "image/jpeg")}
    res = await client.post("/api/v1/ai/scan-prescription", headers=headers, files=files)
    assert res.status_code == 200

    data = res.json()
    assert data["source"] == "text"
    assert data["medications"] == []
    assert data["confidence"] == 0.0


@pytest.mark.asyncio
async def test_scan_prescription_uses_gemini_vision_when_available(
    client: AsyncClient, user_factory, monkeypatch: pytest.MonkeyPatch
):
    from app.api.v1.endpoints import ai as ai_endpoint

    async def fake_vision(image_bytes: bytes, api_key: str, **kwargs):
        assert image_bytes.startswith(b"\xff\xd8\xff")
        assert api_key == "test-gemini-key"
        return [
            {
                "drug_trade_name": "Concor 5mg",
                "dosage_mg": 5,
                "frequency_per_day": 1,
                "meal_relation": "before_meal",
                "times": ["08:00"],
                "inventory_pills": 30,
                "confidence_score": 0.93,
                "active_ingredient": "Bisoprolol",
            }
        ]

    monkeypatch.setattr(ai_endpoint, "extract_medications_from_image", fake_vision)
    monkeypatch.setattr(ai_endpoint, "get_settings", lambda: _settings_with_gemini_key())

    patient = await user_factory(phone="+201011100033", name="مريض تحليل")
    headers = {"Authorization": f"Bearer {patient.id}"}

    files = {"file": ("rx.jpg", b"\xff\xd8\xff\xe0not-a-real-jpeg", "image/jpeg")}
    res = await client.post("/api/v1/ai/scan-prescription", headers=headers, files=files)
    assert res.status_code == 200

    data = res.json()
    assert data["source"] == "gemini_vision"
    assert len(data["medications"]) == 1
    assert data["medications"][0]["drug_trade_name"] == "Concor 5mg"
    assert data["medications"][0]["times"] == ["08:00"]
    assert data["confidence"] > 0.5


@pytest.mark.asyncio
async def test_scan_prescription_falls_back_when_gemini_fails(
    client: AsyncClient, user_factory, monkeypatch: pytest.MonkeyPatch
):
    from app.api.v1.endpoints import ai as ai_endpoint

    async def failing_vision(image_bytes: bytes, api_key: str, **kwargs):
        return None

    monkeypatch.setattr(ai_endpoint, "extract_medications_from_image", failing_vision)
    monkeypatch.setattr(ai_endpoint, "get_settings", lambda: _settings_with_gemini_key())

    patient = await user_factory(phone="+201011100044", name="مريض فشل")
    headers = {"Authorization": f"Bearer {patient.id}"}

    files = {"file": ("rx.jpg", b"\xff\xd8\xff\xe0not-a-real-jpeg", "image/jpeg")}
    res = await client.post("/api/v1/ai/scan-prescription", headers=headers, files=files)
    assert res.status_code == 200
    assert res.json()["source"] == "text"
    assert res.json()["medications"] == []


def test_looks_like_image_detects_real_images_only():
    assert looks_like_image(b"\xff\xd8\xff\xe0jpeg") is True
    assert looks_like_image(b"\x89PNG\r\n\x1a\n") is True
    assert looks_like_image(b"Concor 5mg") is False
    assert looks_like_image(b"") is False


def test_extract_json_array_handles_markdown_fences():
    raw = '```json\n[{"drug_trade_name": "Concor 5mg"}]\n```'
    assert extract_json_array(raw) == [{"drug_trade_name": "Concor 5mg"}]
    assert extract_json_array("no json here") == []
    assert extract_json_array("[1, 2]") == []


class _Settings:
    gemini_api_key = "test-gemini-key"


def _settings_with_gemini_key() -> _Settings:
    return _Settings()
