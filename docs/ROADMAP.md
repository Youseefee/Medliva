# خارطة الطريق (16 أسبوع · 8 سبرنتات × أسبوعين)

| Sprint | الأسابيع | الهدف | أهم المهام | معيار القبول |
|---|---|---|---|---|
| S1 | 1–2 | التحليل والتصميم | SRS، UML، Personas، Wireframes، Figma Design System | موافقة المشرف على SRS + Figma |
| S2 | 3–4 | الأساسات | Monorepo، ربط Supabase + Upstash، Alembic schema، OTP/JWT، CI، Flutter skeleton + Theme + l10n | تسجيل دخول end-to-end |
| S3 | 5–6 | ⭐ الأدوية والمنبه | CRUD أدوية/مواعيد، Drift، Native alarm + Full-Screen + Boot receiver، TTS | المنبه يرن Offline وبعد Restart |
| S4 | 7–8 | المرافق والتصعيد | Pairing، Sync batch، WebSocket، FCM، Celery watcher، سلّم التصعيد، Voice notes | تنبيه للمرافق خلال 30 د من عدم التأكيد |
| S5 | 9–10 | AI-1: الروشتة | Drug catalog، Gemini OCR، بطاقة التأكيد، Dataset + تقييم | دقة ≥ 85% |
| S6 | 11–12 | AI-2: الصوت + المخزون | Whisper، Parser عامي، Triage، Inventory forecast، WhatsApp، Expiry | دقة القياسات ≥ 95% |
| S7 | 13–14 | التقارير + SOS + الأمان | PDF عربي، QR + Doctor portal، SOS + Twilio، Rate limit، Audit | الطبيب يفتح التقرير من QR |
| S8 | 15–16 | الاختبار والتسليم | E2E، Pilot مع 5 عائلات، SUS، Bug bash، Deploy، كتاب + Demo | جاهز للمناقشة |

## Milestones
- **M1 (أسبوع 4):** Foundation demo.
- **M2 (أسبوع 8):** MVP — منبه + مرافق + تصعيد.
- **M3 (أسبوع 12):** Feature complete — AI + مخزون.
- **M4 (أسبوع 16):** Release + مناقشة.

## Checklist عام
- [ ] SRS + UML
- [ ] Figma
- [ ] Backend foundation
- [ ] Mobile foundation
- [ ] Alarm engine
- [ ] Caregiver sync + escalation
- [ ] Prescription OCR
- [ ] Voice vitals + triage
- [ ] Inventory
- [ ] Reports + Doctor portal
- [ ] SOS
- [ ] Testing + Pilot
- [ ] Deployment + Book + Demo
