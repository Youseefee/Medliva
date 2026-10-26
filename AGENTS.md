# Medliva Agent Instructions

## First read
- Read `docs/START_HERE.md` before exploring the repository.
- For implementation work, follow `docs/EXECUTION_PLAN.md` (one unchecked task per run).
- Read only the docs linked from that map for the requested area.
- Check `git status --short` first; preserve unrelated working-tree changes.

## Project map
- `apps/mobile`: Flutter patient/caregiver app; current UI is auth (email/password via Supabase Auth, no phone/SMS/OTP in the MVP), and home.
- `services/api`: FastAPI modular monolith; implementation and tests are the source of truth.
- `apps/doctor-portal`: reserved for the doctor report portal; currently documentation only.
- `docs/`: canonical plans, contracts, architecture, and research notes.
- `infra/`: environment examples and optional local service configuration.

## Do not scan by default
- `.git/`, `services/api/.venv/`, `**/__pycache__/`, `.dart_tool/`, `build/`, `node_modules/`, `.next/`, and `dist/`.
- `docs/original/` contains reference PDFs/HTML; open only for a documentation task.
- `docs/tools/` contains document generators; open only when changing generated deliverables.

## Commands
| Area | Install | Check | Run |
|---|---|---|---|
| API | `uv sync` | `uv run ruff check . && uv run pytest` | `uv run uvicorn app.main:app --reload --port 8000` |
| Mobile | `flutter pub get` | `flutter analyze && flutter test` | `flutter run` |

Run API commands from `services/api` and Flutter commands from `apps/mobile`.
Prefer tests for the touched feature before broad checks.

## Change boundaries
- Keep API routes, schemas, models, migrations, and tests aligned.
- Keep Arabic/English localization and elderly accessibility intact.
- Do not treat `MASTER_PLAN.md` or `ROADMAP.md` as proof that a feature is implemented.
- Do not add dependencies or restructure directories unless the task requires it.

## Commit attribution
If creating a commit, AI commits MUST include the agent model's `Co-Authored-By` attribution.
