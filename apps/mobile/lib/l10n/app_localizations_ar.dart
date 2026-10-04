// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'كير إلدر';

  @override
  String get appTagline => 'رعاية ذكية لكبار السن ومتابعة لحظية للأهل';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'أدخل رقم هاتفك لتسجيل الدخول أو إنشاء حساب جديد';

  @override
  String get phoneLabel => 'رقم الهاتف المحمول';

  @override
  String get phoneHint => '01012345678';

  @override
  String get sendOtpButton => 'إرسال رمز التحقق';

  @override
  String get otpTitle => 'تأكيد رقم الهاتف';

  @override
  String otpSubtitle(String phone) {
    return 'تم إرسال رمز مكون من 6 أرقام إلى الرقم $phone';
  }

  @override
  String get otpLabel => 'رمز التحقق';

  @override
  String get otpHint => '123456';

  @override
  String get verifyButton => 'تأكيد ودخول';

  @override
  String get resendButton => 'إعادة الإرسال';

  @override
  String get nameLabel => 'الاسم بالكامل';

  @override
  String get nameHint => 'مثال: أحمد محمد';

  @override
  String get roleLabel => 'نوع الحساب';

  @override
  String get rolePatient => 'مريض / كبير سن';

  @override
  String get roleCaregiver => 'مرافق / ابن أو ابنة';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String welcomeUser(String name) {
    return 'أهلاً بك، $name';
  }

  @override
  String userRoleLabel(String role) {
    return 'الدور: $role';
  }

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get errorOccurred => 'حدث خطأ ما';

  @override
  String get retry => 'إعادة المحاولة';
}
