# Medliva

تطبيق Flutter عربي/إنجليزي للمريض والمرافق لإدارة الأدوية والجرعات والقياسات والتنبيهات والتقارير الطبية.

## المعمارية

- تطبيق الهاتف: Flutter وDart في apps/mobile.
- الخدمات: Supabase Auth وPostgreSQL/PostgREST وStorage وEdge Functions.
- مسح الروشتة: Edge Function scan-prescription؛ مفتاح Gemini محفوظ ضمن أسرار Supabase.
- التقارير العامة: Edge Function public-report تتحقق من رمز المشاركة وانتهائه.
- الصور: مخازن Supabase خاصة مع سياسات RLS للمريض والمرافق المرتبط.

كل عمليات التطبيق تستخدم Supabase مباشرة؛ لا يحتاج التشغيل إلى خادم محلي.

## التشغيل السريع على Windows

شغّل:

```powershell
.\run.ps1
```

أو شغّل التطبيق يدويًا:

```powershell
cd apps/mobile
flutter pub get
flutter run
```

يستخدم التطبيق إعدادات Supabase الموجودة في apps/mobile/lib/core/config/app_config.dart. لتشغيل مشروع آخر:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

ضع GEMINI_API_KEY في أسرار Edge Functions داخل لوحة Supabase. لا تستخدم مفتاحًا سريًا أو service_role داخل Flutter.

## قاعدة البيانات والدوال

ملفات SQL المضافة موجودة في supabase/migrations، ودوال Edge في supabase/functions. يبدأ `20261027113900_initial_schema.sql` مخطط قاعدة فارغة، ثم تضيف الترحيلات المرتبة سياسات الأمان ودوال RPC. لإعداد Supabase محليًا ثبّت Supabase CLI وDocker ثم شغّل `supabase start` و`supabase db reset` من جذر المشروع. يحتوي `supabase/seed.sql` على كتالوج أدوية مشترك فقط، دون حسابات أو سجلات مرضى تجريبية.

## الفحوصات

```powershell
cd apps/mobile
flutter analyze
flutter test
```

تُشغّل GitHub Actions الفحوصات نفسها وتبني APK أندرويد.

## تنزيل APK

- [تنزيل Medliva-v1.0.0.apk](https://github.com/Youseefee/Medliva/releases/download/v1.0.0-latest/Medliva-v1.0.0.apk)
- [صفحة الإصدارات](https://github.com/Youseefee/Medliva/releases/tag/v1.0.0-latest)

## الوثائق

- [دليل البدء والحالة الحالية](docs/START_HERE.md)
- [خطة التنفيذ](docs/EXECUTION_PLAN.md)
- [المعمارية](docs/ARCHITECTURE.md)
- [عقد Supabase](docs/API_SPEC.md)
- [قاعدة البيانات](docs/DATABASE.md)
- [مسار الذكاء الاصطناعي](docs/AI_PIPELINE.md)
- [الأمان والخصوصية](docs/SECURITY.md)
