# قاعدة البيانات — Supabase PostgreSQL

قاعدة البيانات الفعلية مستضافة على Supabase. يرسل Flutter طلبات PostgREST وRPC مع جلسة Auth؛ سياسات RLS تحصر الوصول. تُسجل تغييرات SQL في supabase/migrations، وتوجد Edge Functions في supabase/functions.

## مخطط البيانات

| الجدول | الاستخدام والحقول الأساسية |
|---|---|
| users | ملف Auth: id، email، phone، name، role، language، timezone، birth_date، address |
| caregiver_links | caregiver_id، patient_id، pairing_code، pairing_code_expires_at، status، permissions_mask، linked_at |
| drug_catalog | trade_name، active_ingredient، strength، form، manufacturer، price_egp |
| medications | patient_id، drug_catalog_id، الاسم والمادة الفعالة، الشكل والتركيز، pill_image_url، stock_count، alert_threshold_days، expiry_date، is_active |
| schedules | medication_id، time_of_day، days_mask، dose_amount، meal_relation، instructions_ar، start_date، end_date، is_active |
| intake_logs | client_uuid، schedule_id، patient_id، scheduled_time، actual_time، status، reason، logged_offline |
| vitals_logs | client_uuid، patient_id، type، value_primary، value_secondary، meal_context، band، recorded_at |
| prescriptions | patient_id، image_url، doctor_name، raw_extracted_json، confidence، verified_at، verified_by |
| emergency_contacts | patient_id، name، phone، relationship، is_primary، notify_call |
| devices | user_id، fcm_token، platform، app_version، last_seen |
| report_shares | patient_id، token_hash، scope، expires_at، views_count، revoked |
| alerts | patient_id، type، tier، payload_json، sent_at، acknowledged_at |

تستخدم الجداول معرفات UUID وعلاقات FK، وتضيف الطوابع الزمنية التي يعرفها المخطط الفعلي. لا توجد جداول Drift للمزامنة في التطبيق الحالي؛ طابور الجرعات محفوظ محليًا بشكل آمن.

## الأمان والعمليات

- RLS مفعّل على جداول public المستخدمة في التطبيق.
- سياسات كل جدول تربط الصف بالمريض أو بمرافق ذي caregiver_link نشط.
- إنشاء/تعديل الملف الشخصي محدود بصاحب الحساب؛ لا يسمح للعميل بترقية دوره إلى admin.
- دوال RPC الخاصة بالجرعات والقياسات والاقتران وSOS والأجهزة والتقارير تتحقق من المستخدم والارتباط، مع منح التنفيذ للأدوار المطلوبة فقط.
- OCR لا يكتب سجلات الوصفات أو الأدوية؛ يرسل اقتراحات ليؤكدها المستخدم.
- يتم حفظ بصمة رمز مشاركة التقرير في report_shares، ويعيد Edge Function التقرير قبل انتهاء الرمز أو إلغائه.
- صور prescriptions وpill-images في buckets خاصة بسياسات Storage.

## كتالوج الأدوية

يحتوي مشروع Supabase المرتبط على كتالوج مشترك للأدوية. تُحفظ بيانات الكتالوج في قاعدة البيانات؛ لا تزرع بيانات مرضى تجريبية من التطبيق.

## إعداد قاعدة البيانات

ملف `supabase/migrations/20261027113900_initial_schema.sql` ينشئ الجداول الاثني عشر وعلاقاتها وفهارسها ويفعّل RLS، كما يضمن وجود مخزني الصور الخاصين. بعده تطبق الترحيلات المرتبة سياسات الوصول والمنح ودوال RPC والمشغلات. ملف `supabase/seed.sql` يضيف بيانات كتالوج أدوية عامة فقط، ولا يضيف حسابات أو بيانات مرضى تجريبية.

لإنشاء بيئة محلية جديدة، ثبّت Supabase CLI وDocker ثم شغّل `supabase start` و`supabase db reset` من جذر المشروع. هذا يعيد إنشاء قاعدة Supabase المحلية فقط؛ لا تستخدم `db reset` على المشروع السحابي المرتبط لأنه يمسح بياناته. قاعدة المشروع السحابي الحالية تحتفظ ببياناتها وتستقبل الترحيلات الجديدة عبر `supabase db push` بعد ربط CLI بالمشروع.
