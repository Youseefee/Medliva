import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

final linkedPatientsProvider = FutureProvider<List<LinkedPatientModel>>((ref) {
  final repo = ref.watch(caregiverRepositoryProvider);
  return repo.listLinkedPatients();
});

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final patientsAsync = ref.watch(linkedPatientsProvider);
    final selectedPatientId = ref.watch(selectedPatientIdProvider);

    return patientsAsync.when(
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
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: ElevatedButton.icon(
                  onPressed: () => ref.invalidate(linkedPatientsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (patients) {
        if (patients.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(linkedPatientsProvider.future),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.group_add_rounded,
                              size: 38,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noLinkedPatients,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  ref.invalidate(linkedPatientsProvider),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.retry),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (selectedPatientId == null && patients.isNotEmpty) {
          unawaited(
            Future.microtask(() {
              ref
                  .read(selectedPatientIdProvider.notifier)
                  .selectPatient(patients.first.patientId);
            }),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(linkedPatientsProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final patient = patients[index];
              final displayName = patient.displayName;
              final isSelected = selectedPatientId == patient.patientId;
              final alertsCount = patient.activeAlertsCount > 0
                  ? patient.activeAlertsCount
                  : patient.todayMissedCount;

              return Card(
                key: ValueKey('patient_card_${patient.patientId}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    ref
                        .read(selectedPatientIdProvider.notifier)
                        .selectPatient(patient.patientId);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text(displayName)),
                          body: const TodayScreen(readOnly: true),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: theme.colorScheme.primary,
                              child: Icon(
                                Icons.person_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        displayName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          key: ValueKey(
                                            'selected_badge_${patient.patientId}',
                                          ),
                                          padding:
                                              const EdgeInsetsDirectional.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.caregiverSelectedBadge,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 20,
                                        color: isDark
                                            ? Colors.green.shade300
                                            : Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          l10n.takenMissedSummary(
                                            patient.todayTakenCount,
                                            patient.todayMissedCount,
                                          ),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (alertsCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                key: ValueKey(
                                  'alert_badge_${patient.patientId}',
                                ),
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.red.shade900.withValues(
                                          alpha: 0.5,
                                        )
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.red.shade200
                                          : Colors.red.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.alertsBadgeLabel(alertsCount),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.red.shade200
                                                : Colors.red.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        if (patient.missedDoses.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final dose in patient.missedDoses.take(3))
                                Container(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.red.shade900.withValues(
                                            alpha: 0.35,
                                          )
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.red.shade700.withValues(
                                              alpha: 0.5,
                                            )
                                          : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.medication_rounded,
                                        size: 18,
                                        color: isDark
                                            ? Colors.red.shade200
                                            : Colors.red.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${dose.medicationName} • ${dose.timeOfDay}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.red.shade200
                                                    : Colors.red.shade900,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (patient.missedDoses.length > 3)
                                Container(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    l10n.caregiverMissedCount(
                                      patient.missedDoses.length,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
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
  }
}
