# ⚙️ Medliva API (FastAPI)

خادم الـ Backend لمشروع **Medliva**.

## 🏗️ الهيكل المنفذ (Sprint 2)
```
app/
├── main.py                  # FastAPI app + Lifespan + CORS + Error Handling + /health
├── api/v1/
│   ├── endpoints/
│   │   └── users.py         # GET/PATCH /me
│   └── router.py            # مجمع الـ Endpoints
├── core/
│   ├── config.py            # إعدادات Pydantic Settings (Supabase / Upstash)
│   ├── deps.py              # Supabase Auth token validation & RBAC
│   ├── errors.py            # Standardized Error Envelope
├── db/
│   ├── base.py              # Base & IdTimestampMixin (UUID PK + Timestamps)
│   └── session.py           # Async SQLAlchemy Engine & Sessions
├── models/
│   └── user.py              # User profile linked to Supabase Auth
└── schemas/
    └── user.py              # Pydantic Schemas للمستخدم
alembic/                     # مصفوفة Migrations (متوافقة مع Async + Supabase)
tests/                       # اختبارات الـ Unit و Integration بالـ Pytest
```

## 🚀 التشغيل المحلي

### الاتصال بقاعدة Supabase

أنشئ أو افتح `infra/.env`، وضع فيه `DATABASE_URL` و`SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY` من إعدادات مشروع Supabase. ملف `.env` المحلي متجاهل في Git. يستخدم الـ API اتصال PostgreSQL مع TLS ويتحقق من جلسات التطبيق عبر Supabase Auth.

طبّق مخطط قاعدة البيانات من مجلد `services/api`:

```bash
uv run alembic upgrade head
```

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

## 🌱 بيانات العرض (Demo Seed)

سكربت `scripts/seed_demo_data.py` يزرع بيانات جاهزة للعرض التقديمي، وهو **آمن التكرار**: تشغيله مرة أخرى لا يكرر أي صف، بل يحدّث الموجود.

```bash
# 1. زرع كتالوج الأدوية المصري فقط
uv run python scripts/seed_demo_data.py

# 2. زرع كتالوج الأدوية + سجل دواء وقياسات 7 أيام لpatient تجريبي
#    (المريض يجب أن يكون موجوداً مسبقاً في قاعدة البيانات)
uv run python scripts/seed_demo_data.py --patient-id <UUID>

# 3. تحديد عدد الأيام (الافتراضي 7)
uv run python scripts/seed_demo_data.py --patient-id <UUID> --days 14
```

السكربت يزرع:
- `drug_catalog`: كل أدوية `COMMON_EGYPTIAN_DRUGS` (10 أدوية).
- `medications` + `schedules`: Concor 5mg، Glucophage 500mg، Augmentin 1g (5 مواعيد يومياً).
- `vitals_logs`: 7 أيام من ضغط الدم والسكر مع تصنيف triage.
- `intake_logs`: سجل التزام لـ 7 أيام (مأخوذ / متخطى / فائت).

## 🧠 تحليل صور الوصفات (اختياري)

لو ضُبط `GEMINI_API_KEY` في `infra/.env`، فإن `POST /api/v1/ai/scan-prescription` يقرأ صورة الوصفة عبر Gemini Vision ويستخرج الأدوية منها. بدون المفتاح (أو عند فشل الطلب) يرجع النظام تلقائياً للتحليل النصي بدون أي بيانات مُختلَقة.

```bash
GEMINI_API_KEY=your-key
```
