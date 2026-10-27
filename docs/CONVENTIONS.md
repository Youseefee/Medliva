# قواعد العمل

## Git
- Branches: main وdevelop وfeature/<scope>-<short> أو fix/<short>.
- Commits (Conventional): feat(mobile): ... · fix(mobile): ... · docs: ... · test: ... · chore: ...
- PR إلزامي حسب سير الفريق، مع مراجعة شخص آخر وفحوص ناجحة.

## Code Style
| الجزء | الأدوات |
|---|---|
| Flutter/Dart | flutter analyze وdart format |
| Supabase SQL | migrations مرتبة، أسماء snake_case، RLS لكل جدول مكشوف |
| Edge Functions | TypeScript وDeno، أسرار خارج ملفات المصدر |

## التسمية
- Dart: ملفات snake_case.dart، Classes بصيغة PascalCase.
- SQL: الجداول والدوال snake_case، ومفاتيح FK بصيغة <entity>_id.
- Edge Functions: أسماء kebab-case.

## الأسرار
- لا ترفع ملفات الأسرار أو مفاتيح Supabase السرية.
- استخدم المفتاح العام فقط في Flutter؛ أبقِ مفاتيح الخادم في أسرار Supabase.

## Definition of Done
- [ ] تغييرات الكود متوافقة مع RLS وRPC أو Edge Function المقابلة.
- [ ] الاختبارات والفحوص المتأثرة ناجحة.
- [ ] الترجمة العربية والإنجليزية محدثة لأي نص ظاهر.
- [ ] التوثيق محدث.
