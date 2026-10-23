# CareElder — Start Here

## قراءة سريعة للإيجنت

1. اقرأ `AGENTS.md`.
2. حدّد الجزء المطلوب: `apps/mobile` أو `services/api` أو `apps/doctor-portal`.
3. اقرأ الوثيقة المرتبطة بالمهمة فقط؛ لا تبدأ بتحميل كل ملفات `docs/`.
4. افحص الكود والاختبارات قبل اعتبار أي شيء “منفّذاً”.

## الحالة الحالية

| الجزء | الحالة الفعلية من الكود |
|---|---|
| `services/api` | FastAPI يعمل ويضم auth/users، caregiver، medications/adherence، vitals، AI، inventory، emergency، reports، وdevices مع اختبارات API. |
| `apps/mobile` | Flutter يضم البنية الأساسية، تسجيل الهاتف/OTP، الجلسة، التوجيه، الترجمة، والشاشة الرئيسية؛ تكامل ميزات الأدوية والمرافق غير ظاهر في الواجهة الحالية بعد. |
| `apps/doctor-portal` | غير منفّذ بعد؛ الموجود README يحدد النطاق المقترح فقط. |
| `docs/` | بعض الملفات مواصفات وخطط مستقبلية، وليست سجل تنفيذ. |

## خريطة الملفات المهمة

| لو بتشتغل على | ابدأ من | ثم راجع |
|---|---|---|
| Backend endpoint | `services/api/app/api/v1/endpoints/` | `schemas/`, `models/`, `tests/`, `docs/API_SPEC.md` |
| Auth/security | `services/api/app/api/v1/endpoints/auth.py` | `core/security.py`, `core/deps.py`, `tests/test_auth.py`, `docs/SECURITY.md` |
| Medication/adherence | `services/api/app/api/v1/endpoints/medications.py` | `adherence.py`, `models/medication.py`, related tests |
| Flutter screen/flow | `apps/mobile/lib/features/` | `core/router/`, `core/network/`, `lib/l10n/`, `test/` |
| Architecture/data | `docs/ARCHITECTURE.md` | `docs/DATABASE.md`, `docs/API_SPEC.md` |
| Product priority | `docs/USE_CASES.md` | `docs/MASTER_PLAN.md`, `docs/ROADMAP.md` |

## الوثائق حسب نوعها

- مصدر المنتج والأولوية: `USE_CASES.md`, `ROADMAP.md`.
- العقود التقنية الحالية: `API_SPEC.md`, `DATABASE.md`, `ARCHITECTURE.md`.
- قواعد العمل والأمان: `CONVENTIONS.md`, `SECURITY.md`.
- `docs/original/`: مراجع أصلية كبيرة، لا تُقرأ في مهام الكود العادية.
- `docs/tools/`: سكربتات توليد مستندات، لا تُفتح إلا لمهمة توثيق.

## قاعدة البحث

استخدم قائمة الملفات المتتبعة أو بحثاً يستبعد البيئة والملفات المولّدة. ابدأ بأضيق مسار ممكن، ثم وسّع البحث فقط إذا أثبتت الاختبارات أو imports وجود اعتماد إضافي.
