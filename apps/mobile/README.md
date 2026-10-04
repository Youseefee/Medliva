# 📱 CareElder Mobile (Flutter)

تطبيق الموبايل لمشروع **CareElder** (رعاية ذكية لكبار السن ومتابعة عائلية).

## 🏗️ المعمارية الحالية (Clean Architecture)
```
lib/
├── core/
│   ├── config/      # AppConfig (API_BASE_URL via --dart-define)
│   ├── network/     # ApiClient (Dio + Token Interceptor + Auto Refresh on 401)
│   ├── router/      # GoRouter (Auth redirection + Splash/Login/OTP/Home)
│   ├── storage/     # TokenStorage (flutter_secure_storage)
│   ├── theme/       # AppTheme (Accessible, Cairo Font, High Contrast, Large Buttons)
│   └── utils/       # PhoneValidator (Egyptian phone normalization)
├── features/
│   ├── auth/
│   │   ├── data/            # AuthRepository
│   │   ├── domain/models/   # UserModel
│   │   └── presentation/    # AuthNotifier (Riverpod) + PhoneScreen + OtpScreen
│   └── home/
│       └── presentation/    # HomeScreen (Welcome + User Role + Logout)
├── l10n/                    # AppLocalizations (ar/en) - العربية افتراضية RTL
└── main.dart
```

## 📦 الحزم المستخدمة (Sprint 2)
- `flutter_riverpod`: إدارة الحالة بالـ Notifiers بدون Code Generation.
- `go_router`: التوجيه والتحويل التلقائي حسب حالة تسجيل الدخول.
- `dio`: التعامل مع الـ API والتجديد التلقائي لرمز الدخول (JWT Token Refresh).
- `flutter_secure_storage`: التخزين الآمن لمفاتيح الجلسة.
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

### الاختبار والتحليل:
```bash
flutter analyze
flutter test
```
