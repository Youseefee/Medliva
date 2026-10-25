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
    final patientsAsync = ref.watch(linkedPatientsProvider);

    return patientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(err.toString(), style: theme.textTheme.bodyLarge),
        ),
      ),
      data: (patients) {
        if (patients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(24),
              child: Text(
                l10n.noLinkedPatients,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (ref.read(selectedPatientIdProvider) == null &&
            patients.isNotEmpty) {
          unawaited(
            Future.microtask(() {
              ref
                  .read(selectedPatientIdProvider.notifier)
                  .selectPatient(patients.first.patientId);
            }),
          );
        }

        return ListView.separated(
          padding: const EdgeInsetsDirectional.all(16),
          itemCount: patients.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final patient = patients[index];
            final displayName = patient.name ?? patient.phone ?? patient.patientId;
            final alertsCount = patient.activeAlertsCount > 0
                ? patient.activeAlertsCount
                : patient.todayMissedCount;

            return Card(
              key: ValueKey('patient_card_${patient.patientId}'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
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
                leading: const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFF00796B),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                title: Text(
                  displayName,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: Colors.green,
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
                ),
                trailing: alertsCount > 0
                    ? Container(
                        key: ValueKey('alert_badge_${patient.patientId}'),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: Colors.red.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.alertsBadgeLabel(alertsCount),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 22),
              ),
            );
          },
        );
      },
    );
  }
}
