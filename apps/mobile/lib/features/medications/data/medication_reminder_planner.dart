import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PlannedReminder {
  const PlannedReminder({
    required this.notificationId,
    required this.scheduleId,
    required this.medicationName,
    required this.scheduledAt,
    required this.attemptIndex,
    this.fullScreenIntent = true,
  });

  final int notificationId;
  final String scheduleId;
  final String medicationName;
  final DateTime scheduledAt;
  final int attemptIndex; // 0 = initial, 1..3 = 5-min repeats
  final bool fullScreenIntent;
}

/// Localized text used by the medication reminder notifications.
class ReminderCopy {
  const ReminderCopy({
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  /// Fallback copy used when no localized copy is supplied.
  static const fallback = ReminderCopy(
    body: 'موعد تناول الجرعة الآن',
    channelName: 'منبهات الأدوية',
    channelDescription: 'تنبيهات مواعيد جرعات الأدوية لكبار السن',
  );

  final String body;
  final String channelName;
  final String channelDescription;
}

class MedicationReminderPlanner {
  const MedicationReminderPlanner({
    this.repeatInterval = const Duration(minutes: 5),
    this.maxRepeats = 3,
  });

  final Duration repeatInterval;
  final int maxRepeats;

  List<PlannedReminder> buildReminders({
    required List<TodayDoseModel> doses,
    required DateTime referenceDate,
  }) {
    final planned = <PlannedReminder>[];

    for (var i = 0; i < doses.length; i++) {
      final dose = doses[i];
      if (dose.status == 'taken' || dose.status == 'skipped') {
        continue;
      }

      final parts = dose.timeOfDay.split(':');
      final hour = int.tryParse(parts.first) ?? 8;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      final baseTime = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        hour,
        minute,
      );

      final baseId = (dose.scheduleId.hashCode.abs() % 100000) * 10;

      for (var attempt = 0; attempt <= maxRepeats; attempt++) {
        final scheduledAt = baseTime.add(repeatInterval * attempt);
        planned.add(
          PlannedReminder(
            notificationId: baseId + attempt,
            scheduleId: dose.scheduleId,
            medicationName: dose.medicationName,
            scheduledAt: scheduledAt,
            attemptIndex: attempt,
          ),
        );
      }
    }

    return planned;
  }

  List<int> notificationIdsForSchedule(String scheduleId) {
    final baseId = (scheduleId.hashCode.abs() % 100000) * 10;
    return [
      for (var attempt = 0; attempt <= maxRepeats; attempt++) baseId + attempt,
    ];
  }
}

class LocalReminderService {
  LocalReminderService({
    FlutterLocalNotificationsPlugin? plugin,
    MedicationReminderPlanner planner = const MedicationReminderPlanner(),
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _planner = planner;

  final FlutterLocalNotificationsPlugin _plugin;
  final MedicationReminderPlanner _planner;
  bool _initialized = false;

  /// Whether the platform plugin is ready. While this is false every
  /// scheduling call is a safe no-op so widget tests (and platforms without
  /// notification support) never touch a platform channel.
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: settings);
      await _requestAndroidPermissions();
      _initialized = true;
    } catch (_) {
      // Reminders are a convenience, not a requirement: if the platform
      // channel is unavailable the app must keep working without them.
      _initialized = false;
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
  }

  Future<void> rescheduleForToday(
    List<TodayDoseModel> doses, {
    DateTime? now,
    ReminderCopy copy = ReminderCopy.fallback,
  }) async {
    if (!_initialized) return;

    final refNow = now ?? DateTime.now();
    final reminders = _planner.buildReminders(
      doses: doses,
      referenceDate: refNow,
    );

    await _ignoreFailure(_plugin.cancelAll);

    final androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      copy.channelName,
      channelDescription: copy.channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );
    final details = NotificationDetails(android: androidDetails);

    for (final reminder in reminders) {
      if (!reminder.scheduledAt.isAfter(refNow)) continue;
      await _ignoreFailure(
        () => _plugin.zonedSchedule(
          id: reminder.notificationId,
          title: reminder.medicationName,
          body: copy.body,
          scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        ),
      );
    }
  }

  Future<void> cancelScheduleReminders(String scheduleId) async {
    if (!_initialized) return;
    for (final id in _planner.notificationIdsForSchedule(scheduleId)) {
      await _ignoreFailure(() => _plugin.cancel(id: id));
    }
  }

  /// Runs a platform call and swallows its failures so a broken notification
  /// channel can never break the medication flow.
  Future<void> _ignoreFailure(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Intentionally ignored.
    }
  }
}

final localReminderServiceProvider = Provider<LocalReminderService>((ref) {
  return LocalReminderService();
});
