# 🩺 Medliva — منصة الرعاية الصحية والالتزام الدوائي الذكية

> **مشروع تخرج متكامل:** منصة رقمية مخصصة لكبار السن ومرافقيهم لإدارة الالتزام الدوائي، والفرز الطبي الفوري، ومراقبة المؤشرات الحيوية بالصوت، ومسح الروشتات بالذكاء الاصطناعي، ومنظومة استغاثة طارئة، واستخراج تقارير الأطباء.

---

## ⚡ معمارية التشغيل السحابي المباشر (Cloud-First & Zero Docker)

تم بناء المنصة بالكامل لتعمل على **سحابة Supabase المباشرة (Supabase Auth + PostgreSQL 16)** مع تشغيل الخادم الخلفي عبر أداة `uv` الحديثة، **دون الحاجة لأي حاويات Docker محلياً**:

- **قاعدة البيانات والمصادقة:** سحابة [Supabase](https://supabase.com) المباشرة المشفرة باتصال TLS وسياسات أمان RLS.
- **الواجهة الخلفية (Backend):** خادم FastAPI غير متزامن بلغة Python 3.12 يُدار بالكامل عبر `uv`.
- **التطبيق الذكي (Mobile/Web):** تطبيق Flutter يدعم واجهات كبار السن المزدوجة (المريض / المرافق) ويعمل بنمط Offline-First الصارم.

---

## 📚 وثائق المشروع الرسمية

| المستند | المحتوى والغرض |
|---|---|
| [docs/START_HERE.md](docs/START_HERE.md) | ⭐ الدليل المرجعي السريع وحالة التنفيذ الفعلية من واقع الكود |
| [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) | وثيقة الخطة الشاملة والهيكلية العامة للمنصة |
| [docs/ROADMAP.md](docs/ROADMAP.md) | خارطة الطريق والمراحل السبرنتية ومصفوفة الإنجاز |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | المعمارية الهندسية، نمط أوفلاين، ومخططات التسلسل UML |
| [docs/DATABASE.md](docs/DATABASE.md) | هيكل قاعدة بيانات PostgreSQL والعلاقات وجداول Supabase |
| [docs/API_SPEC.md](docs/API_SPEC.md) | التوثيق التفصيلي لمسارات REST API ونماذج الطلبات والاستجابة |
| [docs/AI_PIPELINE.md](docs/AI_PIPELINE.md) | طبقة الذكاء الاصطناعي (Gemini Vision OCR + الفرز الطبي الصوتي) |
| [docs/SECURITY.md](docs/SECURITY.md) | تدابير أمان البيانات الطبية والتحقق الصارم من صلاحيات المريض |
| [docs/CONVENTIONS.md](docs/CONVENTIONS.md) | معايير صياغة الكود وضوابط الجودة والمزامنة |
| [docs/tools/](docs/tools/) | أدوات توليد التقارير ومخرجات التوثيق الأكاديمي الشامل |

---

## 🧱 هيكل المستودع البرمجي

```
apps/mobile          تطبيق Flutter الشامل (المريض + المرافق + توليد تقرير الطبيب PDF)
services/api         خادم FastAPI المكتمل (المصادقة، الأدوية، القياسات، الفرز، المخزون، الطوارئ)
services/api/scripts سكربت زرع بيانات العرض التجريبي على Supabase (seed_demo_data.py)
infra/               ملفات البيئة والإعداد (.env.example)
docs/                المستندات الهندسية ومخططات المشروع
docs/tools/          أدوات إنشاء المستندات والتقارير الأكاديمية (ReportLab PDF)
```

---

## 🚀 التشغيل السريع الموحد على Windows (بنقرة واحدة)

لتشغيل السيرفر وتطبيق الويب معاً بضغطة زر واحدة بدون كتابة أوامر:
```powershell
.\run.ps1
# أو بالضغط المزدوج على ملف run.bat
```
سيفتح لك التطبيق على المتصفح عبر `http://localhost:5000` وخادم الـ API عبر `http://localhost:8000/docs`.

---

## 🛠️ التشغيل اليدوي خطوة بخطوة (Direct Supabase)

### 1. إعداد متغيرات الاتصال بسحابة Supabase
انسخ ملف الإعداد وضع بيانات مشروع Supabase الخاص بك في `infra/.env`:
```bash
cp infra/.env.example infra/.env
```
المتغيرات الأساسية المطلوبة:
```env
SUPABASE_URL=https://bapyzkwbkkyilgueaftc.supabase.co
SUPABASE_ANON_KEY=sb_publishable_ar58W5ioZ8ClN-IdcYMe9Q_mQW9CQWU
DATABASE_URL=postgresql+asyncpg://postgres:PASSWORD@db.bapyzkwbkkyilgueaftc.supabase.co:5432/postgres
```

### 2. تشغيل الواجهة الخلفية (Backend API)
```bash
cd services/api

# تثبيت الاعتماديات عبر uv
uv sync

# تطبيق ترقيات وهيكل الجداول على قاعدة بيانات Supabase
uv run alembic upgrade head

# بدء تشغيل السيرفر
uv run uvicorn app.main:app --reload --port 8000
```
- لوحة Swagger التفاعلية: `http://localhost:8000/docs`
- فحص الحالة والاتصال بقاعدة البيانات: `http://localhost:8000/health`

### 3. تشغيل تطبيق الموبايل والويب (Flutter)
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## 🎯 دليل يوم المناقشة والعرض الحي (Live Demo Runbook مع Supabase)

خصصنا هذا الدليل لمساعدتك على تقديم أفضل تجربة عرض حي أمام لجنة المناقشة والتحكيم:

### المرحلة 1: تشغيل السيرفر السحابي
تأكد من تشغيل خادم FastAPI في نافذة موجه الأوامر:
```bash
cd services/api
uv run uvicorn app.main:app --reload --port 8000
```

### المرحلة 2: زرع بيانات المريض التجريبية بضغطة زر على Supabase
حتى تظهر شاشات التطبيق مليئة ببيانات واقعية ونسب التزام ورسوم بيانية دون الحاجة لقضاء ساعات في التسجيل اليدوي:

```bash
# الخيار 1 (الأسهل والأسرع): ربط وزرع البيانات تلقائياً بأول مريض مسجل في قاعدة البيانات
uv run python scripts/seed_demo_data.py --auto-patient

# الخيار 2: زرع البيانات بحساب بريد إلكتروني مسجل مسبقاً في التطبيق
uv run python scripts/seed_demo_data.py --patient-email patient@medliva.app

# الخيار 3: زرع البيانات بمعرف الـ UUID الخاص بالمريض في Supabase
uv run python scripts/seed_demo_data.py --patient-id <PATIENT_UUID>
```

> **البيانات التي تُزرع فورياً:** كتالوج الأدوية المصري (10 أدوية) + 3 أدوية نشطة بـ 5 مواعيد يومية + 35 سجل التزام دوائي لأسبوع كامل + 14 قياساً حيوياً للضغط والسكر مع تصنيف الفرز الطبي + 3 تنبيهات حرجة في مركز الإشعارات.

### المرحلة 3: تشغيل التطبيق وتمرير الروابط عبر `--dart-define`

اختر البيئة المفضلة لديك للعرض التقديمي:

#### أ. العرض على المتصفح (Web Presentation):
```bash
cd apps/mobile
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=SUPABASE_URL=https://bapyzkwbkkyilgueaftc.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_ar58W5ioZ8ClN-IdcYMe9Q_mQW9CQWU
```

#### ب. العرض على محاكي أندرويد (Android Emulator):
```bash
cd apps/mobile
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=SUPABASE_URL=https://bapyzkwbkkyilgueaftc.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_ar58W5ioZ8ClN-IdcYMe9Q_mQW9CQWU
```

#### ج. العرض على هاتف حقيقي (Physical Device عبر Wi-Fi):
```bash
cd apps/mobile
# استبدل 192.168.1.50 بعنوان IP الخاص بجهازك على شبكة الواي فاي المحلية
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1 \
  --dart-define=SUPABASE_URL=https://bapyzkwbkkyilgueaftc.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_ar58W5ioZ8ClN-IdcYMe9Q_mQW9CQWU
```

### 🎬 سيناريو العرض المقترح أمام اللجنة (5 دقائق):
1. **تسجيل الدخول كمريض:** استعراض شاشة "جرعات اليوم" بأزرارها الضخمة وبطاقاتها الواضحة لكبار السن.
2. **تأكيد تناول دواء:** الضغط على زر "أخذته"؛ يلاحظ الحضور تحول الجرعة للون الأخضر وخصم رصيد المخزون فورياً.
3. **الإدخال الصوتي للقياسات:** نطق قراءة قياس باللهجة المصرية "الضغط 135 على 85" وتأكيد بطاقة الفرز الطبي (طبيعي / حدّي / حرج).
4. **استغاثة الطوارئ SOS:** استعراض زر الاستغاثة المحمي بالضغط المطول مع التقاط الموقع الجغرافي GPS.
5. **التبديل لواجهة المرافق (Caregiver):** استعراض لوحة المتابعة وكروت المرضى ونسب الالتزام الدوائي وتنبيهات الجرعات الفائتة.
6. **تقرير الطبيب المعتمد:** فتح شاشة تقرير الطبيب داخل التطبيق وتوليد ملف PDF احترافي فوري بخطوط عربية جاهز للطباعة والمشاركة.

---

## 🧪 التحقق ومؤشرات الجودة وضمان الاستقرار

تم اختبار المنصة بنسبة 100% بكافة طبقاتها:
- **الواجهة الخلفية (Backend):** 34 اختباراً آلياً بـ Pytest تغطي المصادقة، والأدوية، والفرز، ومحاكاة البيانات، وحظر الصلاحيات 403.
- **تطبيق الموبايل (Flutter):** 49 اختباراً للوحدات والـ Widgets والتوجيه ومعالجة انتهاء الجلسات بدون أي أخطاء.
- **إمكانية الوصول (Accessibility):** فحص كامل لمطابقة معايير إمكانية الوصول لكبار السن (WCAG) بأحجام لمس 48dp ونصوص 18sp.
