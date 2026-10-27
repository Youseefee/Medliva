# Medliva Mobile

تطبيق Flutter للمريض والمرافق. جميع بيانات التطبيق والمصادقة والملفات تستخدم Supabase مباشرة عبر `supabase_flutter`؛ لا يحتاج التطبيق إلى خادم محلي.

## التشغيل

```powershell
flutter pub get
flutter run
```

تأتي `SUPABASE_URL` ومفتاح `SUPABASE_PUBLISHABLE_KEY` من إعداد التطبيق في `lib/core/config/app_config.dart`. يمكن تبديلهما عند التشغيل:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

استخدم مفتاحًا عامًا فقط داخل تطبيق الموبايل؛ لا تضع مفتاحًا سريًا أو `service_role` فيه. يُخزّن مفتاح Gemini ضمن أسرار Supabase Edge Functions، وليس في التطبيق.

## الخدمات المستخدمة

- Supabase Auth للبريد وكلمة المرور والجلسة.
- PostgREST ودوال PostgreSQL للملفات الطبية والجرعات والمرافق والتنبيهات والتقارير.
- Supabase Storage للصور الخاصة بسياسات RLS.
- Edge Functions لمسح الروشتة ومشاركة التقرير العام.
- تخزين آمن على الجهاز لطابور الجرعات الذي ينتظر المزامنة عند عودة الاتصال.

## الفحص

```powershell
flutter analyze
flutter test
```
