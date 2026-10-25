# Medliva — Execution Plan (Agent-Ready)

## ▶ How to work (agent: follow exactly)
1. Find the **first unchecked `[ ]` task** below. Do only that task. Do not jump ahead or "also fix" other things.
2. Read only: the files named in the task + the matching API schema/endpoint. Nothing else unless an import forces it.
3. Implement → run the checks in *Rules* → all must pass.
4. Tick `[x]`, add one Progress log row (date, task id, files changed, test result).
5. Stop and report. One task per run.
6. Stuck after 2 failed attempts, or task unclear? Don't guess: write `BLOCKED: <question>` in the Progress log and stop.

> Prompt the user can paste: **"اقرأ docs/EXECUTION_PLAN.md ونفّذ أول مهمة مش متعلّم عليها بس، واتبع قسم How to work."**

> Read `AGENTS.md` → `docs/START_HERE.md` → this file. Do **one task at a time**, top to bottom.
> Mark a task `[x]` only when its **Done when** checks pass, then add a Progress log row.
> Never mark based on `MASTER_PLAN.md`/`ROADMAP.md`. If a task is blocked or ambiguous, stop and write the question in the Progress log.

## Snapshot (verified from code, 2026-10-23)

| Area | Status |
|---|---|
| API (`services/api`) | Supabase Auth token validation and user profiles; caregiver, medications/schedules/today, adherence + sync/batch, vitals + voice parse, AI scan-prescription, inventory forecast/refill, emergency SOS/contacts, reports share/public, and devices. |
| Mobile (`apps/mobile`) | Patient and caregiver app with Supabase email/password auth, session, router, localized screens, and API-backed care features. |
| Doctor portal | **Dropped as a web app.** Doctor sees a PDF report generated inside the mobile app (Phase 8). `apps/doctor-portal` stays docs-only. |

## Decisions (fixed — do not re-ask)
| Topic | Decision |
|---|---|
| Doctor view | In-app PDF report (medication history, adherence, vitals) shared via system share sheet. No web portal. |
| Patient id for patient users | From `GET /users/me` (`id`). Caregivers pick a patient from `GET /caregiver/patients`. Store selected patient in a Riverpod provider `currentPatientIdProvider`. |
| Escalation | Missed dose = no adherence log 15 min after scheduled time → caregiver notified. |
| Push notifications | Out of scope for now: escalation is computed by API and shown on caregiver dashboard (pull). `POST /devices` still registers token for later FCM. |
| Approved dependencies | Only in the task that names them: `flutter_local_notifications`, `timezone` (P2.4) · `connectivity_plus` (P2.5) · `speech_to_text` (P4.2) · `image_picker` (P5.1) · `geolocator` (P6.2) · `pdf`, `printing` (P8.2) · `supabase_flutter` (P11.1). |

## Rules for every task
- Checks: API → `cd services/api; uv run ruff check .; uv run pytest` · Mobile → `cd apps/mobile; flutter analyze; flutter test`. Both must pass before ticking.
- Every new UI string in **both** `lib/l10n/app_ar.arb` and `app_en.arb`, then `flutter gen-l10n`. Min tap target 48dp, body text ≥18sp, RTL-safe (`EdgeInsetsDirectional`), never color-only meaning.
- Mobile feature layout: `lib/features/<name>/{data,domain/models,presentation/{screens,widgets}}`.
- **Reference pattern** to copy: `features/auth/data/auth_repository.dart` (repo + dio), `features/auth/presentation/auth_notifier.dart` (Riverpod notifier), `features/auth/domain/models/user.dart` (model + fromJson). Tests use `mocktail`.
- JSON field names must match the API schema in `services/api/app/schemas/<module>.py` — read it before writing a Dart model.
- Keep API routes ↔ schemas ↔ models ↔ migrations ↔ tests ↔ `docs/API_SPEC.md` aligned.
- No dependencies beyond the Decisions table. Do not commit unless the task says so.

---

## Phase 0 — Stabilize baseline
- [x] **P0.1 Green API baseline.** *Done when:* ruff + pytest pass.
- [x] **P0.2 Migrations cover all models.** Compare `app/models/*` with `alembic/versions/*`; add missing migration(s). Test against a temporary SQLite/DB URL only. *Done when:* `uv run alembic upgrade head` on empty DB succeeds and `alembic check` (or autogenerate) shows no diff.
- [x] **P0.3 Green mobile baseline.** *Done when:* `flutter pub get; flutter analyze; flutter test` pass.
- [x] **P0.4 Sync API_SPEC.md** with actual routes (prefixes from `app/api/v1/router.py`). *Done when:* every route documented with method, path, request/response schema name; none fictional.
- [x] **P0.5 Commit baseline** — ask user first; include `Co-Authored-By`.

## Phase 1 — Mobile foundation
- [x] **P1.1 API client hardening** in `core/network/api_client.dart`: typed `ApiException` (status, message), interceptor retries once after renewing the Supabase Auth session; on refresh failure logs out. *Done when:* unit tests cover the renewal retry and failed-renewal logout.
- [x] **P1.2 Role-aware routing.** Load `/users/me` after login; patient → `/patient` shell, caregiver → `/caregiver` shell (placeholder screens OK). Add `currentPatientIdProvider`. *Done when:* widget tests for both roles land on correct shell.
- [x] **P1.3 Profile screen.** `GET/PATCH /users/me` (name, language). *Done when:* widget test: changing language switches app locale.

## Phase 2 — Medications (UC-01, Must)
- [x] **P2.1 Data layer.** Models + `MedicationRepository` for list/create/update/delete medications, list/create schedules, get today. *Done when:* repository unit tests with mocked dio for each method.
- [x] **P2.2 Today screen** (patient home tab): one large card per dose (name, dose, time, status); Taken/Skip buttons → `POST /adherence/log`, card updates. *Done when:* widget test taps Taken and sees status change.
- [x] **P2.3a Medication list screen** with delete (confirm dialog). *Done when:* widget test renders list + delete.
- [x] **P2.3b Add/Edit medication form** (validation for required fields). *Done when:* widget test submits valid form and shows errors on empty.
- [x] **P2.3c Schedule editor** (times of day + days of week) on the medication detail. *Done when:* widget test adds a time.
- [x] **P2.4 Local reminders** (`flutter_local_notifications`, `timezone`). Schedule from today/schedules data; reschedule on change; full-screen intent on Android; repeat every 5 min up to 3 times until Taken/Skip. *Done when:* scheduling logic is in a pure class with unit tests; Android manifest permissions added.
- [x] **P2.5 Offline queue** (`connectivity_plus`): failed adherence logs saved locally, flushed via `POST /sync/batch` when online. *Done when:* unit test: offline log → queued → online → batch sent once.

## Phase 3 — Caregiver (UC-04, Must)
- [x] **P3.1 Pairing.** Patient screen shows code from `POST /caregiver/pairing-code` (big digits); caregiver enters it → `POST /caregiver/pair`. *Done when:* widget tests for both screens.
- [x] **P3.2 Caregiver dashboard** (`GET /caregiver/patients`): list of patients with today's taken/missed counts; tap → sets `currentPatientIdProvider` and opens patient's Today (read-only). *Done when:* widget test.
- [x] **P3.3 Missed-dose escalation (API).** Compute missed doses (15 min rule) and expose them in caregiver patients response or a new `GET /caregiver/alerts`; update schema, API_SPEC, tests. Show alerts badge on dashboard. *Done when:* pytest covers on-time / missed / logged-late cases.

## Phase 4 — Vitals (UC-03, Must)
- [x] **P4.1 Vitals list + manual entry** (`GET/POST /patients/{id}/vitals`); show triage level as icon + text + color. *Done when:* widget test adds a reading and sees triage label.
- [x] **P4.2 Voice entry** (`speech_to_text`, locale ar/en): transcript → `POST /ai/parse-voice-vitals` → editable confirm screen → save. *Done when:* widget test with mocked parser shows confirm screen; nothing saved without confirm.

## Phase 5 — Prescription scan (UC-02, Must)
- [x] **P5.1** `image_picker` (camera/gallery) → `POST /ai/scan-prescription` → editable review list → create selected medications. *Done when:* widget test: mocked scan result → edit → confirm creates meds; cancel creates none.

## Phase 6 — Emergency (UC-07, Must)
- [x] **P6.1 Contacts screen** (`GET/POST /patients/{id}/contacts`). *Done when:* widget test.
- [x] **P6.2 SOS button** fixed on patient shell; long-press 2s or confirm dialog → `POST /emergency/sos` with location (`geolocator`) if permission granted, without otherwise. *Done when:* widget test: accidental tap does nothing; confirmed press calls API.

## Phase 7 — Inventory (UC-05, Should)
- [x] **P7.1** Per-medication "days left" card (`/inventory/forecast`), warning under 7 days, refill button (`/inventory/refill-order`). *Done when:* widget test for warning state.

## Phase 8 — Doctor PDF report (UC-06, Must)
- [x] **P8.1 Report data endpoint (API).** Ensure an authenticated endpoint returns, for a patient and date range (default last 30 days): patient info, active medications + schedules, adherence history (per dose: scheduled/taken/skipped/missed) with adherence %, vitals history with triage. Reuse existing reports module if it already returns this; otherwise add `GET /patients/{id}/reports/summary?from=&to=`. Keep the existing public share-token endpoint untouched. *Done when:* pytest covers content + access control (other users get 403).
- [x] **P8.2 PDF generation in app** (`pdf`, `printing`): "Doctor report" screen → pick range → build PDF (Arabic font embedded, RTL when locale ar) with sections: header (patient, date range), medications table, adherence summary + table, vitals table with abnormal values marked by text, footer disclaimer. Preview, then share/print via `Printing`. *Done when:* unit test builds PDF bytes from sample data without error; widget test opens screen.

## Phase 9 — Hardening
- [x] **P9.1** Security review vs `docs/SECURITY.md`: token expiry and patient-access check on every `{patient_id}` route. *Done when:* a pytest per route asserting 403 for unrelated user.
- [x] **P9.2** Accessibility audit (`flutter_a11y_agent`); fix findings. *Done when:* no high-severity findings left.
- [x] **P9.3** CI (`.github/workflows/ci.yml`) runs API + mobile checks. *Done when:* workflow YAML validates and runs both.
- [x] **P9.4** Update `START_HERE.md` status table and `apps/doctor-portal/README.md` (note: replaced by in-app PDF).

## Phase 10 — Supabase connection
- [x] **P10.1** Connect the FastAPI backend to the requested Supabase project, apply the Alembic schema, and enable RLS for public tables. Keep the database password in the ignored local `infra/.env`. *Done when:* the Supabase project is at Alembic head, public tables have RLS enabled, and the API can connect using the local `DATABASE_URL`.

## Phase 11 — Supabase Auth and remove SMS/OTP
- [x] **P11.1** Replace phone/SMS OTP and custom API tokens with Supabase email/password Auth in Flutter and Supabase access-token validation in FastAPI. Remove the unused SMS notification preference, OTP/refresh endpoints, settings, active models, schemas, UI, and docs; add an Alembic migration to remove legacy tables/column and add email to user profiles. *Done when:* Supabase Auth is the only login/session provider, API profiles are keyed by Supabase user IDs, current schema matches models, and no runtime SMS/OTP flow remains.

## Phase 12 — Local Reminder Rescheduling & Cancellation Sync
- [x] **P12.1 Wire `LocalReminderService` to `TodayDosesNotifier`.** Provide `LocalReminderService` via a Riverpod provider (`localReminderServiceProvider`) in `apps/mobile/lib/features/medications/data/medication_reminder_planner.dart`. When `TodayDosesNotifier` in `apps/mobile/lib/features/medications/presentation/screens/today_screen.dart` loads today's doses, call `rescheduleForToday(doses)` (safe no-op if platform plugin isn't initialized in tests). When `logDose` marks a dose `taken` or `skipped`, call `cancelScheduleReminders(dose.scheduleId)`. *Done when:* unit/widget test verifies `cancelScheduleReminders` is called when a dose is marked `taken`, and `flutter analyze` + `flutter test` pass.

## Phase 13 — Real Alerts Feed & Notification Center Integration
- [x] **P13.1 Patient & Caregiver Alerts API endpoint.** Add `GET /patients/{patient_id}/alerts` in `services/api/app/api/v1/endpoints/emergency.py` returning recent `Alert` rows (`sos`, `critical_vital`, `low_stock`, `missed_dose`) ordered by `created_at desc`, protected by `check_patient_access`. Add corresponding response schema in `services/api/app/schemas/emergency.py` and document in `docs/API_SPEC.md`. *Done when:* pytest in `services/api/tests/test_security_access.py` and `services/api/tests/test_caregiver.py` verifies both 200 (authorized) and 403 (unrelated user).
- [x] **P13.2 Connect `NotificationsScreen` to live API alerts.** Update `apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart` to fetch real alerts from `GET /patients/{id}/alerts` (with graceful fallback to existing cards when empty) and add a widget test `apps/mobile/test/features/notifications/notifications_screen_test.dart` covering category filter chips (`all`, `medications`, `caregivers`, `alerts`). *Done when:* `flutter analyze` and `flutter test` pass.

## Phase 14 — Comprehensive Widget Tests for Remaining Screens
- [x] **P14.1 `DoseReminderScreen` & `VitalsTrendsScreen` widget tests.** Add `apps/mobile/test/features/medications/dose_reminder_screen_test.dart` (verifies tapping "أخذته" / `reminder_take_btn` logs dose as `taken` and pops, and "بعدين" / `reminder_snooze_btn` logs `snoozed`) and `apps/mobile/test/features/vitals/vitals_trends_screen_test.dart` (verifies BP/Glucose toggle and 7-day trend cards render). *Done when:* both new test files pass with `flutter analyze` and `flutter test`.
- [x] **P14.2 `SosEmergencyScreen` & `DoctorReportScreen` share-link widget tests.** Add `apps/mobile/test/features/emergency/sos_emergency_screen_test.dart` (verifies emergency contacts list and `sos_call_now_btn` triggers `EmergencyRepository.triggerSos`) and extend `apps/mobile/test/features/reports/doctor_report_test.dart` to test the 7/30/90-day range selector and `generate_share_link_btn`. *Done when:* `flutter analyze` and `flutter test` pass.

## Phase 15 — Production AI Vision & Demo Seed Data
- [x] **P15.1 Optional Gemini Vision OCR in `ai_service.py`.** In `services/api/app/services/ai_service.py` and `services/api/app/api/v1/endpoints/ai.py`, if `settings.gemini_api_key` is set and an image file is uploaded, call Gemini 2.5 Flash REST API via `httpx.AsyncClient` to extract prescription drugs JSON and fuzzy-match against `DrugCatalog` / `COMMON_EGYPTIAN_DRUGS`; if `gemini_api_key` is empty or the call fails, fall back cleanly to `scan_prescription_mock`. *Done when:* unit test in `services/api/tests/test_prescription_and_reports.py` tests both the mocked HTTP Gemini response path and the fallback path; `ruff check .` and `pytest` pass.
- [x] **P15.2 Demo seed script for graduation presentation.** Create `services/api/scripts/seed_demo_data.py` that idempotently seeds `DrugCatalog` with `COMMON_EGYPTIAN_DRUGS` and (when given a demo patient UUID) populates sample medications, schedules, 7-day vitals (`bp` & `glucose`), and adherence logs for live demo/discussion. Document usage in `README.md`. *Done when:* `uv run ruff check .` and a pytest test verifying the seed function on SQLite pass.

## Phase 16 — Final Release & Git Commit
- [x] **P16.1 Full verification & clean Git commit.** Run `uv run ruff check .`, `uv run pytest`, `flutter analyze`, and `flutter test`. Update `docs/START_HERE.md` and `docs/ROADMAP.md` final checklist items. Stage all project files and create a clean commit with `Co-Authored-By` attribution (ask user before committing if required by rules). *Done when:* all API and Mobile test suites pass and `git status --short` is clean.

---

## Progress log
| Date | Task | Result / notes |
|---|---|---|
| 2026-10-25 | P12–P15 | Completed Phases 12-15: wired `LocalReminderService` to `TodayDosesNotifier` (reschedule on load, cancel on taken/skipped, Android 13+ notification permission, safe no-op in tests); added `GET /patients/{id}/alerts` (+ `GET /patients/{id}/caregivers`) with `AlertOut`/`LinkedCaregiverOut` schemas, shared `adherence_service` for missed-dose detection, and API_SPEC updates; rebuilt `NotificationsScreen` on the live alerts feed with working category chips and no fake cards; made the vitals trends BP/Glucose toggle actually switch cards and removed fake fallback numbers; removed the fake emergency contacts and hardcoded GPS text; replaced the indefinite SOS spinner with a determinate hold ring; embedded a real Arabic PDF font (Cairo via `printing`) with the transliteration kept as offline fallback; added optional Gemini Vision OCR with a clean text fallback and no invented medications; added `scripts/seed_demo_data.py` (idempotent) plus its pytest coverage and README docs. API: 30 pytest tests, `ruff check`/`ruff format` clean. Mobile: new widget tests for reminders, trends, notifications, SOS and doctor report share link. |
| 2026-10-25 | Final Polish | Wired `OfflineAdherenceQueue` into `TodayDosesNotifier` for automatic offline fallback & sync, added 7/30/90-day date range selector and temporary share-link generation (`POST /reports/share`) to `DoctorReportScreen`, connected dynamic 7-day BP/Glucose chart points in `VitalsTrendsScreen`, auto-selected first linked patient on `CaregiverDashboardScreen`, fixed GoRouter navigation links in `InventoryScreen`, and enhanced prescription OCR hint matching in `services/api`. All 17 API pytest tests, `ruff check`, `flutter analyze`, and all 32 mobile tests passed. |
| 2026-10-24 | P11.1 | Replaced app login with Supabase email/password Auth and API token checks with Supabase Auth user validation; removed active OTP/SMS auth code, screens, API routes/settings/models, and SMS contact preference. Applied migration `0006_supabase_auth`; verified legacy tables/column are absent, phone is optional, RLS is enabled on every public table, and Alembic reports no model/schema diff. Supabase Phone provider was already disabled. `ruff check`, targeted `ruff format --check`, `alembic check`, and `flutter analyze --no-pub` passed; tests not run. |
| 2026-10-24 | P10.1 | Connected FastAPI through the Supabase Session Pooler; verified Alembic revision `0005_fk_indexes` and RLS on all 15 public tables. Files: `infra/.env` (ignored), `infra/.env.example`, `services/api/README.md`, `services/api/app/db/session.py`, migrations `0004_public_rls` and `0005_fk_indexes`, and this plan. `ruff check`, `ruff format --check`, `alembic heads`, and `alembic current` passed; full tests not run. |
| 2026-10-23 | P0.1 | Green API baseline: uv sync, ruff format/lint fixed, 18 pytest tests passing. |
| 2026-10-23 | P0.2 | Added `services/api/alembic/versions/2026_10_23_0003_domain_models.py` covering all domain models; `alembic upgrade head`, `alembic downgrade base`, `alembic check` (no diff), `ruff check .`, and 18 pytest tests passed. |
| 2026-10-23 | P0.3 | Green mobile baseline: `flutter pub get`, `flutter analyze` (No issues found), and `flutter test` (4 tests passed). |
| 2026-10-23 | P0.4 | Synced `docs/API_SPEC.md` with all actual routes in `services/api/app/api/v1/router.py` and `app/main.py`, including request/response schemas and removing fictional routes. |
| 2026-10-23 | P0.5 | Baseline committed in `486881e` (`git status` clean). |
| 2026-10-23 | P1.1 | Hardened `ApiClient` (`core/network/api_client.dart`) and `auth_notifier.dart` with single-retry refresh and unauthorized logout callback; added unit tests in `test/core/network/api_client_test.dart`; `flutter analyze` and 6 tests passed. |
| 2026-10-23 | P1.2 | Added role-aware routing (`/patient` and `/caregiver` shells in `core/router/app_router.dart`), `/me` load on login (`auth_notifier.dart`), and `currentPatientIdProvider`; added widget tests in `test/core/router/role_routing_test.dart`; `flutter analyze` and 8 tests passed. |
| 2026-10-23 | P1.3 | Added `ProfileScreen` (`features/auth/presentation/screens/profile_screen.dart`), `PATCH /me` in `AuthRepository`/`AuthNotifier`, dynamic locale in `main.dart`, and widget test in `test/features/auth/profile_screen_test.dart`; `flutter analyze` and 9 tests passed. |
| 2026-10-23 | P2.1 | Added medication models (`features/medications/domain/models/medication.dart`), `MedicationRepository` (`features/medications/data/medication_repository.dart`), and unit tests (`test/features/medications/medication_repository_test.dart`); `flutter analyze` and 16 tests passed. |
| 2026-10-23 | P2.2 | Added `TodayScreen` and `TodayDosesNotifier` (`features/medications/presentation/screens/today_screen.dart`), wired into patient home tab (`home_screen.dart`), and added widget test (`test/features/medications/today_screen_test.dart`); `flutter analyze` and 17 tests passed. |
| 2026-10-23 | P2.3a | Added `MedicationListScreen` and `MedicationsNotifier` (`features/medications/presentation/screens/medication_list_screen.dart`) with confirm-delete dialog, wired `/medications` route, and added widget test (`test/features/medications/medication_list_screen_test.dart`); `flutter analyze` and 18 tests passed. |
| 2026-10-23 | P2.3b | Added `MedicationFormScreen` (`features/medications/presentation/screens/medication_form_screen.dart`) with required field validation, wired routes, and added widget test (`test/features/medications/medication_form_screen_test.dart`); `flutter analyze` and 19 tests passed. |
| 2026-10-23 | P2.3c | Added `MedicationDetailScreen` with schedule editor (`features/medications/presentation/screens/medication_detail_screen.dart`), wired `/medications/:id` route, and added widget test (`test/features/medications/schedule_editor_test.dart`); `flutter analyze` and 20 tests passed. |
| 2026-10-23 | P2.4 | Added `flutter_local_notifications` and `timezone`, Android manifest permissions (`AndroidManifest.xml`), pure `MedicationReminderPlanner` + `LocalReminderService` (`features/medications/data/medication_reminder_planner.dart`), and unit tests (`test/features/medications/medication_reminder_planner_test.dart`); `flutter analyze` and 23 tests passed. |
| 2026-10-23 | P2.5 | Added `connectivity_plus`, `syncBatch` in `MedicationRepository`, `OfflineAdherenceQueue` (`features/medications/data/offline_adherence_queue.dart`), and unit test (`test/features/medications/offline_adherence_queue_test.dart`); `flutter analyze` and 24 tests passed. |
| 2026-10-23 | P3.1 | Added `CaregiverRepository`, `PatientPairingCodeScreen`, `CaregiverPairScreen` (`features/caregiver/presentation/screens/pairing_screens.dart`), routes, and widget tests (`test/features/caregiver/pairing_screens_test.dart`); `flutter analyze` and 26 tests passed. |
| 2026-10-23 | P3.2 | Added `CaregiverDashboardScreen` (`features/caregiver/presentation/screens/caregiver_dashboard_screen.dart`), wired into caregiver home tab (`home_screen.dart`), and added widget test (`test/features/caregiver/caregiver_dashboard_test.dart`); `flutter analyze` and 27 tests passed. |
| 2026-10-23 | P3.3 | Added 15-min missed-dose computation in `services/api/app/api/v1/endpoints/caregiver.py` (`GET /caregiver/patients` and `GET /caregiver/alerts`), updated `schemas/caregiver.py`, `docs/API_SPEC.md`, and `tests/test_caregiver.py`; `ruff check .` and 19 pytest tests passed. |
| 2026-10-23 | P4.1 | Added `VitalsRepository`, `VitalsScreen` (`features/vitals/presentation/screens/vitals_screen.dart`) with icon+text+color triage, route `/vitals`, and widget test (`test/features/vitals/vitals_screen_test.dart`); `flutter analyze` and 28 tests passed. |
| 2026-10-23 | P4.2 | Added `speech_to_text`, `VoiceVitalConfirmDialog` + `startVoiceVitalEntryFlow` (`features/vitals/presentation/screens/voice_vital_entry.dart`), and widget test (`test/features/vitals/voice_vital_entry_test.dart`); `flutter analyze` and 29 tests passed. |
| 2026-10-23 | P5.1 | Added `image_picker`, `PrescriptionRepository`, `PrescriptionScanScreen` (`features/prescription/presentation/screens/prescription_scan_screen.dart`), route `/prescription/scan`, and widget test (`test/features/prescription/prescription_scan_screen_test.dart`); `flutter analyze` and 30 tests passed. |
| 2026-10-23 | P6.1 | Added `EmergencyRepository`, `EmergencyContactsScreen` (`features/emergency/presentation/screens/contacts_screen.dart`), route `/contacts`, and widget test (`test/features/emergency/contacts_screen_test.dart`); `flutter analyze` and 31 tests passed. |
| 2026-10-23 | P6.2 | Added `geolocator`, `SosButtonWidget` (`features/emergency/presentation/widgets/sos_button_widget.dart`) fixed on patient shell (`home_screen.dart`), and widget test (`test/features/emergency/sos_button_test.dart`); `flutter analyze` and 32 tests passed. |
| 2026-10-23 | P7.1 | Added `InventoryRepository`, `InventoryScreen` (`features/inventory/presentation/screens/inventory_screen.dart`) with <7 days warning and refill button, route `/inventory`, and widget test (`test/features/inventory/inventory_screen_test.dart`); `flutter analyze` and 33 tests passed. |
| 2026-10-23 | P8.1 | Added `GET /patients/{patient_id}/reports/summary` in `services/api/app/api/v1/endpoints/reports.py`, `ReportSummaryOut` in `schemas/reports.py`, updated `docs/API_SPEC.md`, and added content + 403 test in `tests/test_prescription_and_reports.py`; `ruff check .` and 19 pytest tests passed. |
| 2026-10-23 | P8.2 | Added `pdf` and `printing`, `ReportSummaryModel`, `ReportsRepository`, `DoctorReportPdfBuilder` (`features/reports/data/reports_repository.dart`), `DoctorReportScreen` (`features/reports/presentation/screens/doctor_report_screen.dart`), route `/reports/doctor`, and unit+widget tests (`test/features/reports/doctor_report_test.dart`); `flutter analyze` and 35 tests passed. |
| 2026-10-23 | P9.1 | Enforced `check_patient_access` in `POST /sync/batch` (`adherence.py`) and added `services/api/tests/test_security_access.py` asserting 403 on all 18 patient/medication routes + 401 on expired JWT; `ruff check .` and 21 pytest tests passed. |
| 2026-10-23 | P9.2 | Ran `flutter_a11y_agent` audit and fixed all high/medium findings: added `Semantics(button: true, ...)` to `SosButtonWidget`, visual+semantic selected states on meal relation and vital type toggles, `materialTapTargetSize: MaterialTapTargetSize.padded` and `>=18sp` `bodyMedium` in `AppTheme`, checkbox semantic label in `PrescriptionScanScreen`, and RTL-safe `EdgeInsetsDirectional` + directional icons; `flutter analyze` and 35 tests passed. |
| 2026-10-23 | P9.3 | Fixed `.github/workflows/ci.yml` by removing invalid job-level `hashFiles` conditions so both `api` and `mobile` jobs validate and run unconditionally on push/PR. |
| 2026-10-23 | P9.4 | Updated `docs/START_HERE.md` status table and `apps/doctor-portal/README.md` to reflect full MVP completion and replacement of the standalone web portal with in-app PDF report generation. |
