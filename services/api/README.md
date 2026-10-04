# ⚙️ CareElder API (FastAPI)

خادم الـ Backend لمشروع **CareElder**.

## 🏗️ الهيكل المنفذ (Sprint 2)
```
app/
├── main.py                  # FastAPI app + Lifespan + CORS + Error Handling + /health
├── api/v1/
│   ├── endpoints/
│   │   ├── auth.py          # /auth/otp/request, /auth/otp/verify, /auth/refresh
│   │   └── users.py         # GET/PATCH /me
│   └── router.py            # مجمع الـ Endpoints
├── core/
│   ├── config.py            # إعدادات Pydantic Settings (Supabase / Upstash)
│   ├── deps.py              # Auth & RBAC Dependencies
│   ├── errors.py            # Standardized Error Envelope
│   ├── phone.py             # التحقق وضبط صيغة أرقام الموبايل المصرية
│   └── security.py          # HMAC-SHA256 OTP hashing & JWT (Access + Refresh)
├── db/
│   ├── base.py              # Base & IdTimestampMixin (UUID PK + Timestamps)
│   └── session.py           # Async SQLAlchemy Engine & Sessions
├── models/
│   └── user.py              # Users & OtpChallenges (SQLAlchemy 2.0)
└── schemas/
    ├── auth.py              # Pydantic Schemas للتحقق والـ Tokens
    └── user.py              # Pydantic Schemas للمستخدم
alembic/                     # مصفوفة Migrations (متوافقة مع Async + Supabase)
tests/                       # اختبارات الـ Unit و Integration بالـ Pytest
```

## 🚀 التشغيل المحلي

```bash
# 1. تثبيت الاعتماديات
uv sync

# 2. تشغيل الاختبارات وفحص الكود
uv run ruff check .
uv run pytest

# 3. تشغيل السيرفر
uv run uvicorn app.main:app --reload --port 8000
```
- Swagger Docs متاحة على: `http://localhost:8000/docs`
- فحص الصحة: `http://localhost:8000/health`
