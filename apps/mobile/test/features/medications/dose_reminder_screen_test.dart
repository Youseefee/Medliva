import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/dose_reminder_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

void main() {
  late MockMedicationRepository repository;

  const dose = TodayDoseModel(
    scheduleId: 'sched-1',
    medicationId: 'med-1',
    medicationName: 'Concor 5mg',
    timeOfDay: '08:00',
    doseAmount: 1,
    mealRelation: 'after_meal',
    status: 'pending',
  );

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
    when(() => repository.getTodayDoses(any()))
        .thenAnswer((_) async => const [dose]);
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
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentPatientIdProvider.overrideWithValue('patient-1'),
        medicationRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open_reminder'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DoseReminderScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openReminder(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open_reminder')));
    await tester.pumpAndSettle();
  }

  testWidgets('DoseReminderScreen shows the pending dose of the day', (
    tester,
  ) async {
    await openReminder(tester);

    expect(find.text('Concor 5mg'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder_take_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder_snooze_btn')), findsOneWidget);
  });

  testWidgets('tapping the take button logs the dose as taken and pops', (
    tester,
  ) async {
    await openReminder(tester);

    await tester.tap(find.byKey(const ValueKey('reminder_take_btn')));
    await tester.pumpAndSettle();

    final captured = verify(() => repository.logAdherence(captureAny()))
        .captured;
    final input = captured.single as IntakeLogCreateInput;
    expect(input.scheduleId, 'sched-1');
    expect(input.status, 'taken');

    // The screen popped back to the opener.
    expect(find.byKey(const ValueKey('open_reminder')), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder_take_btn')), findsNothing);
  });

  testWidgets('tapping the snooze button logs the dose as snoozed and pops', (
    tester,
  ) async {
    await openReminder(tester);

    await tester.tap(find.byKey(const ValueKey('reminder_snooze_btn')));
    await tester.pumpAndSettle();

    final captured = verify(() => repository.logAdherence(captureAny()))
        .captured;
    final input = captured.single as IntakeLogCreateInput;
    expect(input.scheduleId, 'sched-1');
    expect(input.status, 'snoozed');

    expect(find.byKey(const ValueKey('open_reminder')), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder_snooze_btn')), findsNothing);
  });

  testWidgets('does not offer a reminder for an already completed dose', (
    tester,
  ) async {
    const completedDose = TodayDoseModel(
      scheduleId: 'sched-1',
      medicationId: 'med-1',
      medicationName: 'Concor 5mg',
      timeOfDay: '08:00',
      doseAmount: 1,
      mealRelation: 'after_meal',
      status: 'taken',
    );
    when(() => repository.getTodayDoses(any()))
        .thenAnswer((_) async => const [completedDose]);

    await openReminder(tester);

    expect(find.text('لا توجد جرعة معلّقة الآن'), findsOneWidget);
    expect(find.text('Concor 5mg'), findsNothing);
    expect(find.byKey(const ValueKey('reminder_take_btn')), findsNothing);
    expect(find.byKey(const ValueKey('reminder_snooze_btn')), findsNothing);
    verifyNever(() => repository.logAdherence(any()));
  });

  testWidgets('a snoozed dose remains available to take', (tester) async {
    const snoozedDose = TodayDoseModel(
      scheduleId: 'sched-1',
      medicationId: 'med-1',
      medicationName: 'Concor 5mg',
      timeOfDay: '08:00',
      doseAmount: 1,
      mealRelation: 'after_meal',
      status: 'snoozed',
    );
    when(() => repository.getTodayDoses(any()))
        .thenAnswer((_) async => const [snoozedDose]);

    await openReminder(tester);
    await tester.tap(find.byKey(const ValueKey('reminder_take_btn')));
    await tester.pumpAndSettle();

    final captured = verify(() => repository.logAdherence(captureAny()))
        .captured;
    final input = captured.single as IntakeLogCreateInput;
    expect(input.scheduleId, 'sched-1');
    expect(input.status, 'taken');
  });
}
