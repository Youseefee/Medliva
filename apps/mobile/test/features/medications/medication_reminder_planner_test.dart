import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';

void main() {
  group('MedicationReminderPlanner', () {
    const planner = MedicationReminderPlanner();
    final refDate = DateTime(2026, 10, 23, 7);

    test(
        'schedules initial reminder + 3 repeats every 5 min with fullScreenIntent for pending doses',
        () {
      const doses = [
        TodayDoseModel(
          scheduleId: 'sched-1',
          medicationId: 'med-1',
          medicationName: 'Concor 5mg',
          timeOfDay: '08:30',
          doseAmount: 1,
          mealRelation: 'after_meal',
          status: 'pending',
        ),
      ];

      final reminders = planner.buildReminders(
        doses: doses,
        referenceDate: refDate,
      );

      expect(reminders, hasLength(4));
      expect(reminders[0].attemptIndex, 0);
      expect(reminders[0].scheduledAt, DateTime(2026, 10, 23, 8, 30));
      expect(reminders[1].attemptIndex, 1);
      expect(reminders[1].scheduledAt, DateTime(2026, 10, 23, 8, 35));
      expect(reminders[2].attemptIndex, 2);
      expect(reminders[2].scheduledAt, DateTime(2026, 10, 23, 8, 40));
      expect(reminders[3].attemptIndex, 3);
      expect(reminders[3].scheduledAt, DateTime(2026, 10, 23, 8, 45));
      expect(reminders.every((r) => r.fullScreenIntent), isTrue);
    });

    test('skips taken and skipped doses when rescheduling', () {
      const doses = [
        TodayDoseModel(
          scheduleId: 'sched-1',
          medicationId: 'med-1',
          medicationName: 'Concor 5mg',
          timeOfDay: '08:30',
          doseAmount: 1,
          mealRelation: 'after_meal',
          status: 'taken',
        ),
        TodayDoseModel(
          scheduleId: 'sched-2',
          medicationId: 'med-2',
          medicationName: 'Glucophage',
          timeOfDay: '14:00',
          doseAmount: 1,
          mealRelation: 'after_meal',
          status: 'skipped',
        ),
        TodayDoseModel(
          scheduleId: 'sched-3',
          medicationId: 'med-3',
          medicationName: 'Aspirin',
          timeOfDay: '20:00',
          doseAmount: 1,
          mealRelation: 'after_meal',
          status: 'pending',
        ),
      ];

      final reminders = planner.buildReminders(
        doses: doses,
        referenceDate: refDate,
      );

      expect(reminders, hasLength(4));
      expect(reminders.every((r) => r.scheduleId == 'sched-3'), isTrue);
    });

    test('notificationIdsForSchedule returns all 4 notification IDs for cancellation',
        () {
      final ids = planner.notificationIdsForSchedule('sched-1');
      expect(ids, hasLength(4));
      expect(ids.toSet(), hasLength(4));
    });
  });
}
