import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/data/offline_adherence_queue.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/l10n/app_localizations.dart';

class TodayDosesNotifier extends AsyncNotifier<List<TodayDoseModel>> {
  @override
  Future<List<TodayDoseModel>> build() async {
    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      return const [];
    }
    final repo = ref.watch(medicationRepositoryProvider);
    final doses = await repo.getTodayDoses(patientId);
    await _rescheduleReminders(doses);
    return doses;
  }

  /// Re-plans the local reminders so the device notifications always match
  /// the doses shown on screen. The service itself is a safe no-op when the
  /// notification plugin is not initialized (tests, unsupported platforms).
  Future<void> _rescheduleReminders(List<TodayDoseModel> doses) async {
    if (doses.isEmpty) return;
    final service = ref.read(localReminderServiceProvider);

    final language = ref.read(authNotifierProvider).value?.language;
    final l10n = lookupAppLocalizations(Locale(language == 'en' ? 'en' : 'ar'));

    await service.rescheduleForToday(
      doses,
      copy: ReminderCopy(
        body: l10n.reminderNotificationBody,
        channelName: l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
      ),
    );
  }

  Future<void> logDose({
    required TodayDoseModel dose,
    required String status,
  }) async {
    final repo = ref.read(medicationRepositoryProvider);
    final now = DateTime.now().toUtc();
    final timeParts = dose.timeOfDay.split(':');
    final hour = int.tryParse(timeParts.first) ?? 8;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    final scheduledTime = DateTime.utc(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final clientUuid =
        '${dose.scheduleId}-${now.millisecondsSinceEpoch}-$status';

    final input = IntakeLogCreateInput(
      clientUuid: clientUuid,
      scheduleId: dose.scheduleId,
      scheduledTime: scheduledTime,
      actualTime: now,
      status: status,
    );

    IntakeLogModel? log;
    try {
      log = await repo.logAdherence(input);
    } catch (_) {
      final queue = ref.read(offlineAdherenceQueueProvider);
      await queue.logWithOfflineFallback(input);
    }

    final currentList = state.value ?? const [];
    state = AsyncValue.data(
      currentList
          .map(
            (item) => item.scheduleId == dose.scheduleId
                ? item.copyWith(
                    status: log?.status ?? status,
                    intakeLogId: log?.id ?? 'offline-$clientUuid',
                    actualTime: log?.actualTime ?? now,
                  )
                : item,
          )
          .toList(),
    );

    // Stop the local reminders once the dose is handled so the patient is
    // not notified again for a dose that is already taken or skipped.
    if (status == 'taken' || status == 'skipped') {
      await ref
          .read(localReminderServiceProvider)
          .cancelScheduleReminders(dose.scheduleId);
    }
  }
}

final todayDosesNotifierProvider =
    AsyncNotifierProvider<TodayDosesNotifier, List<TodayDoseModel>>(
  TodayDosesNotifier.new,
);

class TodayScreen extends ConsumerWidget {
  const TodayScreen({
    this.readOnly = false,
    super.key,
  });

  final bool readOnly;

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'taken':
        return l10n.statusTaken;
      case 'skipped':
        return l10n.statusSkipped;
      case 'missed':
        return l10n.statusMissed;
      case 'snoozed':
        return l10n.statusSnoozed;
      default:
        return l10n.statusPending;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle_rounded;
      case 'skipped':
        return Icons.remove_circle_outline_rounded;
      case 'missed':
        return Icons.error_rounded;
      case 'snoozed':
        return Icons.snooze_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'taken':
        return Colors.green.shade800;
      case 'skipped':
        return Colors.orange.shade800;
      case 'missed':
        return Colors.red.shade800;
      default:
        return Colors.teal.shade800;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dosesAsync = ref.watch(todayDosesNotifierProvider);

    return dosesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                err.toString(),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => ref.invalidate(todayDosesNotifierProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (doses) {
        if (doses.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.medication_liquid_rounded,
                    size: 56,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noDosesToday,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsetsDirectional.all(16),
          itemCount: doses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final dose = doses[index];
            final statusColor = _statusColor(dose.status);
            final doseAmountStr = dose.doseAmount % 1 == 0
                ? dose.doseAmount.toInt().toString()
                : dose.doseAmount.toString();

            return Card(
              key: ValueKey('dose_card_${dose.scheduleId}'),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medication_rounded,
                          size: 36,
                          color: Color(0xFF00796B),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dose.medicationName,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.doseAmountLabel(doseAmountStr)} • ${dose.timeOfDay}',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon(dose.status),
                                color: statusColor,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _statusLabel(l10n, dose.status),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (dose.instructionsAr != null &&
                        dose.instructionsAr!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        dose.instructionsAr!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (!readOnly && dose.status == 'pending') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                key: ValueKey('take_btn_${dose.scheduleId}'),
                                onPressed: () => ref
                                    .read(todayDosesNotifierProvider.notifier)
                                    .logDose(dose: dose, status: 'taken'),
                                icon: const Icon(Icons.check_rounded),
                                label: Text(l10n.takeDoseButton),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton.icon(
                                key: ValueKey('skip_btn_${dose.scheduleId}'),
                                onPressed: () => ref
                                    .read(todayDosesNotifierProvider.notifier)
                                    .logDose(dose: dose, status: 'skipped'),
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.skipDoseButton),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (dose.status == 'missed') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsetsDirectional.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.escalationReminder15m,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.group_rounded,
                                  color: Color(0xFFEA580C),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.escalationFamily30m,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Colors.red.shade800,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.escalationDoctor60m,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
