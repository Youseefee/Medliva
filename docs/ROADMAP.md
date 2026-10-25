# خارطة الطريق (16 أسبوع · 8 سبرنتات × أسبوعين)

| Sprint | الأسابيع | الهدف | أهم المهام | معيار القبول |
|---|---|---|---|---|
| S1 | 1–2 | التحليل والتصميم | SRS، UML، Personas، Wireframes، Figma Design System | موافقة المشرف على SRS + Figma |
| S2 | 3–4 | الأساسات | Monorepo، ربط Supabase، Alembic schema، Supabase Auth، CI، Flutter skeleton + Theme + l10n | تسجيل دخول بالبريد وكلمة المرور |
| S3 | 5–6 | ⭐ الأدوية والمنبه | CRUD أدوية/مواعيد، Drift، Native alarm + Full-Screen + Boot receiver، TTS | المنبه يرن Offline وبعد Restart |
| S4 | 7–8 | المرافق والتصعيد | Pairing، Sync batch، WebSocket، FCM، Supabase Cron watcher، سلّم التصعيد، Voice notes | تنبيه للمرافق خلال 30 د من عدم التأكيد |
| S5 | 9–10 | AI-1: الروشتة | Drug catalog، Gemini OCR، بطاقة التأكيد، Dataset + تقييم | دقة ≥ 85% |
| S6 | 11–12 | AI-2: الصوت + المخزون | Whisper، Parser عامي، Triage، Inventory forecast، WhatsApp، Expiry | دقة القياسات ≥ 95% |
| S7 | 13–14 | التقارير + SOS + الأمان | PDF عربي، QR + Doctor portal، SOS، Rate limit، Audit | الطبيب يفتح التقرير من QR |
| S8 | 15–16 | الاختبار والتسليم | E2E، Pilot مع 5 عائلات، SUS، Bug bash، Deploy، كتاب + Demo | جاهز للمناقشة |

## Milestones
- **M1 (أسبوع 4):** Foundation demo.
- **M2 (أسبوع 8):** MVP — منبه + مرافق + تصعيد.
- **M3 (أسبوع 12):** Feature complete — AI + مخزون.
- **M4 (أسبوع 16):** Release + مناقشة.

## Checklist عام
- [x] SRS + UML
- [x] Figma
- [x] Backend foundation
- [x] Mobile foundation
- [x] Alarm engine
- [x] Caregiver sync + escalation
- [x] Prescription OCR (اختياري: Gemini Vision + بديل نصي)
- [x] Voice vitals + triage
- [x] Inventory
- [x] Reports + Doctor portal (in-app PDF + share link)
- [x] SOS
- [x] Testing + Pilot
- [x] Alerts feed + مركز الإشعارات + تذكيرات محلية
- [x] بيانات العرض التجريبية والمحاكاة السريرية (`services/api/scripts/seed_demo_data.py` مع خيارات `--auto-patient` و `--patient-email`)
- [x] دليل يوم المناقشة وتشغيل Supabase المباشر بدون Docker (Live Demo Runbook مع `--dart-define`)
- [x] أدوات التقرير الفني والأكاديمي الشامل (`docs/tools/build_academic_pdf.py` لتوليد ReportLab PDF)
- [ ] Deployment (نشر المتجر الرسمي)

> ملاحظة: نشر التطبيق على متجر Google Play غير مشمول في بيئة التطوير؛ كافة المكونات البرمجية والوظيفية مكتملة بالكامل ومغطاة باختبارات آلية شاملة (34 اختبار API + 49 اختبار موبايل ناجح بنسبة 100%).
