import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class MedicationsNotifier extends AsyncNotifier<List<MedicationModel>> {
  @override
  Future<List<MedicationModel>> build() async {
    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      return const [];
    }
    final repo = ref.watch(medicationRepositoryProvider);
    return await repo.listMedications(patientId);
  }

  Future<void> deleteMedication(String medicationId) async {
    final current = state.value ?? const [];
    final existing = current.where((m) => m.id == medicationId).firstOrNull;
    final repo = ref.read(medicationRepositoryProvider);
    await repo.deleteMedication(medicationId);

    if (existing != null) {
      final reminderService = ref.read(localReminderServiceProvider);
      for (final schedule in existing.schedules) {
        await reminderService.cancelScheduleReminders(schedule.id);
      }
    }

    state = AsyncValue.data(
      current.where((m) => m.id != medicationId).toList(),
    );
    ref
      ..invalidate(todayDosesNotifierProvider)
      ..invalidate(inventoryForecastProvider);
  }

  Future<MedicationModel> createMedication(MedicationCreateInput input) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      throw StateError('No active patient selected');
    }
    final repo = ref.read(medicationRepositoryProvider);
    final created = await repo.createMedication(patientId, input);
    final current = state.value ?? const [];
    state = AsyncValue.data([...current, created]);
    ref
      ..invalidate(todayDosesNotifierProvider)
      ..invalidate(inventoryForecastProvider);
    return created;
  }

  Future<MedicationModel> updateMedication(
    String medicationId,
    MedicationUpdateInput input,
  ) async {
    final repo = ref.read(medicationRepositoryProvider);
    final updated = await repo.updateMedication(medicationId, input);
    final current = state.value ?? const [];
    state = AsyncValue.data(
      current.map((m) => m.id == medicationId ? updated : m).toList(),
    );
    ref
      ..invalidate(todayDosesNotifierProvider)
      ..invalidate(inventoryForecastProvider);
    return updated;
  }
}

final medicationsNotifierProvider =
    AsyncNotifierProvider<MedicationsNotifier, List<MedicationModel>>(
      MedicationsNotifier.new,
    );

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({
    this.onTapMedication,
    this.onAddMedication,
    this.embedded = false,
    super.key,
  });

  final void Function(MedicationModel medication)? onTapMedication;
  final VoidCallback? onAddMedication;
  final bool embedded;

  String _frequencyLabel(AppLocalizations l10n, int scheduleCount) {
    if (scheduleCount <= 0) return l10n.medicationNoSchedule;
    if (scheduleCount == 1) return l10n.onceDaily;
    if (scheduleCount == 2) return l10n.twiceDaily;
    return l10n.medicationFreqCount(scheduleCount);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MedicationModel medication,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteMedicationTitle),
        content: Text(l10n.deleteMedicationConfirm),
        actions: [
          SizedBox(
            height: 48,
            child: TextButton(
              key: const ValueKey('cancel_delete_med_btn'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              key: const ValueKey('confirm_delete_med_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteButton),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref
            .read(medicationsNotifierProvider.notifier)
            .deleteMedication(medication.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final medsAsync = ref.watch(medicationsNotifierProvider);

    final handleAdd =
        onAddMedication ?? () => context.push('/medications/new');

    final body = medsAsync.when(
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(medicationsNotifierProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (medications) {
        if (medications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(medicationsNotifierProvider);
              await ref.read(medicationsNotifierProvider.future);
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.noMedicationsYet,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: handleAdd,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n.addMedicationTitle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(medicationsNotifierProvider);
            await ref.read(medicationsNotifierProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsetsDirectional.fromSTEB(
              16,
              16,
              16,
              embedded ? 96 : 16,
            ),
            itemCount: medications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final med = medications[index];
              final subtitleParts = <String>[
                if (med.strength != null && med.strength!.isNotEmpty)
                  med.strength!,
                med.form,
              ];
              final stock = med.stockCount;
              final dailyDose = med.schedules.fold<double>(0, (sum, s) {
                final daysPerWeek = countDaysInMask(s.daysMask);
                return sum + (s.doseAmount * (daysPerWeek / 7.0));
              });
              final daysLeft = dailyDose > 0
                  ? (stock / dailyDose).floor()
                  : null;
              final isLowStock = daysLeft != null
                  ? daysLeft <= med.alertThresholdDays
                  : stock <= med.alertThresholdDays;
              final isMedStock = !isLowStock &&
                  (daysLeft != null
                      ? daysLeft <= med.alertThresholdDays + 4
                      : stock <= med.alertThresholdDays + 5);

              final stockText = isLowStock
                  ? l10n.stockLowBadge
                  : isMedStock
                      ? l10n.stockRemainingPillsBadge(stock)
                      : l10n.stockAvailableBadge;
              final stockIcon = isLowStock
                  ? Icons.warning_amber_rounded
                  : isMedStock
                      ? Icons.inventory_2_outlined
                      : Icons.check_circle_rounded;
              final stockBg = isLowStock
                  ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFFEBEE))
                  : isMedStock
                      ? (isDark
                          ? const Color(0xFF45220A)
                          : const Color(0xFFFFF8E1))
                      : (isDark
                          ? const Color(0xFF14532D)
                          : const Color(0xFFE8F5E9));
              final stockFg = isLowStock
                  ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC62828))
                  : isMedStock
                      ? (isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFB45309))
                      : (isDark
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF2E7D32));

              final parsedExpiry = med.expiryDate != null
                  ? DateTime.tryParse(med.expiryDate!)
                  : null;
              final expiryOnly = parsedExpiry == null
                  ? null
                  : DateTime(
                      parsedExpiry.year,
                      parsedExpiry.month,
                      parsedExpiry.day,
                    );
              final isExpired =
                  expiryOnly != null && expiryOnly.isBefore(todayDate);
              final isExpiringSoon =
                  expiryOnly != null &&
                  !isExpired &&
                  !expiryOnly.isAfter(todayDate.add(const Duration(days: 30)));

              final times = med.schedules.map((s) => s.timeOfDay).toList();
              final freqLabel = _frequencyLabel(l10n, med.schedules.length);

              return Card(
                key: ValueKey('med_card_${med.id}'),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTapMedication != null
                      ? () => onTapMedication!(med)
                      : () =>
                          context.push('/medications/${med.id}', extra: med),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.medication_rounded,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${subtitleParts.join(' • ')} • $freqLabel',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: ValueKey('delete_med_btn_${med.id}'),
                              tooltip: l10n.deleteMedicationTitle,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700,
                                size: 26,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, ref, med),
                            ),
                            Icon(
                              isRtl
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final t in times)
                                  Container(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(
                                              0xFF075985,
                                            ).withValues(alpha: 0.4)
                                          : const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF7DD3FC)
                                            : const Color(0xFF0369A1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (isExpired || isExpiringSoon)
                                  Container(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                    decoration: BoxDecoration(
                                      color: isExpired
                                          ? (isDark
                                              ? const Color(0xFF450A0A)
                                              : const Color(0xFFFFEBEE))
                                          : (isDark
                                              ? const Color(0xFF45220A)
                                              : const Color(0xFFFFF8E1)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.event_busy_rounded,
                                          size: 18,
                                          color: isExpired
                                              ? (isDark
                                                  ? const Color(0xFFFCA5A5)
                                                  : const Color(0xFFC62828))
                                              : (isDark
                                                  ? const Color(0xFFFDE68A)
                                                  : const Color(0xFFB45309)),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isExpired
                                              ? l10n.expiredBadge
                                              : l10n.expiringSoonBadge,
                                          style: TextStyle(
                                            color: isExpired
                                                ? (isDark
                                                    ? const Color(0xFFFCA5A5)
                                                    : const Color(0xFFC62828))
                                                : (isDark
                                                    ? const Color(0xFFFDE68A)
                                                    : const Color(0xFFB45309)),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                  decoration: BoxDecoration(
                                    color: stockBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(stockIcon, size: 18, color: stockFg),
                                      const SizedBox(width: 6),
                                      Text(
                                        stockText,
                                        style: TextStyle(
                                          color: stockFg,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (embedded) {
      return Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('add_medication_action_btn'),
          onPressed: handleAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addMedicationTitle),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationsTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: IconButton(
              key: const ValueKey('add_medication_action_btn'),
              tooltip: l10n.addMedicationTitle,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
              onPressed: handleAdd,
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
