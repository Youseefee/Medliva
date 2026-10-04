# قواعد العمل (Conventions)

## Git
- Branches: `main` (مستقر) ← `develop` ← `feature/<scope>-<short>` / `fix/...`
- Commits (Conventional): `feat(mobile): add alarm screen` · `fix(api): ...` · `docs: ...` · `test: ...` · `chore: ...`
- PR إلزامي + مراجعة شخص واحد على الأقل + CI أخضر.

## Code Style
| الجزء | الأدوات |
|---|---|
| Flutter | `flutter analyze`, `very_good_analysis`, `dart format` |
| Python | `ruff` (lint + format), `mypy`, `pytest` |
| Web | ESLint, Prettier, TypeScript strict |

## التسمية
- Dart: ملفات `snake_case.dart`، Classes `PascalCase`.
- Python: `snake_case`، Pydantic schemas بلاحقة `In/Out` (`MedicationIn`).
- DB: جداول جمع `snake_case`، FK بصيغة `<entity>_id`.
- API: kebab/plural nouns (`/medications`).

## الأسرار
- ممنوع رفع `.env` أو مفاتيح. استخدم `infra/.env.example` و GitHub Secrets.

## Definition of Done
- [ ] الكود متراجع ومدموج
- [ ] Tests مكتوبة وناجحة
- [ ] الترجمة (ar/en) مضافة
- [ ] التوثيق محدّث
