# Medliva Agent Instructions

## First read
- Read docs/START_HERE.md before exploring the repository.
- For implementation work, follow docs/EXECUTION_PLAN.md (one unchecked task per run).
- Read only the docs linked from that map for the requested area.
- Check git status --short first; preserve unrelated working-tree changes.

## Project map
- apps/mobile: Flutter patient/caregiver app.
- supabase/migrations: versioned PostgreSQL schema, security, and RPC changes.
- supabase/functions: TypeScript Edge Functions.
- docs/: canonical plans, contracts, architecture, and research notes.
- apps/doctor-portal: documentation only; doctor reports are created in the mobile app.

## Do not scan by default
- .git/, .dart_tool/, build/, node_modules/, .next/, and dist/.
- docs/original/ contains reference PDFs/HTML; open only for a documentation task.
- docs/tools/ contains generated deliverables; open only when changing those deliverables.

## Commands
| Area | Install | Check | Run |
|---|---|---|---|
| Mobile | flutter pub get | flutter analyze && flutter test | flutter run |
| Supabase | supabase --help | use the documented CLI command for the task | supabase start |

Run Flutter commands from apps/mobile. Use the linked Supabase project for database and Edge Function changes. Check the installed Supabase CLI help before choosing CLI commands.

## Change boundaries
- Keep Flutter repositories/models, SQL migrations/RLS/RPCs, Edge Functions, and tests aligned.
- Keep Arabic/English localization and elderly accessibility intact.
- Do not treat MASTER_PLAN.md or ROADMAP.md as proof that a feature is implemented.
- Do not add dependencies or restructure directories unless the task requires it.

## Commit attribution
If creating a commit, AI commits MUST include the agent model's Co-Authored-By attribution.
