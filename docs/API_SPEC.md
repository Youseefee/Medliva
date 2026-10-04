# مواصفات الـ API (v1)

- Base: `/api/v1` · JSON · Auth: `Authorization: Bearer <JWT>`
- Errors: `{ "error": { "code": "STRING", "message": "..." } }`
- Swagger تلقائي على `/docs`.

| Method | Endpoint | الصلاحية | الوصف |
|---|---|---|---|
| POST | `/auth/otp/request` | Public | `{phone}` |
| POST | `/auth/otp/verify` | Public | `{phone, code}` → `{access, refresh, user}` |
| POST | `/auth/refresh` | Public | |
| GET/PATCH | `/me` | Auth | |
| POST | `/caregiver/pairing-code` | Patient | توليد كود 6 أرقام (10 د) |
| POST | `/caregiver/pair` | Caregiver | `{code}` |
| GET | `/caregiver/patients` | Caregiver | |
| GET/POST | `/patients/{id}/medications` | Linked | |
| PATCH/DELETE | `/medications/{id}` | Linked | |
| GET/POST | `/medications/{id}/schedules` | Linked | |
| GET | `/patients/{id}/today` | Linked | جرعات اليوم وحالتها |
| POST | `/adherence/log` | Patient | خصم مخزون + بث WS |
| POST | `/sync/batch` | Patient | `{items:[{client_uuid, entity, op, payload}]}` |
| POST | `/ai/scan-prescription` | Auth | multipart image |
| POST | `/ai/parse-voice-vitals` | Patient | multipart audio |
| GET/POST | `/patients/{id}/vitals` | Linked | فلترة `type, from, to` |
| GET | `/patients/{id}/inventory/forecast` | Linked | |
| POST | `/patients/{id}/inventory/refill-order` | Caregiver | يرجّع نص + رابط `wa.me` |
| POST | `/patients/{id}/voice-notes` | Caregiver | |
| GET | `/patients/{id}/reports/pdf?days=30` | Linked | |
| POST | `/patients/{id}/reports/share` | Linked | → `{url, qr_png, expires_at}` |
| GET | `/public/reports/{token}` | Token | بوابة الطبيب |
| POST | `/emergency/sos` | Patient | `{lat, lng}` |
| POST | `/devices` | Auth | تسجيل FCM token |
| WS | `/ws/patients/{id}` | Linked | events: `intake`, `vital`, `alert` |

## أمثلة
**POST /adherence/log**
```json
{ "client_uuid": "6f1c...", "schedule_id": "…", "scheduled_time": "2026-10-04T05:30:00Z",
  "actual_time": "2026-10-04T05:34:12Z", "status": "taken" }
```
**POST /ai/scan-prescription → 200**
```json
{ "medications": [ { "drug_trade_name": "Glucophage", "dosage_mg": 500, "frequency_per_day": 2,
  "meal_relation": "after_meals", "times": ["08:30","20:30"], "inventory_pills": 60,
  "confidence_score": 0.96, "catalog_match_id": "…" } ] }
```
**POST /ai/parse-voice-vitals → 200**
```json
{ "transcript": "الضغط النهارده 135 على 85", "type": "bp",
  "value_primary": 135, "value_secondary": 85, "band": "borderline",
  "message_ar": "الضغط مرتفع شوية، قلل الملح" }
```
