import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockVitalsRepository extends Mock implements VitalsRepository;

void main() {
  late MockVitalsRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const VitalCreateInput(type: 'bp', valuePrimary: 120),
    );
  });

  setUp(() {
    repository = MockVitalsRepository();
  });

  testWidgets('VitalsScreen adds a reading and shows triage label', (
    tester,
  ) async {
    when(() => repository.listVitals('patient-1'))
        .thenAnswer((_) async => const []);
    when(() => repository.createVital('patient-1', any())).thenAnswer(
      (_) async => VitalReadingModel(
        id: 'vital-1',
        patientId: 'patient-1',
        type: 'bp',
        valuePrimary: 185,
        valueSecondary: 115,
        band: 'critical',
        recordedAt: DateTime.utc(2026, 10, 23, 12),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          vitalsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VitalsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('لا توجد قياسات مسجلة بعد'), findsWidgets);
    expect(find.text('120 / 80'), findsNothing);
    expect(find.text('160'), findsNothing);
    expect(find.textContaining('7:30'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('vital_primary_field')),
      '185',
    );
    await tester.enterText(
      find.byKey(const ValueKey('vital_secondary_field')),
      '115',
    );
    await tester.tap(find.byKey(const ValueKey('submit_vital_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vital_card_vital-1')), findsOneWidget);
    expect(find.textContaining('185/115'), findsOneWidget);
    expect(find.text('حرج / خطر'), findsOneWidget);
    verify(() => repository.createVital('patient-1', any())).called(1);
  });
}
