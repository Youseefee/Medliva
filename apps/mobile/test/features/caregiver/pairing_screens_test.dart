import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:medliva/features/caregiver/presentation/screens/pairing_screens.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCaregiverRepository extends Mock implements CaregiverRepository;

void main() {
  late MockCaregiverRepository repository;

  setUp(() {
    repository = MockCaregiverRepository();
  });

  testWidgets('PatientPairingCodeScreen requests and shows 6-digit pairing code',
      (tester) async {
    when(() => repository.generatePairingCode()).thenAnswer(
      (_) async => PairingCodeModel(
        code: '654321',
        expiresAt: DateTime.utc(2026, 10, 23, 15),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caregiverRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PatientPairingCodeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pairing_code_display')), findsOneWidget);
    expect(find.text('654321'), findsOneWidget);
    verify(() => repository.generatePairingCode()).called(1);
  });

  testWidgets('CaregiverPairScreen submits entered pairing code',
      (tester) async {
    when(() => repository.pairWithPatient('654321')).thenAnswer(
      (_) async => const LinkedPatientModel(
        patientId: 'patient-1',
        phone: '+201012345678',
        name: 'عم أحمد',
        status: 'active',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caregiverRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CaregiverPairScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('caregiver_pair_code_field')),
      '654321',
    );
    await tester.tap(find.byKey(const ValueKey('caregiver_pair_submit_btn')));
    await tester.pumpAndSettle();

    expect(find.text('تم ربط حساب المريض بنجاح'), findsOneWidget);
    verify(() => repository.pairWithPatient('654321')).called(1);
  });
}
