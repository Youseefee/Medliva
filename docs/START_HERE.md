# Medliva — Start Here

## قراءة سريعة للإيجنت

1. اقرأ AGENTS.md.
2. حدّد الجزء المطلوب: apps/mobile أو supabase أو docs.
3. اقرأ الوثيقة المرتبطة بالمهمة فقط؛ لا تبدأ بتحميل كل ملفات docs.
4. افحص الكود والاختبارات قبل اعتبار أي شيء منفّذًا.

## الحالة الحالية

| الجزء | الحالة الفعلية من الكود |
|---|---|
| apps/mobile | تطبيق Flutter للمريض والمرافق. يستخدم Supabase Auth وPostgREST/RPC وStorage وEdge Functions. يشمل الملف الشخصي، الأدوية والجرعات، القياسات، ربط المرافق، الطوارئ، المخزون، التنبيهات، وتقارير PDF ومشاركتها. |
| supabase/migrations | تغييرات PostgreSQL وسياسات RLS ودوال RPC المستخدمة في التطبيق. |
| supabase/functions | دالتا scan-prescription وpublic-report. |
| apps/doctor-portal | البوابة المستقلة خارج MVP؛ الطبيب يتلقى تقرير PDF ينشأ من تطبيق الموبايل. |

## خريطة الملفات المهمة

| لو بتشتغل على | ابدأ من | ثم راجع |
|---|---|---|
| Flutter screen/flow | apps/mobile/lib/features/ | core/router/، lib/l10n/، test/ |
| Auth/security | apps/mobile/lib/features/auth/ | supabase/migrations وdocs/SECURITY.md |
| Medication/adherence | apps/mobile/lib/features/medications/ | migrations الخاصة بالجرعات، docs/API_SPEC.md |
| Supabase database/function | supabase/migrations أو supabase/functions/ | docs/DATABASE.md، docs/API_SPEC.md، docs/SECURITY.md |
| Architecture/data | docs/ARCHITECTURE.md | docs/DATABASE.md، docs/API_SPEC.md |
| Product priority | docs/USE_CASES.md | docs/MASTER_PLAN.md، docs/ROADMAP.md |

## الوثائق حسب نوعها

- مصدر المنتج والأولوية: USE_CASES.md وROADMAP.md.
- عقود Supabase الحالية: API_SPEC.md وDATABASE.md وARCHITECTURE.md.
- قواعد العمل والأمان: CONVENTIONS.md وSECURITY.md.
- docs/original/: مراجع كبيرة، لا تُقرأ في مهام الكود العادية.
- docs/tools/: نواتج ومرفقات وثائقية؛ لا تُفتح إلا لمهمة توثيق.

## قاعدة البحث

ابدأ بأضيق مسار ممكن، واستبعد الملفات المولّدة وبيئات الأدوات. وسّع البحث فقط إذا أثبتت الاختبارات أو imports وجود اعتماد إضافي.
