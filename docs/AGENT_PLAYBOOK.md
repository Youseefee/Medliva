# Medliva — Agent Playbook (للموديلات المنفِّذة)

> هذا الملف مكتوب لموديل منفِّذ. اتبعه حرفيًا. لا تجتهد خارج النطاق.
> المرجع الوحيد للمهام: `docs/EXECUTION_PLAN.md`. هذا الملف يشرح **طريقة العمل** فقط.

---

## 0) البرومبت الذي يُلصق للموديل في بداية كل جلسة

```
You are working on the Medliva repo (Flutter app in apps/mobile, FastAPI in services/api).
Follow docs/AGENT_PLAYBOOK.md exactly.
Do exactly ONE unchecked task from docs/EXECUTION_PLAN.md (the first "- [ ]" in order), then stop.
Do not refactor, rename, or touch files unrelated to that task.
Do not add dependencies unless the task text names them.
When done: tick the task, add one Progress log row, report changed files + test results.
If anything is ambiguous or a check fails 3 times, STOP and ask me — do not guess.
```

---

## 1) الخطوات الثابتة لكل جلسة (Loop)

1. **حالة الريبو:** شغّل `git status --short`. لا تحذف ولا تعدّل أي تغيير موجود لا يخص مهمتك.
2. **اختيار المهمة:** افتح `docs/EXECUTION_PLAN.md`، خذ **أول** سطر `- [ ]` فقط. اقرأ نصه كاملًا، خصوصًا جملة *Done when*.
3. **اقرأ قبل أن تكتب:** افتح كل ملف مذكور في نص المهمة، وملف الاختبار المجاور له، وملف واحد مشابه موجود كنموذج للأسلوب (مثال أدناه). لا تفتح `docs/original/` أو `.venv` أو `build/`.
4. **خطة قصيرة:** اكتب لنفسك 3–6 نقاط: الملفات التي ستعدّلها وما ستضيفه في كل منها.
5. **نفّذ بأصغر تغيير ممكن.** قلّد أسلوب الكود الموجود (نفس أنماط Riverpod/Repository/Router في الموبايل، ونفس أنماط endpoints/schemas/tests في الـ API).
6. **اختبر المهمة أولًا** ثم الفحص الكامل (الأوامر في القسم 3).
7. **لو فشل اختبار:** اقرأ رسالة الخطأ كاملة، أصلح السبب لا العرض. بحد أقصى 3 محاولات ثم توقّف واسأل.
8. **التوثيق:** غيّر `- [ ]` إلى `- [x]` للمهمة، وأضف صفًا في جدول `## Progress log` بنفس الصيغة:
   `| YYYY-MM-DD | P13.1 | ماذا أضفت (ملفات) ; ruff/pytest أو analyze/test passed (عدد الاختبارات). |`
   لو غيّرت API → حدّث `docs/API_SPEC.md`.
9. **التقرير النهائي للمستخدم:** قائمة الملفات المعدّلة + أوامر الفحص ونتيجتها. **لا تعمل commit** إلا في P16.1 وبعد موافقة المستخدم.

---

## 2) قواعد ممنوع كسرها

- مهمة واحدة فقط في الجلسة.
- الـ API: route + schema + model + migration + test لازم يكونوا متطابقين. أي endpoint لمريض يستخدم `check_patient_access` ويُختبر بـ 200 و 403.
- الموبايل: أي نص ظاهر للمستخدم يُضاف في `lib/l10n/app_ar.arb` **و** `app_en.arb` ثم `flutter gen-l10n` (أو `flutter pub get`).
- إمكانية الوصول لكبار السن: خط ≥ 18sp، أزرار كبيرة، `Semantics` للأزرار الأيقونية، `EdgeInsetsDirectional` (دعم RTL)، الحالة لا تعتمد على اللون وحده (أيقونة + نص + لون).
- كل زر يُختبر في الاختبارات يأخذ `Key('...')` بالاسم المذكور في المهمة (مثل `reminder_take_btn`).
- الاختبارات لا تتصل بالشبكة: استخدم fake/override للـ Repository عبر Riverpod `ProviderScope(overrides: [...])`، وفي Python استخدم `monkeypatch` أو `httpx.MockTransport`.
- لا تعتبر `MASTER_PLAN.md` أو `ROADMAP.md` دليلًا على وجود ميزة؛ الكود هو المرجع.

---

## 3) الأوامر

| المكان | فحص سريع للمهمة | فحص كامل |
|---|---|---|
| `services/api` | `uv run pytest tests/test_xxx.py -q` | `uv run ruff check . ; uv run pytest -q` |
| `apps/mobile` | `flutter test test/features/xxx/yyy_test.dart` | `flutter analyze ; flutter test` |

(PowerShell: استخدم `;` بدل `&&` لو ظهر خطأ.)
إصلاح lint تلقائي: `uv run ruff check . --fix` ، `dart fix --apply`.

---

## 4) دليل تنفيذ المهام المتبقية (تلميحات لكل مهمة)

### P12.1 — ربط التذكيرات المحلية
- الملفات: `features/medications/data/medication_reminder_planner.dart`، `features/medications/presentation/screens/today_screen.dart`.
- أضف `final localReminderServiceProvider = Provider<LocalReminderService>((ref) => LocalReminderService());`.
- في تحميل الجرعات: `await ref.read(localReminderServiceProvider).rescheduleForToday(doses)` داخل `try/catch` (حتى لا يفشل في الاختبارات).
- في `logDose`: لو الحالة `taken` أو `skipped` → `cancelScheduleReminders(dose.scheduleId)`.
- الاختبار: Fake يرث/ينفّذ `LocalReminderService` ويسجّل الاستدعاءات، override للـ provider، ثم تأكد أن `cancelScheduleReminders` استُدعي.

### P13.1 — Endpoint التنبيهات
- `emergency.py`: `GET /patients/{patient_id}/alerts` → `check_patient_access` ثم select `Alert` where patient_id order by `created_at desc` limit 50.
- `schemas/emergency.py`: `AlertOut` (id, type, message/payload, created_at…) بنفس حقول الموديل الموجود فعلًا — افتح `models/emergency.py` أولًا.
- اختبارات: 200 للمريض/المرافق المرتبط، 403 لمستخدم غريب، وأضف المسار لقائمة المسارات في `test_security_access.py`.
- حدّث `docs/API_SPEC.md`.

### P13.2 — شاشة الإشعارات بالبيانات الحقيقية
- أضف دالة `fetchAlerts(patientId)` في Repository موجود (Emergency) بدل إنشاء طبقة جديدة.
- FutureProvider + `when(loading/error/data)`؛ لو القائمة فارغة اعرض البطاقات الحالية.
- الاختبار: override للـ provider ببيانات وهمية، اضغط كل Chip (`all`, `medications`, `caregivers`, `alerts`) وتحقق من العناصر الظاهرة.

### P14.1 / P14.2 — اختبارات الشاشات
- لا تعدّل كود الشاشة إلا لإضافة `Key` ناقص.
- استخدم Fake repository يسجّل الاستدعاءات (مثلًا `loggedStatus == 'taken'`، `triggerSosCalled == true`).
- للتنقل/الـ pop: لفّ الشاشة في `MaterialApp` مع Navigator واختبر أن الشاشة اختفت بعد `pumpAndSettle()`.
- مرّر `localizationsDelegates` و `supportedLocales` و `locale: Locale('ar')` مثل الاختبارات الموجودة في `test/features/`.

### P15.1 — Gemini Vision اختياري
- لا تضف مكتبة Google؛ استخدم `httpx.AsyncClient` (موجود).
- الشكل: `if settings.gemini_api_key and image: try: call → parse JSON → fuzzy match (difflib.get_close_matches) except Exception: fallback` → `scan_prescription_mock`.
- timeout ≈ 20s. لا تطبع المفتاح في اللوج.
- الاختبار: `monkeypatch` للدالة التي تستدعي HTTP لترجع JSON وهمي، واختبار ثانٍ بدون مفتاح يتأكد من مسار الـ mock.

### P15.2 — سكربت بيانات العرض
- `services/api/scripts/seed_demo_data.py` بدالة `async def seed(session, patient_id: UUID | None = None)` + `if __name__ == "__main__":`.
- Idempotent: افحص الوجود قبل الإضافة (by name / by date).
- اختبار pytest يستدعي `seed` مرتين على SQLite ويتأكد أن العدد لم يتضاعف.
- وثّق `uv run python -m scripts.seed_demo_data <patient_uuid>` في `README.md`.

### P16.1 — الإصدار النهائي
- شغّل الفحوصات الأربعة كاملة. حدّث `START_HERE.md` و `ROADMAP.md`.
- **اسأل المستخدم قبل الـ commit.** رسالة الـ commit تنتهي بـ:
  `Co-Authored-By: <اسم الموديل> <noreply@...>`

---

## 5) متى تتوقف وتسأل

- المهمة تذكر ملفًا/دالة غير موجودة.
- الاختبار يحتاج تغيير سلوك في كود خارج نطاق المهمة.
- تحتاج dependency غير مذكورة.
- فشل نفس الفحص 3 مرات.
- اختبارات قديمة (غير مرتبطة بمهمتك) كانت فاشلة قبل أن تبدأ → أبلغ ولا تصلحها بنفسك.

## 6) قالب التقرير النهائي

```
Task: P13.1 — <title>
Changed:
- services/api/app/api/v1/endpoints/emergency.py — added GET /patients/{id}/alerts
- ...
Checks:
- uv run ruff check . → OK
- uv run pytest → 23 passed
Notes/blocked: <none | ...>
```
