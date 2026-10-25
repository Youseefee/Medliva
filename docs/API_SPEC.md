# مواصفات الـ API (v1)

- **Base URL:** `/api/v1` (باستثناء `/health` على الجذر `/`)
- **Format:** JSON (`multipart/form-data` لرفع صورة الروشتة)
- **Auth:** Supabase Auth manages sign-in and sessions; protected API requests use `Authorization: Bearer <Supabase access token>`.
- **Errors:** `{ "error": { "code": "STRING", "message": "..." } }`
- **Swagger / OpenAPI:** متاح في بيئة التطوير على `/docs` و`/redoc`.

## جدول المسارات الفعلية (Routes)

| Method | Path | Auth / الصلاحية | Request Schema | Response Schema | الوصف |
|---|---|---|---|---|---|
| `GET` | `/health` | Public | — | `dict[str, str]` | فحص حالة الخادم (موجود على الجذر خارج `/api/v1`) |
| `GET` | `/me` | Supabase Auth | — | `UserOut` | جلب ملف المستخدم المرتبط بمعرّف Supabase الحالي |
| `PATCH` | `/me` | Supabase Auth | `UserUpdateIn` | `UserOut` | تحديث بيانات المستخدم الحالي (الاسم، اللغة، المنطقة الزمنية، تاريخ الميلاد، العنوان) |
| `POST` | `/caregiver/pairing-code` | Patient | — | `PairingCodeResponse` | توليد كود اقتران من 6 أرقام صالح لمدة 10 دقائق |
| `POST` | `/caregiver/pair` | Caregiver | `PairCaregiverRequest` | `LinkedPatientOut` | ربط حساب المرافق بالمريض عبر كود الاقتران |
| `GET` | `/caregiver/patients` | Caregiver | — | `list[LinkedPatientOut]` | قائمة المرضى المرتبطين بالمرافق الحالي مع إحصاءات التناول/التفويت وتنبيهات الـ 15 دقيقة |
| `GET` | `/caregiver/alerts` | Caregiver | — | `list[MissedDoseAlertOut]` | جلب تنبيهات الجرعات الفائتة (بعد 15 دقيقة بدون تسجيل) للمرضى المرتبطين |
| `GET` | `/patients/{patient_id}/medications` | Patient / Linked Caregiver | — | `list[MedicationOut]` | قائمة الأدوية النشطة للمريض مع مواعيدها |
| `POST` | `/patients/{patient_id}/medications` | Patient / Linked Caregiver | `MedicationCreate` | `MedicationOut` (`201`) | إضافة دواء جديد للمريض مع جدول مواعيده الاختياري |
| `PATCH` | `/medications/{medication_id}` | Patient / Linked Caregiver | `MedicationUpdate` | `MedicationOut` | تعديل بيانات الدواء أو مخزونه أو حالته |
| `DELETE` | `/medications/{medication_id}` | Patient / Linked Caregiver | — | `dict[str, str]` | إلغاء تفعيل الدواء (`is_active = false`) |
| `GET` | `/medications/{medication_id}/schedules` | Patient / Linked Caregiver | — | `list[ScheduleOut]` | جلب مواعيد جرعات دواء معيّن |
| `POST` | `/medications/{medication_id}/schedules` | Patient / Linked Caregiver | `ScheduleCreate` | `ScheduleOut` (`201`) | إضافة موعد جرعة جديد لدواء معيّن |
| `GET` | `/patients/{patient_id}/today` | Patient / Linked Caregiver | — | `list[TodayDoseOut]` | جلب جدول جرعات اليوم للمريض مع حالة كل جرعة (`pending` / `taken` / `skipped` / `missed` / `snoozed`) |
| `POST` | `/adherence/log` | Patient / Linked Caregiver | `IntakeLogCreate` | `IntakeLogOut` | تسجيل تناول/تخطي/تأجيل الجرعة (مع خصم المخزون وإصدار تنبيه انخفاض المخزون عند اللزوم) |
| `POST` | `/sync/batch` | Auth | `SyncBatchRequest` | `SyncBatchResponse` | مزامنة دفعية للسجلات المسجلة بدون إنترنت (`intake_log`, `vitals_log`) |
| `GET` | `/patients/{patient_id}/vitals` | Patient / Linked Caregiver | Query: `type`, `limit` | `list[VitalsOut]` | جلب سجل القياسات الحيوية للمريض مع إمكانية الفلترة بنوع القياس (`bp`, `glucose`, `pulse`) |
| `POST` | `/patients/{patient_id}/vitals` | Patient / Linked Caregiver | `VitalsCreate` | `VitalsOut` (`201`) | تسجيل قياس حيوي جديد وحساب تصنيفه الطبي (`normal`, `borderline`, `critical`) |
| `POST` | `/ai/parse-voice-vitals` | Auth | `VoiceVitalsRequest` | `VoiceVitalsResponse` | تحليل النص الصوتي للقياسات الحيوية باللهجة المصرية واستخراج القيم والتصنيف |
| `POST` | `/ai/scan-prescription` | Auth | `multipart/form-data` (`file`) | `PrescriptionScanResponse` | مسح صورة الروشتة واستخراج الأدوية ومطابقتها مع دليل الأدوية |
| `GET` | `/patients/{patient_id}/inventory/forecast` | Patient / Linked Caregiver | — | `InventoryForecastOut` | حساب الأيام المتبقية لكل دواء وعدد الأدوية منخفضة المخزون أو منتهية الصلاحية |
| `POST` | `/patients/{patient_id}/inventory/refill-order` | Patient / Linked Caregiver | `RefillOrderRequest` | `RefillOrderOut` | توليد نص طلب إعادة التعبئة ورابط واتساب (`wa.me`) للصيدلية |
| `POST` | `/emergency/sos` | Auth | `SosRequest` | `SosResponse` | إطلاق نداء استغاثة عاجل (SOS) مع الموقع الجغرافي الاختياري وإشعار جهات الاتصال والمرافقين |
| `GET` | `/patients/{patient_id}/contacts` | Patient / Linked Caregiver | — | `list[EmergencyContactOut]` | جلب قائمة جهات اتصال الطوارئ الخاصة بالمريض |
| `POST` | `/patients/{patient_id}/contacts` | Patient / Linked Caregiver | `EmergencyContactCreate` | `EmergencyContactOut` (`201`) | إضافة جهة اتصال طوارئ جديدة للمريض |
| `GET` | `/patients/{patient_id}/alerts` | Patient / Linked Caregiver | Query: `limit` (1-200, افتراضي 50), `now` | `list[AlertOut]` | جلب أحدث تنبيهات المريض (`sos`, `critical_vital`, `low_stock`, `missed_dose`) مرتبة من الأحدث للأقدم؛ الجرعات الفائتة تُحسب من جدول اليوم وقاعدة الـ 15 دقيقة |
| `GET` | `/patients/{patient_id}/caregivers` | Patient / Linked Caregiver | — | `list[LinkedCaregiverOut]` | جلب المرافقين الذين يراقبون حالة المريض (منظور المريض) |
| `POST` | `/patients/{patient_id}/reports/share` | Patient / Linked Caregiver | `ReportShareCreate` | `ReportShareOut` | إنشاء رابط مشاركة مؤقت لتقرير المريض الطبي |
| `GET` | `/patients/{patient_id}/reports/summary` | Patient / Linked Caregiver | Query: `from`, `to` | `ReportSummaryOut` | جلب بيانات التقرير الطبي الكامل للمريض (الأدوية، الالتزام، القياسات الحيوية) لبناء ملف PDF داخل التطبيق |
| `GET` | `/public/reports/{token}` | Public Token | — | `PublicReportOut` | عرض التقرير الطبي العام للمريض عبر رمز المشاركة الصالح |
| `POST` | `/devices` | Auth | `DeviceRegisterRequest` | `dict[str, str]` | تسجيل أو تحديث رمز إشعارات الجهاز (`fcm_token`) |

## أمثلة

**POST `/api/v1/adherence/log`** (`IntakeLogCreate` → `IntakeLogOut`)
```json
{
  "client_uuid": "6f1c9a10-1234-4b5c-89ab-0123456789ab",
  "schedule_id": "2c8d3f01-1234-4b5c-89ab-0123456789ab",
  "scheduled_time": "2026-10-23T08:00:00Z",
  "actual_time": "2026-10-23T08:04:12Z",
  "status": "taken",
  "logged_offline": false
}
```

**POST `/api/v1/ai/scan-prescription`** (`multipart/form-data` → `PrescriptionScanResponse`)
```json
{
  "medications": [
    {
      "drug_trade_name": "Concor 5mg",
      "active_ingredient": "Bisoprolol",
      "dosage_mg": "5mg",
      "frequency_per_day": 1,
      "meal_relation": "after_meal",
      "times": ["08:00"],
      "inventory_pills": 30,
      "confidence_score": 0.96
    }
  ],
  "confidence": 0.96,
  "source": "gemini_vision"
}
```
- `source` = `gemini_vision` عندما تُقرأ الصورة عبر Gemini Vision (يتطلب `GEMINI_API_KEY`)، و`text` في حالة التحليل النصي.
- عند عدم وجود أي دواء في الصورة/النص ترجع `medications: []` و`confidence: 0.0` — النظام لا يخترع الأدوية أبداً.

**POST `/api/v1/ai/parse-voice-vitals`** (`VoiceVitalsRequest` → `VoiceVitalsResponse`)
```json
{
  "transcript": "الضغط النهارده 135 على 85",
  "type": "bp",
  "value_primary": 135.0,
  "value_secondary": 85.0,
  "meal_context": null,
  "band": "borderline",
  "message_ar": "الضغط مرتفع قليلاً، يُنصح بالراحة وتقليل الملح والمتابعة"
}
```
