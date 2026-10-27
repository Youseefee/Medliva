import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

void main() {
  late MockMedicationRepository repository;

  setUpAll(() {
    registerFallbackValue(
      IntakeLogCreateInput(
        clientUuid: 'fallback',
        scheduleId: 'sched-1',
        scheduledTime: DateTime.utc(2026, 10, 23, 8),
      ),
    );
  });

  setUp(() {
    repository = MockMedicationRepository();
  });

  testWidgets(
    'TodayScreen renders dose card and updates status when Taken is tapped',
    (tester) async {
      when(() => repository.getTodayDoses('patient-1')).thenAnswer(
        (_) async => const [
          TodayDoseModel(
            scheduleId: 'sched-1',
            medicationId: 'med-1',
            medicationName: 'Concor 5mg',
            timeOfDay: '08:00',
            doseAmount: 1,
            mealRelation: 'after_meal',
            status: 'pending',
            instructionsAr: 'بعد الفطار',
          ),
        ],
      );

      when(() => repository.logAdherence(any())).thenAnswer(
        (_) async => IntakeLogModel(
          id: 'log-1',
          clientUuid: 'uuid-1',
          scheduleId: 'sched-1',
          patientId: 'patient-1',
          scheduledTime: DateTime.utc(2026, 10, 23, 8),
          actualTime: DateTime.utc(2026, 10, 23, 8, 5),
          status: 'taken',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPatientIdProvider.overrideWithValue('patient-1'),
            medicationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TodayScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Concor 5mg'), findsOneWidget);
      expect(find.text('قيد الانتظار'), findsOneWidget);
      expect(find.byKey(const ValueKey('take_btn_sched-1')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('take_btn_sched-1')));
      await tester.pumpAndSettle();

      expect(find.text('تم التناول'), findsOneWidget);
      expect(find.byKey(const ValueKey('take_btn_sched-1')), findsNothing);
      verify(() => repository.logAdherence(any())).called(1);
    },
  );

  testWidgets('missed dose can still be recorded as taken late', (
    tester,
  ) async {
    when(() => repository.getTodayDoses('patient-1')).thenAnswer(
      (_) async => const [
        TodayDoseModel(
          scheduleId: 'sched-missed',
          medicationId: 'med-1',
          medicationName: 'Concor 5mg',
          timeOfDay: '08:00',
          doseAmount: 1,
          mealRelation: 'after_meal',
          status: 'missed',
        ),
      ],
    );
    when(() => repository.logAdherence(any())).thenAnswer((invocation) async {
      final input =
          invocation.positionalArguments.single as IntakeLogCreateInput;
      return IntakeLogModel(
        id: 'log-1',
        clientUuid: input.clientUuid,
        scheduleId: input.scheduleId,
        patientId: 'patient-1',
        scheduledTime: input.scheduledTime,
        actualTime: input.actualTime,
        status: input.status,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          medicationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TodayScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final takeButton = find.byKey(const ValueKey('take_btn_sched-missed'));
    await tester.ensureVisible(takeButton);
    await tester.tap(takeButton);
    await tester.pumpAndSettle();

    final captured = verify(() => repository.logAdherence(captureAny()))
        .captured;
    final input = captured.single as IntakeLogCreateInput;
    expect(input.scheduleId, 'sched-missed');
    expect(input.status, 'taken');
    expect(find.text('تم التناول'), findsOneWidget);
  });
}
