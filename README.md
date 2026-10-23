# 🩺 CareElder

تطبيق ذكي لرعاية كبار السن — مشروع تخرج.
تذكير صارم بالأدوية · مسح الروشتات بالـ AI · تسجيل القياسات بالصوت · متابعة لحظية للأهل · مخزون الأدوية · تقارير للطبيب · زر استغاثة.

## 📚 التوثيق
| الملف | المحتوى |
|---|---|
| [docs/START_HERE.md](docs/START_HERE.md) | ⭐ خريطة البداية للإيجنت وحالة التنفيذ الفعلية |
| [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) | ⭐ الخطة الشاملة (ابدأ من هنا) |
| [docs/USE_CASES.md](docs/USE_CASES.md) | حالات الاستخدام بالتفصيل |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | المعمارية و Offline-First و Sequence diagrams |
| [docs/DATABASE.md](docs/DATABASE.md) | قاعدة البيانات |
| [docs/API_SPEC.md](docs/API_SPEC.md) | الـ API |
| [docs/AI_PIPELINE.md](docs/AI_PIPELINE.md) | طبقة الذكاء الاصطناعي |
| [docs/ROADMAP.md](docs/ROADMAP.md) | المراحل والسبرنتات |
| [docs/CONVENTIONS.md](docs/CONVENTIONS.md) | قواعد الكود و Git |
| [docs/SECURITY.md](docs/SECURITY.md) | الأمان والخصوصية |
| [docs/original/](docs/original/) | ملفات التوثيق الأصلية (HTML/PDF) |

## 🧱 الهيكل
```
apps/mobile          Flutter (المريض + المرافق)
apps/doctor-portal   Next.js (بوابة الطبيب)
services/api         FastAPI (modular monolith)
infra/               ملفات الإعداد والبيئة (.env) وبدائل التشغيل
docs/                التوثيق
```

## 🚀 التشغيل والإعداد السحابي (بدون دوكر)
يعتمد المشروع على خدمات سحابية مجانية وسريعة بدون الحاجة لتثبيت Docker محلياً:
- **قاعدة البيانات والتخزين:** [Supabase](https://supabase.com) (PostgreSQL 16 + Storage للروشتات والصوتيات).
- **المهام المجدولة:** Supabase Cron / Edge Functions، مع Redis اختياري فقط عند الحاجة لاحقاً.

```bash
# 1. إعداد المتغيرات
cp infra/.env.example infra/.env   # وضع روابط Supabase وبيانات البيئة

# 2. تشغيل الـ Backend
cd services/api
uv sync
alembic upgrade head
uvicorn app.main:app --reload
```
*(ملاحظة: ملف `infra/docker-compose.yml` متاح كبديل اختياري لمن يفضل تشغيل الحاويات محلياً).*
