import 'package:careelder/features/auth/presentation/screens/phone_screen.dart';
import 'package:careelder/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PhoneScreen renders in Arabic with elderly-friendly UI',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhoneScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Arabic app name and labels are displayed
    expect(find.text('كير إلدر'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إرسال رمز التحقق'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
