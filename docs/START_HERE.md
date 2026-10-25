# Medliva — Start Here

## قراءة سريعة للإيجنت

1. اقرأ `AGENTS.md`.
2. حدّد الجزء المطلوب: `apps/mobile` أو `services/api` أو `apps/doctor-portal`.
3. اقرأ الوثيقة المرتبطة بالمهمة فقط؛ لا تبدأ بتحميل كل ملفات `docs/`.
4. افحص الكود والاختبارات قبل اعتبار أي شيء “منفّذاً”.

## الحالة الحالية

| الجزء | الحالة الفعلية من الكود |
|---|---|
| `services/api` | FastAPI يتحقق من جلسات Supabase Auth ويزامن ملف المستخدم، ويضم caregiver (بما في ذلك تصعيد الجرعات الفائتة بعد 15 دقيقة)، medications/adherence، vitals، AI (قراءة صورة الروشتة عبر Gemini Vision اختيارياً مع بديل نصي، بدون اختلاق أي دواء)، inventory، emergency (SOS + جهات الاتصال + `GET /patients/{id}/alerts`)، reports (ملخص تقرير الطبيب + رابط مشاركة + PDF بخط عربي)، وdevices. |
| `apps/mobile` | تطبيق Flutter يستخدم البريد وكلمة المرور عبر Supabase Auth، بلا دخول بالهاتف أو SMS/OTP. يشمل التوجيه حسب الدور (`/patient` و`/caregiver`)، الملف الشخصي واللغة، الأدوية وجرعات اليوم والتنبيهات المحلية (مربوطة فعلياً بجرعات اليوم) وطابور عدم الاتصال، ربط المرافق ولوحة المتابعة، القياسات الحيوية والإدخال الصوتي، مسح الروشتة، الطوارئ وزر SOS، المخزون وإعادة الطلب، مركز الإشعارات المبني على تغذية التنبيهات الحقيقية، وتقرير الطبيب PDF داخل التطبيق. |
| `apps/doctor-portal` | استُبدلت البوابة المستقلة في الـ MVP بميزة توليد ومشاركة تقرير الطبيب بصيغة PDF مباشرة داخل تطبيق الموبايل (`DoctorReportScreen`). |
| `docs/` | محدّثة ومتزامنة مع التنفيذ الفعلي (`API_SPEC.md` و`EXECUTION_PLAN.md`). |
| `scripts/` | `services/api/scripts/seed_demo_data.py` يزرع بيانات عرض قابلة للتكرار (كتالوج الأدوية + سجل مريض تجريبي). |

## خريطة الملفات المهمة

| لو بتشتغل على | ابدأ من | ثم راجع |
|---|---|---|
| Backend endpoint | `services/api/app/api/v1/endpoints/` | `schemas/`, `models/`, `tests/`, `docs/API_SPEC.md` |
| Auth/security | `apps/mobile/lib/features/auth/` | `services/api/app/core/deps.py`, `tests/test_auth.py`, `docs/SECURITY.md` |
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
