"""Optional Gemini Vision OCR used to read prescriptions from a photo.

The feature is entirely optional: when no API key is configured, or when the
call fails, the caller falls back to the text based extraction. The module
never raises: a failure simply means "no vision result".
"""

import base64
import json
import re
from typing import Any

import httpx

GEMINI_VISION_ENDPOINT = (
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
)

VISION_PROMPT = (
    "You extract medication data from a photo of a prescription or a medicine "
    "box. Return ONLY a JSON array where every item has the keys: "
    '"drug_trade_name" (string), "dosage_mg" (number or null), '
    '"frequency_per_day" (integer), "meal_relation" (one of after_meal, '
    'before_meal, with_meal, independent), "times" (array of "HH:MM" strings), '
    '"inventory_pills" (integer) and "active_ingredient" (string or null). '
    "Return an empty array when the image contains no medication."
)

# Magic bytes of the image formats we accept.
IMAGE_SIGNATURES: tuple[bytes, ...] = (
    b"\xff\xd8\xff",  # jpeg
    b"\x89PNG\r\n\x1a\n",  # png
    b"GIF8",  # gif
    b"RIFF",  # webp
)


def looks_like_image(data: bytes) -> bool:
    """Whether the payload looks like a real image instead of plain text."""
    if not data:
        return False
    return any(data.startswith(signature) for signature in IMAGE_SIGNATURES)


def guess_mime_type(data: bytes) -> str:
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data.startswith(b"GIF8"):
        return "image/gif"
    if data.startswith(b"RIFF"):
        return "image/webp"
    return "image/jpeg"


def extract_json_array(raw_text: str) -> list[dict[str, Any]]:
    """Pull a JSON array out of a model answer (tolerates markdown fences)."""
    cleaned = raw_text.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```[a-zA-Z]*\n?", "", cleaned)
        cleaned = re.sub(r"\n?```$", "", cleaned).strip()

    start = cleaned.find("[")
    end = cleaned.rfind("]")
    if start != -1 and end != -1 and end > start:
        try:
            parsed = json.loads(cleaned[start : end + 1])
            if isinstance(parsed, list):
                return [item for item in parsed if isinstance(item, dict)]
        except json.JSONDecodeError:
            pass

    # Tolerates single object responses: { "drug_trade_name": "..." }
    start_obj = cleaned.find("{")
    end_obj = cleaned.rfind("}")
    if start_obj != -1 and end_obj != -1 and end_obj > start_obj:
        try:
            parsed_obj = json.loads(cleaned[start_obj : end_obj + 1])
            if isinstance(parsed_obj, dict) and "drug_trade_name" in parsed_obj:
                return [parsed_obj]
        except json.JSONDecodeError:
            pass

    return []


async def extract_medications_from_image(
    image_bytes: bytes,
    api_key: str,
    *,
    request_timeout: float = 25.0,
) -> list[dict[str, Any]] | None:
    """Return the medications found in the image, or None when not available."""
    if not api_key or not image_bytes:
        return None

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": VISION_PROMPT},
                    {
                        "inline_data": {
                            "mime_type": guess_mime_type(image_bytes),
                            "data": base64.b64encode(image_bytes).decode("ascii"),
                        }
                    },
                ]
            }
        ]
    }

    try:
        async with httpx.AsyncClient(timeout=request_timeout) as client:
            response = await client.post(
                f"{GEMINI_VISION_ENDPOINT}?key={api_key}",
                json=payload,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            data = response.json()
    except (httpx.HTTPError, ValueError):
        return None

    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        return None

    return extract_json_array(text)
