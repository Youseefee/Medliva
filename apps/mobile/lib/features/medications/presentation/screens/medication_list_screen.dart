import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
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
    final repo = ref.read(medicationRepositoryProvider);
    await repo.deleteMedication(medicationId);
    final current = state.value ?? const [];
    state = AsyncValue.data(
      current.where((m) => m.id != medicationId).toList(),
    );
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
    super.key,
  });

  final void Function(MedicationModel medication)? onTapMedication;
  final VoidCallback? onAddMedication;

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
    final medsAsync = ref.watch(medicationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationsTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: IconButton(
              key: const ValueKey('add_medication_action_btn'),
              tooltip: l10n.addMedicationTitle,
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF0284C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
              onPressed:
                  onAddMedication ?? () => context.push('/medications/new'),
            ),
          ),
        ],
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(err.toString(), style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
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
            return Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(24),
                child: Text(
                  l10n.noMedicationsYet,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsetsDirectional.all(16),
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
              final isLowStock = stock <= 3;
              final isMedStock = stock > 3 && stock <= 7;
              final stockText = isLowStock
                  ? l10n.stockLowBadge
                  : isMedStock
                      ? l10n.stockRemainingPillsBadge(stock)
                      : l10n.stockAvailableBadge;
              final stockBg = isLowStock
                  ? const Color(0xFFFFEBEE)
                  : isMedStock
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFE8F5E9);
              final stockFg = isLowStock
                  ? const Color(0xFFC62828)
                  : isMedStock
                      ? const Color(0xFFB45309)
                      : const Color(0xFF2E7D32);
              final times = med.schedules.map((s) => s.timeOfDay).toList();
              final freqLabel = med.schedules.length >= 2
                  ? l10n.twiceDaily
                  : l10n.onceDaily;

              return Card(
                key: ValueKey('med_card_${med.id}'),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
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
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.medication_rounded,
                                size: 36,
                                color: Color(0xFF00796B),
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
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red.shade700,
                                size: 26,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, ref, med),
                            ),
                            const Icon(Icons.chevron_right_rounded),
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
                              children: [
                                for (final t in times)
                                  Container(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                        color: Color(0xFF0369A1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: stockBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                stockText,
                                style: TextStyle(
                                  color: stockFg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
