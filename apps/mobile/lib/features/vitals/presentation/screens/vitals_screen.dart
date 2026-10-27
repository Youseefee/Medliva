import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:medliva/l10n/app_localizations.dart';

class VitalsNotifier extends AsyncNotifier<List<VitalReadingModel>> {
  @override
  Future<List<VitalReadingModel>> build() async {
    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      return const [];
    }
    final repo = ref.watch(vitalsRepositoryProvider);
    return await repo.listVitals(patientId);
  }

  Future<VitalReadingModel> addVital(VitalCreateInput input) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      throw StateError('No active patient selected');
    }
    final repo = ref.read(vitalsRepositoryProvider);
    final created = await repo.createVital(patientId, input);
    final current = state.value ?? const [];
    state = AsyncValue.data([created, ...current]);
    return created;
  }
}

final vitalsNotifierProvider =
    AsyncNotifierProvider<VitalsNotifier, List<VitalReadingModel>>(
      VitalsNotifier.new,
    );

class VitalsScreen extends ConsumerStatefulWidget {
  const VitalsScreen({super.key});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  String _selectedType = 'bp';
  bool _isSaving = false;

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'glucose':
        return l10n.vitalTypeGlucose;
      case 'pulse':
        return l10n.vitalTypePulse;
      default:
        return l10n.vitalTypeBp;
    }
  }

  String _bandLabel(AppLocalizations l10n, String band) {
    switch (band) {
      case 'critical':
        return l10n.triageCritical;
      case 'borderline':
        return l10n.triageBorderline;
      default:
        return l10n.triageNormal;
    }
  }

  String _summaryBandLabel(AppLocalizations l10n, String band) {
    switch (band) {
      case 'critical':
        return l10n.highCount;
      case 'borderline':
        return l10n.slightlyHighCount;
      default:
        return l10n.withinNormalCount;
    }
  }

  IconData _bandIcon(String band) {
    switch (band) {
      case 'critical':
        return Icons.dangerous_rounded;
      case 'borderline':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  Color _bandColor(String band) {
    switch (band) {
      case 'critical':
        return Colors.red.shade800;
      case 'borderline':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade800;
    }
  }

  Future<void> _submitManual() async {
    final primaryVal = double.tryParse(_primaryController.text.trim());
    if (primaryVal == null) return;
    final secondaryVal = _selectedType == 'bp'
        ? double.tryParse(_secondaryController.text.trim())
        : null;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(vitalsNotifierProvider.notifier)
          .addVital(
            VitalCreateInput(
              type: _selectedType,
              valuePrimary: primaryVal,
              valueSecondary: secondaryVal,
            ),
          );
      _primaryController.clear();
      _secondaryController.clear();
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vitalsAsync = ref.watch(vitalsNotifierProvider);

    final readings = vitalsAsync.value ?? const [];
    final latestBp = readings.where((r) => r.type == 'bp').firstOrNull;
    final latestGlucose = readings
        .where((r) => r.type == 'glucose')
        .firstOrNull;
    final bpText = latestBp == null
        ? null
        : (latestBp.valueSecondary != null
              ? '${latestBp.valuePrimary.toInt()} / ${latestBp.valueSecondary!.toInt()}'
              : '${latestBp.valuePrimary.toInt()}');
    final glucoseText = latestGlucose == null
        ? null
        : '${latestGlucose.valuePrimary.toInt()}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vitalsTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Manual Entry Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          for (final type in ['bp', 'glucose', 'pulse'])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 4,
                                ),
                                child: Semantics(
                                  selected: _selectedType == type,
                                  button: true,
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      key: ValueKey('vital_type_$type'),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _selectedType == type
                                            ? theme.colorScheme.primaryContainer
                                            : null,
                                      ),
                                      onPressed: () =>
                                          setState(() => _selectedType = type),
                                      icon: Icon(
                                        _selectedType == type
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 16,
                                      ),
                                      label: Text(_typeLabel(l10n, type)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('vital_primary_field'),
                              controller: _primaryController,
                              keyboardType: TextInputType.number,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: l10n.vitalValuePrimaryLabel,
                              ),
                            ),
                          ),
                          if (_selectedType == 'bp') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                key: const ValueKey('vital_secondary_field'),
                                controller: _secondaryController,
                                keyboardType: TextInputType.number,
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: l10n.vitalValueSecondaryLabel,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const ValueKey('submit_vital_btn'),
                          onPressed: _isSaving ? null : _submitManual,
                          icon: const Icon(Icons.add_chart_rounded),
                          label: Text(l10n.addVitalButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Readings List
              vitalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: Column(
                      children: [
                        Text(err.toString(), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.invalidate(vitalsNotifierProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.all(16),
                      child: Center(
                        child: Text(
                          l10n.noVitalsRecorded,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = list[index];
                      final color = _bandColor(r.band);
                      final valText = r.valueSecondary != null
                          ? '${r.valuePrimary.toInt()}/${r.valueSecondary!.toInt()}'
                          : r.valuePrimary.toInt().toString();

                      return Card(
                        key: ValueKey('vital_card_${r.id}'),
                        child: ListTile(
                          contentPadding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: Icon(
                            _bandIcon(r.band),
                            color: color,
                            size: 34,
                          ),
                          title: Text(
                            '${_typeLabel(l10n, r.type)}: $valText',
                            style: theme.textTheme.titleMedium,
                          ),
                          trailing: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_bandIcon(r.band), color: color, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _bandLabel(l10n, r.band),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
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
              const SizedBox(height: 12),

              // Blood Pressure Summary Card (Image 1 Screen 4)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/vitals/trends'),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFE53935),
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.vitalTypeBp,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (vitalsAsync.isLoading && !vitalsAsync.hasValue)
                          const SizedBox(
                            height: 32,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          Text(
                            bpText ??
                                (vitalsAsync.hasError
                                    ? l10n.errorOccurred
                                    : l10n.noVitalsRecorded),
                            style: bpText == null
                                ? theme.textTheme.bodyLarge
                                : theme.textTheme.headlineLarge?.copyWith(
                                    color: const Color(0xFF0F2942),
                                  ),
                          ),
                        if (latestBp != null) ...[
                          Text(
                            l10n.unitMmHg,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _bandColor(latestBp.band)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _summaryBandLabel(l10n, latestBp.band),
                              style: TextStyle(
                                color: _bandColor(latestBp.band),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lastReadingAt(
                              MaterialLocalizations.of(context).formatTimeOfDay(
                                TimeOfDay.fromDateTime(
                                  latestBp.recordedAt.toLocal(),
                                ),
                              ),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Blood Glucose Summary Card (Image 1 Screen 4)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/vitals/trends'),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop_rounded,
                              color: Color(0xFFD32F2F),
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.vitalTypeGlucose,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (vitalsAsync.isLoading && !vitalsAsync.hasValue)
                          const SizedBox(
                            height: 32,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          Text(
                            glucoseText ??
                                (vitalsAsync.hasError
                                    ? l10n.errorOccurred
                                    : l10n.noVitalsRecorded),
                            style: glucoseText == null
                                ? theme.textTheme.bodyLarge
                                : theme.textTheme.headlineLarge?.copyWith(
                                    color: const Color(0xFF0F2942),
                                  ),
                          ),
                        if (latestGlucose != null) ...[
                          Text(
                            l10n.unitMgDl,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _bandColor(latestGlucose.band)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _summaryBandLabel(l10n, latestGlucose.band),
                              style: TextStyle(
                                color: _bandColor(latestGlucose.band),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lastReadingAt(
                              MaterialLocalizations.of(context).formatTimeOfDay(
                                TimeOfDay.fromDateTime(
                                  latestGlucose.recordedAt.toLocal(),
                                ),
                              ),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
