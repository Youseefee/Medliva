import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

/// Records every reminder call instead of touching the platform channel.
class RecordingReminderService extends LocalReminderService {
  final List<List<TodayDoseModel>> rescheduled = [];
  final List<String> cancelledScheduleIds = [];

  @override
  Future<void> rescheduleForToday(
    List<TodayDoseModel> doses, {
    DateTime? now,
    ReminderCopy copy = ReminderCopy.fallback,
  }) async {
    rescheduled.add(doses);
  }

  @override
  Future<void> cancelScheduleReminders(String scheduleId) async {
    cancelledScheduleIds.add(scheduleId);
  }
}

void main() {
  late MockMedicationRepository repository;
  late RecordingReminderService reminderService;

  const doses = [
    TodayDoseModel(
      scheduleId: 'sched-1',
      medicationId: 'med-1',
      medicationName: 'Concor 5mg',
      timeOfDay: '08:00',
      doseAmount: 1,
      mealRelation: 'after_meal',
      status: 'pending',
    ),
  ];

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
    reminderService = RecordingReminderService();

    when(() => repository.getTodayDoses('patient-1')).thenAnswer(
      (_) async => doses,
    );
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentPatientIdProvider.overrideWithValue('patient-1'),
        medicationRepositoryProvider.overrideWithValue(repository),
        localReminderServiceProvider.overrideWithValue(reminderService),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TodayScreen()),
      ),
    );
  }

  testWidgets('loading today doses reschedules the local reminders',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(reminderService.rescheduled, hasLength(1));
    expect(reminderService.rescheduled.first, hasLength(1));
    expect(reminderService.rescheduled.first.first.scheduleId, 'sched-1');
    expect(reminderService.cancelledScheduleIds, isEmpty);
  });

  testWidgets('marking a dose as taken cancels its local reminders',
      (tester) async {
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

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('take_btn_sched-1')));
    await tester.pumpAndSettle();

    expect(reminderService.cancelledScheduleIds, ['sched-1']);
  });

  testWidgets('skipping a dose cancels its local reminders', (tester) async {
    when(() => repository.logAdherence(any())).thenAnswer(
      (_) async => IntakeLogModel(
        id: 'log-2',
        clientUuid: 'uuid-2',
        scheduleId: 'sched-1',
        patientId: 'patient-1',
        scheduledTime: DateTime.utc(2026, 10, 23, 8),
        actualTime: DateTime.utc(2026, 10, 23, 8, 6),
        status: 'skipped',
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('skip_btn_sched-1')));
    await tester.pumpAndSettle();

    expect(reminderService.cancelledScheduleIds, ['sched-1']);
  });
}
