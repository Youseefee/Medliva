import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/screens/email_password_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'EmailPasswordScreen renders in Arabic with elderly-friendly UI',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EmailPasswordScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Arabic app name and labels are displayed
      expect(find.text('ميدليفا'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsNWidgets(2));
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('ليس لديك حساب؟ أنشئ حساباً'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    },
  );
}
