import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/data/offline_adherence_queue.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:medliva/main.dart';

class TodayDosesNotifier extends AsyncNotifier<List<TodayDoseModel>> {
  @override
  Future<List<TodayDoseModel>> build() async {
    final patientId = ref.watch(currentPatientIdProvider);
    final playSound = ref.watch(reminderSoundProvider);
    if (patientId == null || patientId.isEmpty) {
      return const [];
    }

    final repo = ref.watch(medicationRepositoryProvider);
    final doses = await repo.getTodayDoses(patientId);
    await _rescheduleReminders(doses, playSound: playSound);
    unawaited(_flushOfflineQueue());
    return doses;
  }

  Future<void> _flushOfflineQueue() async {
    try {
      final synced = await ref.read(offlineAdherenceQueueProvider).flushQueue();
      if (synced > 0) {
        ref
          ..invalidateSelf()
          ..invalidate(medicationsNotifierProvider)
          ..invalidate(inventoryForecastProvider);
      }
    } catch (_) {
      // Non-fatal: queued doses will retry on next connectivity change.
    }
  }

  ReminderCopy _reminderCopy() {
    final language = ref.read(authNotifierProvider).value?.language;
    final l10n = lookupAppLocalizations(Locale(language == 'en' ? 'en' : 'ar'));
    return ReminderCopy(
      body: l10n.reminderNotificationBody,
      channelName: l10n.reminderChannelName,
      channelDescription: l10n.reminderChannelDescription,
    );
  }

  /// Re-plans the local reminders so the device notifications always match
  /// the doses shown on screen. Even when [doses] is empty, this cancels stale
  /// reminders cleanly.
  Future<void> _rescheduleReminders(
    List<TodayDoseModel> doses, {
    required bool playSound,
  }) async {
    final service = ref.read(localReminderServiceProvider);
    await service.rescheduleForToday(
      doses,
      copy: _reminderCopy(),
      playSound: playSound,
    );
  }

  /// Logs a dose and returns `true` if synced online, `false` if queued offline.
  Future<bool> logDose({
    required TodayDoseModel dose,
    required String status,
  }) async {
    final nowLocal = DateTime.now();
    final nowUtc = nowLocal.toUtc();
    final timeParts = dose.timeOfDay.split(':');
    final hour = int.tryParse(timeParts.first) ?? 8;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    final scheduledTime = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      hour,
      minute,
    ).toUtc();

    final clientUuid =
        '${dose.scheduleId}-${nowUtc.millisecondsSinceEpoch}-$status';

    final input = IntakeLogCreateInput(
      clientUuid: clientUuid,
      scheduleId: dose.scheduleId,
      scheduledTime: scheduledTime,
      actualTime: nowUtc,
      status: status,
    );

    final repo = ref.read(medicationRepositoryProvider);
    IntakeLogModel? log;
    var synced = false;
    try {
      log = await repo.logAdherence(input);
      synced = true;
    } catch (_) {
      await ref.read(offlineAdherenceQueueProvider).enqueue(input);
    }

    final currentList = state.value ?? const [];
    state = AsyncValue.data(
      currentList
          .map(
            (item) => item.scheduleId == dose.scheduleId
                ? item.copyWith(
                    status: log?.status ?? status,
                    intakeLogId: log?.id ?? 'offline-$clientUuid',
                    actualTime: log?.actualTime ?? nowUtc,
                  )
                : item,
          )
          .toList(),
    );

    final reminderService = ref.read(localReminderServiceProvider);
    if (status == 'taken' || status == 'skipped') {
      await reminderService.cancelScheduleReminders(dose.scheduleId);
    } else if (status == 'snoozed') {
      await reminderService.scheduleSnoozeReminder(
        dose: dose,
        copy: _reminderCopy(),
        playSound: ref.read(reminderSoundProvider),
      );
    }

    if (status == 'taken' && synced) {
      ref
        ..invalidate(medicationsNotifierProvider)
        ..invalidate(inventoryForecastProvider);
    }

    return synced;
  }
}

final todayDosesNotifierProvider =
    AsyncNotifierProvider<TodayDosesNotifier, List<TodayDoseModel>>(
      TodayDosesNotifier.new,
    );

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({this.readOnly = false, super.key});

  final bool readOnly;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final Set<String> _submittingScheduleIds = <String>{};

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

  String _mealLabel(AppLocalizations l10n, String mealRelation) {
    switch (mealRelation) {
      case 'before_meal':
        return l10n.mealBefore;
      case 'with_meal':
        return l10n.mealWith;
      case 'independent':
        return l10n.mealAnytime;
      default:
        return l10n.mealAfter;
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

  Color _statusColor(String status, [Brightness brightness = Brightness.light]) {
    final isDark = brightness == Brightness.dark;
    switch (status) {
      case 'taken':
        return isDark ? Colors.green.shade300 : Colors.green.shade800;
      case 'skipped':
        return isDark ? Colors.amber.shade300 : Colors.orange.shade800;
      case 'missed':
        return isDark ? Colors.red.shade300 : Colors.red.shade800;
      default:
        return isDark ? Colors.tealAccent.shade200 : Colors.teal.shade800;
    }
  }

  Future<void> _handleLogDose(TodayDoseModel dose, String status) async {
    if (_submittingScheduleIds.contains(dose.scheduleId)) return;
    setState(() => _submittingScheduleIds.add(dose.scheduleId));
    try {
      final synced = await ref
          .read(todayDosesNotifierProvider.notifier)
          .logDose(dose: dose, status: status);
      if (!mounted) return;
      if (!synced) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.doseLoggedOffline)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingScheduleIds.remove(dose.scheduleId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dosesAsync = ref.watch(todayDosesNotifierProvider);

    return dosesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todayDosesNotifierProvider);
              await ref.read(todayDosesNotifierProvider.future);
            },
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsetsDirectional.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medication_liquid_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.noDosesToday,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  GoRouter.maybeOf(context)?.push(
                                    '/medications/new',
                                  ),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(l10n.addMedicationTitle),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayDosesNotifierProvider);
            await ref.read(todayDosesNotifierProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.all(16),
            itemCount: doses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final dose = doses[index];
              final statusColor = _statusColor(dose.status, theme.brightness);
              final isSubmitting =
                  _submittingScheduleIds.contains(dose.scheduleId);
              final doseAmountStr = dose.doseAmount % 1 == 0
                  ? dose.doseAmount.toInt().toString()
                  : dose.doseAmount.toString();

              return Card(
                key: ValueKey('dose_card_${dose.scheduleId}'),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.medication_rounded,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      dose.medicationName,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: isDark ? 0.20 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _statusIcon(dose.status),
                                            color: statusColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _statusLabel(l10n, dose.status),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${l10n.doseAmountLabel(doseAmountStr)} • ${dose.timeOfDay}',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant_rounded,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _mealLabel(l10n, dose.mealRelation),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
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
                      if (!widget.readOnly && dose.isActionable) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 54,
                                minWidth: 132,
                              ),
                              child: ElevatedButton.icon(
                                key: ValueKey('take_btn_${dose.scheduleId}'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 54),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () => _handleLogDose(dose, 'taken'),
                                icon: isSubmitting
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded),
                                label: Text(l10n.takeDoseButton),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 54,
                                minWidth: 112,
                              ),
                              child: OutlinedButton.icon(
                                key: ValueKey('skip_btn_${dose.scheduleId}'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 54),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () => _handleLogDose(dose, 'skipped'),
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.skipDoseButton),
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
                            color: isDark
                                ? const Color(0xFF450A0A)
                                : Colors.red.shade50,
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.red.shade200
                                                : null,
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.red.shade200
                                                : null,
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
                                    color: isDark
                                        ? Colors.red.shade300
                                        : Colors.red.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.escalationDoctor60m,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.red.shade200
                                                : Colors.red.shade900,
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
          ),
        );
      },
    );
  }
}
