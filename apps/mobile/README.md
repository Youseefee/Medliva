# 📱 Medliva Mobile (Flutter)

تطبيق الموبايل لمشروع **Medliva** (رعاية ذكية لكبار السن ومتابعة عائلية).

## 🏗️ المعمارية الحالية (Clean Architecture)
```
lib/
├── core/
│   ├── config/      # AppConfig (API_BASE_URL via --dart-define)
│   ├── network/     # ApiClient (Dio + Supabase session interceptor)
│   ├── router/      # GoRouter (Auth redirection + Splash/Login/Home)
│   ├── storage/     # TokenStorage wrapper around the Supabase Auth session
│   ├── theme/       # AppTheme (Accessible, Cairo Font, High Contrast, Large Buttons)
│   └── utils/       # PhoneValidator (Egyptian phone normalization)
├── features/
│   ├── auth/
│   │   ├── data/            # AuthRepository
│   │   ├── domain/models/   # UserModel
│   │   └── presentation/    # AuthNotifier (Riverpod) + email/password screen
│   └── home/
│       └── presentation/    # HomeScreen (Welcome + User Role + Logout)
├── l10n/                    # AppLocalizations (ar/en) - العربية افتراضية RTL
└── main.dart
```

## 📦 الحزم المستخدمة (Sprint 2)
- `flutter_riverpod`: إدارة الحالة بالـ Notifiers بدون Code Generation.
- `go_router`: التوجيه والتحويل التلقائي حسب حالة تسجيل الدخول.
- `supabase_flutter`: تسجيل البريد وكلمة المرور، وإدارة جلسة الدخول وتجديدها.
- `dio`: التعامل مع FastAPI وإرسال Access Token الصادر من Supabase Auth.
- `google_fonts`: خط القاهرة (Cairo) لسهولة القراءة لكبار السن.
- `intl` & `flutter_localizations`: دعم كامل للغتين العربية والإنجليزية.

## 🚀 كيفية التشغيل

### تشغيل على محاكي الأندرويد (Android Emulator):
```bash
flutter run
```
*(القيمة الافتراضية للـ API هي `http://10.0.2.2:8000/api/v1`)*

### تشغيل على جهاز حقيقي عبر الشبكة المحلية (Local IP):
```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_LOCAL_IP>:8000/api/v1
```

يمكن تبديل المشروع ومفتاحه العام عند البناء باستخدام `SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY` عبر `--dart-define`. التطبيق يستخدم مفتاحاً عاماً فقط؛ لا تضع مفتاح `service_role` داخل تطبيق الموبايل.

### الاختبار والتحليل:
```bash
flutter analyze
flutter test
```
