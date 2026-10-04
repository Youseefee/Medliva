// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CareElder';

  @override
  String get appTagline => 'Smart Elderly Care & Real-time Family Monitoring';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Enter your phone number to sign in or register';

  @override
  String get phoneLabel => 'Mobile Number';

  @override
  String get phoneHint => '01012345678';

  @override
  String get sendOtpButton => 'Send Verification Code';

  @override
  String get otpTitle => 'Verify Phone';

  @override
  String otpSubtitle(String phone) {
    return 'A 6-digit code was sent to $phone';
  }

  @override
  String get otpLabel => 'Verification Code';

  @override
  String get otpHint => '123456';

  @override
  String get verifyButton => 'Verify & Enter';

  @override
  String get resendButton => 'Resend Code';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get nameHint => 'e.g., Ahmed Mohamed';

  @override
  String get roleLabel => 'Account Type';

  @override
  String get rolePatient => 'Patient / Senior';

  @override
  String get roleCaregiver => 'Caregiver / Family';

  @override
  String get homeTitle => 'Home';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String userRoleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get logoutButton => 'Log Out';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get retry => 'Retry';
}
