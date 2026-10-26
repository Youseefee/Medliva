# ⚙️ Medliva API (FastAPI)

الواجهة الخلفية (Backend API) لمنصة **Medliva** لإدارة الرعاية الصحية والالتزام الدوائي لكبار السن.

> **ملاحظة معمارية هامة:** يعتمد المشروع كلياً على **سحابة Supabase المباشرة (PostgreSQL 16 + Supabase Auth)** وتشغيل FastAPI عبر أداة `uv` الحديثة. المسار الأساسي لا يحتاج Docker؛ ويوجد بديل محلي اختياري فقط في `infra/docker-compose.yml`.

---

## 🏗️ البنية البرمجية المنفذة

```
app/
├── main.py                  # تطبيق FastAPI + Lifespan + CORS + إدارة الأخطاء + /health
├── api/v1/
│   ├── endpoints/
│   │   ├── users.py         # الملف الشخصي GET/PATCH /me
│   │   ├── medications.py   # إدارة الأدوية والجداول ومطابقة الكتالوج
│   │   ├── adherence.py     # تسجيل تناول/تخطي الجرعات وطابور المزامنة أوفلاين
│   │   ├── vitals.py        # تسجيل القياسات الحيوية والفرز الطبي ومخططات الاتجاهات
│   │   ├── ai.py            # مسح الروشتة بـ Gemini Vision + الإدخال الصوتي
│   │   ├── caregiver.py     # كود الاقتران السداسي ولوحة متابعة المرضى
│   │   ├── inventory.py     # رصيد المخزون، توقع النفاد، وإعادة الطلب عبر واتساب
│   │   ├── emergency.py     # زر SOS مع إحداثيات GPS وجهات اتصال الطوارئ
│   │   ├── reports.py       # توليد تقرير الطبيب التفاعلي وروابط المشاركة
│   │   └── devices.py       # إدارة الأجهزة المقترنة
│   └── router.py            # مجمّع مسارات API v1
├── core/
│   ├── config.py            # إعدادات Pydantic Settings المربوطة بسحابة Supabase
│   ├── deps.py              # التحقق الصارم من رموز Supabase Auth وصلاحيات الوصول
│   └── errors.py            # نموذج معالجة وتغليف الأخطاء القياسي
├── db/
│   ├── base.py              # النماذج الأساسية والمعرفات UUID والتواريخ
│   └── session.py           # محرك SQLAlchemy Async المتصل بسحابة Supabase عبر TLS
├── models/                  # نماذج الجداول المتوافقة مع قاعدة Supabase
├── schemas/                 # مخططات Pydantic للتحقق من المدخلات والمخرجات
└── services/                # خدمات الفرز الطبي، معالجة الصوت، والتصعيد
alembic/                     # ترقيات ومخططات قاعدة البيانات الموجهة لـ Supabase
scripts/
└── seed_demo_data.py        # سكربت زرع بيانات المحاكاة والعرض الحي
tests/                       # اختبارات Pytest الآلية الشاملة (تُعاد الأرقام من مخرجات التشغيل الفعلية)
```

---

## 🚀 الإعداد والتشغيل السحابي المباشر (بدون Docker)

### 1. إعداد متغيرات البيئة (`infra/.env`)

أنشئ أو افتح ملف `infra/.env` وضمنه بيانات مشروع Supabase الخاص بك:

```env
ENV=dev
CORS_ORIGINS=["http://localhost:3000","http://localhost:5000","*"]

# --- Supabase Auth ---
SUPABASE_URL=https://YOUR_SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
# أو SUPABASE_ANON_KEY (كلاهما مدعوم تلقائياً)
SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY

# --- Supabase PostgreSQL Database ---
# رابط الاتصال المباشر (أو Transaction/Session Pooler من لوحة تحكم Supabase > Connect):
DATABASE_URL=postgresql+asyncpg://postgres:YOUR_PASSWORD@db.bapyzkwbkkyilgueaftc.supabase.co:5432/postgres

# --- AI Layer (اختياري لتحليل صور الروشتات الفعلي) ---
GEMINI_API_KEY=your_gemini_api_key_here
```

### 2. تثبيت الحزم وتشغيل الترحيلات

من مسار `services/api`:

```bash
# تثبيت الاعتماديات بسرعة فائقة عبر uv
uv sync

# تطبيق هيكل الجداول مباشرة على سحابة Supabase
uv run alembic upgrade head
```

### 3. تشغيل خادم التطوير

```bash
uv run uvicorn app.main:app --reload --port 8000
```

- **توثيق التفاعلي (Swagger UI):** `http://localhost:8000/docs`
- **فحص صحة السيرفر وقاعدة البيانات:** `http://localhost:8000/health`

### 4. التحقق واختبارات الجودة

```bash
# فحص وتنسيق الكود
uv run ruff check .

# تشغيل حزمة الاختبارات الآلية الشاملة
uv run pytest
```

---

## 🎯 دليل يوم المناقشة والعرض الحي (Live Demo Runbook مع Supabase)

لتقديم عرض عملي متكامل أمام لجنة التحكيم والمناقشة دون أي تعقيد، اتبع الخطوات المرتبة التالية:

### الخطوة 1: تشغيل السيرفر المربوط بـ Supabase
تأكد من تشغيل الخادم الخلفي في نافذة موجه الأوامر:
```bash
cd services/api
uv run uvicorn app.main:app --reload --port 8000
```
تأكد من ظهور: `Application startup complete` ونجاح الاتصال بسحابة Supabase.

---

### الخطوة 2: زرع بيانات المحاكاة السريرية على Supabase
يوفر سكربت `scripts/seed_demo_data.py` آليات مرنة وسريعة لزرع كتالوج الأدوية وسجل مريض تجريبي كامل على قاعدة Supabase بضغطة زر واحدة وهو **آمن التكرار بنسبة 100% (Idempotent)**:

```bash
# الخيار أ: زرع كتالوج الأدوية وربط البيانات فورياً بأول مريض مسجل في قاعدة البيانات
uv run python scripts/seed_demo_data.py --auto-patient

# الخيار ب: زرع البيانات لمريض محدد بواسطة بريده الإلكتروني في Supabase
uv run python scripts/seed_demo_data.py --patient-email patient@medliva.app

# الخيار ج: زرع البيانات لمريض عبر معرّف UUID الخاص به
uv run python scripts/seed_demo_data.py --patient-id <PATIENT_UUID>

# الخيار د: زرع كتالوج الأدوية المصري فقط (10 أدوية معتمدة)
uv run python scripts/seed_demo_data.py
```

**ما يتم زرعه تلقائياً على Supabase:**
1. **كتالوج الأدوية (`drug_catalog`):** 10 أدوية مصرية شائعة للضغط والسكر والقلب والمضادات الحيوية.
2. **أدوية وجداول المريض (`medications` + `schedules`):** 3 أدوية رئيسية (Concor 5mg, Glucophage 500mg, Augmentin 1g) موزعة على 5 مواعيد يومية دقيقة.
3. **سجل الالتزام (`intake_logs`):** 35 سجلاً يغطي 7 أيام كاملة يجمع بين الجرعات المتناولة والمتخطاة والفائتة لإظهار دقة نسب الالتزام.
4. **القياسات الحيوية والفرز الطبي (`vitals_logs`):** 14 قياساً واقعياً لضغط الدم والسكر تشمل قراءات طبيعية، وحدية، وحرجة لإبراز محرك الفرز Triage ومخططات الاتجاهات.
5. **تغذية التنبيهات (`alerts`):** 3 تنبيهات حرجة (جرعة فائتة، قياس حرج، وتنبيه مخزون منخفض) لتشغيل شاشة مركز الإشعارات للمريض والمرافق فورياً.

---

### الخطوة 3: تمرير المتغيرات لتطبيق Flutter عبر `--dart-define`

عند تشغيل تطبيق Flutter للهواتف أو المتصفح، مرر روابط Supabase والـ API مباشرة عبر معلمات `--dart-define`:

#### أ. للتشغيل على الويب (Web Browser):
```bash
cd apps/mobile
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=SUPABASE_URL=https://YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

#### ب. للتشغيل على محاكي أندرويد (Android Emulator):
> يستخدم محاكي أندرويد المعرف المضيف `10.0.2.2` للوصول إلى `localhost` الخاص بالحاسوب:
```bash
cd apps/mobile
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=SUPABASE_URL=https://YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

#### ج. للتشغيل على هاتف حقيقي (Physical Device عبر Wi-Fi):
> استبدل `192.168.1.X` بـ IP حاسوبك المحلي على نفس شبكة الواي فاي:
```bash
cd apps/mobile
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1 \
  --dart-define=SUPABASE_URL=https://YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

---

## 🧠 مسح الروشتات بالذكاء الاصطناعي (Gemini Vision)

عند توفر مفتاح `GEMINI_API_KEY` في `infra/.env`:
- يقوم مسار `POST /api/v1/ai/scan-prescription` بتحليل صورة الروشتة عبر نموذج **Gemini 2.5 Flash Vision**.
- تُجرى مطابقة تقريبية (Fuzzy Matching) مع جدول `drug_catalog` المعتمد لمنع اختلاق أي أسماء أدوية خيالية.
- في حال عدم توفر المفتاح، يقوم النظام بالتحليل النصي البديل الآمن دون اختلاق أي بيانات.
