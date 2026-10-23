# CareElder — Execution Plan (Agent-Ready)

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
| API (`services/api`) | Endpoints exist: auth, users, caregiver, medications/schedules/today, adherence + sync/batch, vitals + voice parse, AI scan-prescription, inventory forecast/refill, emergency SOS/contacts, reports share/public, devices. Tests per module. Much of it is **uncommitted**. |
| Mobile (`apps/mobile`) | Only auth (phone/OTP), session, router, l10n, home. No feature screens wired to API. |
| Doctor portal | **Dropped as a web app.** Doctor sees a PDF report generated inside the mobile app (Phase 8). `apps/doctor-portal` stays docs-only. |

## Decisions (fixed — do not re-ask)
| Topic | Decision |
|---|---|
| Doctor view | In-app PDF report (medication history, adherence, vitals) shared via system share sheet. No web portal. |
| Patient id for patient users | From `GET /users/me` (`id`). Caregivers pick a patient from `GET /caregiver/patients`. Store selected patient in a Riverpod provider `currentPatientIdProvider`. |
| Escalation | Missed dose = no adherence log 15 min after scheduled time → caregiver notified. |
| Push notifications | Out of scope for now: escalation is computed by API and shown on caregiver dashboard (pull). `POST /devices` still registers token for later FCM. |
| Approved dependencies | Only in the task that names them: `flutter_local_notifications`, `timezone` (P2.4) · `connectivity_plus` (P2.5) · `speech_to_text` (P4.2) · `image_picker` (P5.1) · `geolocator` (P6.2) · `pdf`, `printing` (P8.2). |

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
- [ ] **P0.5 Commit baseline** — ask user first; include `Co-Authored-By`.

## Phase 1 — Mobile foundation
- [ ] **P1.1 API client hardening** in `core/network/api_client.dart`: typed `ApiException` (status, message), interceptor that on 401 calls `/auth/refresh` once, saves tokens, retries; on refresh failure logs out. *Done when:* unit tests cover 401→refresh→retry and refresh-fail→logout.
- [ ] **P1.2 Role-aware routing.** Load `/users/me` after login; patient → `/patient` shell, caregiver → `/caregiver` shell (placeholder screens OK). Add `currentPatientIdProvider`. *Done when:* widget tests for both roles land on correct shell.
- [ ] **P1.3 Profile screen.** `GET/PATCH /users/me` (name, language). *Done when:* widget test: changing language switches app locale.

## Phase 2 — Medications (UC-01, Must)
- [ ] **P2.1 Data layer.** Models + `MedicationRepository` for list/create/update/delete medications, list/create schedules, get today. *Done when:* repository unit tests with mocked dio for each method.
- [ ] **P2.2 Today screen** (patient home tab): one large card per dose (name, dose, time, status); Taken/Skip buttons → `POST /adherence/log`, card updates. *Done when:* widget test taps Taken and sees status change.
- [ ] **P2.3a Medication list screen** with delete (confirm dialog). *Done when:* widget test renders list + delete.
- [ ] **P2.3b Add/Edit medication form** (validation for required fields). *Done when:* widget test submits valid form and shows errors on empty.
- [ ] **P2.3c Schedule editor** (times of day + days of week) on the medication detail. *Done when:* widget test adds a time.
- [ ] **P2.4 Local reminders** (`flutter_local_notifications`, `timezone`). Schedule from today/schedules data; reschedule on change; full-screen intent on Android; repeat every 5 min up to 3 times until Taken/Skip. *Done when:* scheduling logic is in a pure class with unit tests; Android manifest permissions added.
- [ ] **P2.5 Offline queue** (`connectivity_plus`): failed adherence logs saved locally, flushed via `POST /sync/batch` when online. *Done when:* unit test: offline log → queued → online → batch sent once.

## Phase 3 — Caregiver (UC-04, Must)
- [ ] **P3.1 Pairing.** Patient screen shows code from `POST /caregiver/pairing-code` (big digits); caregiver enters it → `POST /caregiver/pair`. *Done when:* widget tests for both screens.
- [ ] **P3.2 Caregiver dashboard** (`GET /caregiver/patients`): list of patients with today's taken/missed counts; tap → sets `currentPatientIdProvider` and opens patient's Today (read-only). *Done when:* widget test.
- [ ] **P3.3 Missed-dose escalation (API).** Compute missed doses (15 min rule) and expose them in caregiver patients response or a new `GET /caregiver/alerts`; update schema, API_SPEC, tests. Show alerts badge on dashboard. *Done when:* pytest covers on-time / missed / logged-late cases.

## Phase 4 — Vitals (UC-03, Must)
- [ ] **P4.1 Vitals list + manual entry** (`GET/POST /patients/{id}/vitals`); show triage level as icon + text + color. *Done when:* widget test adds a reading and sees triage label.
- [ ] **P4.2 Voice entry** (`speech_to_text`, locale ar/en): transcript → `POST /ai/parse-voice-vitals` → editable confirm screen → save. *Done when:* widget test with mocked parser shows confirm screen; nothing saved without confirm.

## Phase 5 — Prescription scan (UC-02, Must)
- [ ] **P5.1** `image_picker` (camera/gallery) → `POST /ai/scan-prescription` → editable review list → create selected medications. *Done when:* widget test: mocked scan result → edit → confirm creates meds; cancel creates none.

## Phase 6 — Emergency (UC-07, Must)
- [ ] **P6.1 Contacts screen** (`GET/POST /patients/{id}/contacts`). *Done when:* widget test.
- [ ] **P6.2 SOS button** fixed on patient shell; long-press 2s or confirm dialog → `POST /emergency/sos` with location (`geolocator`) if permission granted, without otherwise. *Done when:* widget test: accidental tap does nothing; confirmed press calls API.

## Phase 7 — Inventory (UC-05, Should)
- [ ] **P7.1** Per-medication "days left" card (`/inventory/forecast`), warning under 7 days, refill button (`/inventory/refill-order`). *Done when:* widget test for warning state.

## Phase 8 — Doctor PDF report (UC-06, Must)
- [ ] **P8.1 Report data endpoint (API).** Ensure an authenticated endpoint returns, for a patient and date range (default last 30 days): patient info, active medications + schedules, adherence history (per dose: scheduled/taken/skipped/missed) with adherence %, vitals history with triage. Reuse existing reports module if it already returns this; otherwise add `GET /patients/{id}/reports/summary?from=&to=`. Keep the existing public share-token endpoint untouched. *Done when:* pytest covers content + access control (other users get 403).
- [ ] **P8.2 PDF generation in app** (`pdf`, `printing`): "Doctor report" screen → pick range → build PDF (Arabic font embedded, RTL when locale ar) with sections: header (patient, date range), medications table, adherence summary + table, vitals table with abnormal values marked by text, footer disclaimer. Preview, then share/print via `Printing`. *Done when:* unit test builds PDF bytes from sample data without error; widget test opens screen.

## Phase 9 — Hardening
- [ ] **P9.1** Security review vs `docs/SECURITY.md`: OTP rate limit, token expiry, patient-access check on every `{patient_id}` route. *Done when:* a pytest per route asserting 403 for unrelated user.
- [ ] **P9.2** Accessibility audit (`flutter_a11y_agent`); fix findings. *Done when:* no high-severity findings left.
- [ ] **P9.3** CI (`.github/workflows/ci.yml`) runs API + mobile checks. *Done when:* workflow YAML validates and runs both.
- [ ] **P9.4** Update `START_HERE.md` status table and `apps/doctor-portal/README.md` (note: replaced by in-app PDF).

---

## Progress log
| Date | Task | Result / notes |
|---|---|---|
| 2026-10-23 | P0.1 | Green API baseline: uv sync, ruff format/lint fixed, 18 pytest tests passing. |
| 2026-10-23 | P0.2 | Added `services/api/alembic/versions/2026_10_23_0003_domain_models.py` covering all domain models; `alembic upgrade head`, `alembic downgrade base`, `alembic check` (no diff), `ruff check .`, and 18 pytest tests passed. |
| 2026-10-23 | P0.3 | Green mobile baseline: `flutter pub get`, `flutter analyze` (No issues found), and `flutter test` (4 tests passed). |
| 2026-10-23 | P0.4 | Synced `docs/API_SPEC.md` with all actual routes in `services/api/app/api/v1/router.py` and `app/main.py`, including request/response schemas and removing fictional routes. |
