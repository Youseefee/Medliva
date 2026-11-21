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
  const VitalsScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  String _selectedType = 'bp';
  String _mealContext = 'fasting';
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

  String _unitLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'glucose':
        return l10n.unitMgDl;
      case 'pulse':
        return 'bpm';
      default:
        return l10n.unitMmHg;
    }
  }

  String _primaryFieldLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'glucose':
        return l10n.vitalGlucoseLabel;
      case 'pulse':
        return l10n.vitalPulseLabel;
      default:
        return l10n.vitalSystolicLabel;
    }
  }

  String _mealContextLabel(AppLocalizations l10n, String ctx) {
    switch (ctx) {
      case 'fasting':
        return l10n.mealContextFasting;
      case 'post_prandial':
        return l10n.mealContextPostMeal;
      default:
        return l10n.mealContextRandom;
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

  Color _bandColor(String band, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (band) {
      case 'critical':
        return isDark ? Colors.red.shade300 : Colors.red.shade800;
      case 'borderline':
        return isDark ? Colors.amber.shade300 : Colors.orange.shade800;
      default:
        return isDark ? Colors.green.shade300 : Colors.green.shade800;
    }
  }

  String? _validatePrimary(AppLocalizations l10n, String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return l10n.vitalInvalidValue;
    switch (_selectedType) {
      case 'bp':
        if (parsed < 40 || parsed > 300) return l10n.vitalInvalidValue;
      case 'glucose':
        if (parsed < 20 || parsed > 700) return l10n.vitalInvalidValue;
      case 'pulse':
        if (parsed < 25 || parsed > 250) return l10n.vitalInvalidValue;
    }
    return null;
  }

  String? _validateSecondary(AppLocalizations l10n, String? value) {
    if (_selectedType != 'bp') return null;
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 20 || parsed > 200) {
      return l10n.vitalInvalidValue;
    }
    final primary = double.tryParse(_primaryController.text.trim());
    if (primary != null && primary <= parsed) {
      return l10n.vitalSystolicGreaterError;
    }
    return null;
  }

  Future<void> _submitManual() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final primaryVal = double.parse(_primaryController.text.trim());
    final secondaryVal = _selectedType == 'bp'
        ? double.parse(_secondaryController.text.trim())
        : null;
    final mealContext = _selectedType == 'glucose' ? _mealContext : null;
    final clientUuid =
        'vital-$_selectedType-${DateTime.now().toUtc().millisecondsSinceEpoch}';

    setState(() => _isSaving = true);
    try {
      final created = await ref
          .read(vitalsNotifierProvider.notifier)
          .addVital(
            VitalCreateInput(
              clientUuid: clientUuid,
              type: _selectedType,
              valuePrimary: primaryVal,
              valueSecondary: secondaryVal,
              mealContext: mealContext,
            ),
          );
      _primaryController.clear();
      _secondaryController.clear();
      if (!mounted) return;
      final feedbackText = created.band == 'normal'
          ? '${l10n.vitalLoggedSuccess} — ${l10n.reassuringStatusSub}'
          : '${l10n.vitalLoggedSuccess} — ${_bandLabel(l10n, created.band)}';
      final bgColor = created.band == 'critical'
          ? Theme.of(context).colorScheme.error
          : (created.band == 'borderline'
              ? Colors.orange.shade800
              : const Color(0xFF00796B));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackText),
          backgroundColor: bgColor,
        ),
      );
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
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chevronIcon =
        isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;
    final vitalsAsync = ref.watch(vitalsNotifierProvider);

    final readings = vitalsAsync.value ?? const [];
    final latestBp = readings.where((r) => r.type == 'bp').firstOrNull;
    final latestGlucose = readings
        .where((r) => r.type == 'glucose')
        .firstOrNull;
    final latestPulse = readings.where((r) => r.type == 'pulse').firstOrNull;

    final bpText = latestBp == null
        ? null
        : (latestBp.valueSecondary != null
              ? '${latestBp.valuePrimary.toInt()} / ${latestBp.valueSecondary!.toInt()}'
              : '${latestBp.valuePrimary.toInt()}');
    final glucoseText = latestGlucose == null
        ? null
        : '${latestGlucose.valuePrimary.toInt()}';
    final pulseText = latestPulse == null
        ? null
        : '${latestPulse.valuePrimary.toInt()}';

    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vitalsNotifierProvider);
          await ref.read(vitalsNotifierProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded) ...[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const ValueKey('vitals_open_trends_btn'),
                    onPressed: () => context.push('/vitals/trends'),
                    icon: const Icon(Icons.show_chart_rounded),
                    label: Text(l10n.navTrends),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Manual Entry Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final type in const ['bp', 'glucose', 'pulse'])
                              Semantics(
                                selected: _selectedType == type,
                                button: true,
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    key: ValueKey('vital_type_$type'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      backgroundColor: _selectedType == type
                                          ? theme.colorScheme.primaryContainer
                                          : null,
                                      foregroundColor: _selectedType == type
                                          ? theme.colorScheme.onPrimaryContainer
                                          : null,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedType = type;
                                        if (type != 'bp') {
                                          _secondaryController.clear();
                                        }
                                      });
                                      _formKey.currentState?.reset();
                                    },
                                    icon: Icon(
                                      _selectedType == type
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 18,
                                    ),
                                    label: Text(_typeLabel(l10n, type)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_selectedType == 'glucose') ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final ctx in const [
                                'fasting',
                                'post_prandial',
                                'random',
                              ])
                                ChoiceChip(
                                  key: ValueKey('meal_context_$ctx'),
                                  label: Text(_mealContextLabel(l10n, ctx)),
                                  selected: _mealContext == ctx,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _mealContext = ctx);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const ValueKey('vital_primary_field'),
                                controller: _primaryController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: _primaryFieldLabel(
                                    l10n,
                                    _selectedType,
                                  ),
                                ),
                                validator: (val) =>
                                    _validatePrimary(l10n, val),
                              ),
                            ),
                            if (_selectedType == 'bp') ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: const ValueKey('vital_secondary_field'),
                                  controller: _secondaryController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: l10n.vitalDiastolicLabel,
                                  ),
                                  validator: (val) =>
                                      _validateSecondary(l10n, val),
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
                            icon: _isSaving
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_chart_rounded),
                            label: Text(l10n.addVitalButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Summary Cards above recent readings for immediate elderly visibility
              _buildSummaryCard(
                context: context,
                l10n: l10n,
                theme: theme,
                isDark: isDark,
                chevronIcon: chevronIcon,
                icon: Icons.favorite_rounded,
                iconColor: isDark
                    ? Colors.red.shade300
                    : const Color(0xFFE53935),
                title: l10n.vitalTypeBp,
                valueText: bpText,
                unit: l10n.unitMmHg,
                reading: latestBp,
                vitalsAsync: vitalsAsync,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                context: context,
                l10n: l10n,
                theme: theme,
                isDark: isDark,
                chevronIcon: chevronIcon,
                icon: Icons.water_drop_rounded,
                iconColor: isDark
                    ? Colors.red.shade300
                    : const Color(0xFFD32F2F),
                title: l10n.vitalTypeGlucose,
                valueText: glucoseText,
                unit: l10n.unitMgDl,
                reading: latestGlucose,
                vitalsAsync: vitalsAsync,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                context: context,
                l10n: l10n,
                theme: theme,
                isDark: isDark,
                chevronIcon: chevronIcon,
                icon: Icons.monitor_heart_rounded,
                iconColor: theme.colorScheme.primary,
                title: l10n.vitalTypePulse,
                valueText: pulseText,
                unit: 'bpm',
                reading: latestPulse,
                vitalsAsync: vitalsAsync,
              ),
              const SizedBox(height: 16),

              // Recent Readings List
              vitalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: Column(
                      children: [
                        Text(
                          err.toString(),
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
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
                      final color = _bandColor(r.band, theme.brightness);
                      final valText = r.valueSecondary != null
                          ? '${r.valuePrimary.toInt()}/${r.valueSecondary!.toInt()}'
                          : r.valuePrimary.toInt().toString();
                      final unit = _unitLabel(l10n, r.type);
                      final localTime = r.recordedAt.toLocal();
                      final timeStr = MaterialLocalizations.of(context)
                          .formatTimeOfDay(TimeOfDay.fromDateTime(localTime));
                      final dateStr =
                          '${localTime.day.toString().padLeft(2, '0')}/'
                          '${localTime.month.toString().padLeft(2, '0')}';
                      final subtitleParts = <String>[
                        '$dateStr • $timeStr',
                        if (r.type == 'glucose' &&
                            r.mealContext != null &&
                            r.mealContext!.isNotEmpty)
                          _mealContextLabel(l10n, r.mealContext!),
                      ];

                      return Card(
                        key: ValueKey('vital_card_${r.id}'),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
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
                            '${_typeLabel(l10n, r.type)}: $valText $unit',
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            subtitleParts.join(' • '),
                            style: theme.textTheme.bodyMedium,
                          ),
                          trailing: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
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
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(body: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vitalsTitle),
        actions: [
          IconButton(
            key: const ValueKey('vitals_open_trends_btn'),
            tooltip: l10n.navTrends,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.show_chart_rounded),
            onPressed: () => context.push('/vitals/trends'),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool isDark,
    required IconData chevronIcon,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String? valueText,
    required String unit,
    required VitalReadingModel? reading,
    required AsyncValue<List<VitalReadingModel>> vitalsAsync,
  }) {
    final bandColor = reading != null
        ? _bandColor(reading.band, theme.brightness)
        : null;

    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
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
                  Icon(icon, color: iconColor, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  Icon(chevronIcon),
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
                  valueText ??
                      (vitalsAsync.hasError
                          ? l10n.errorOccurred
                          : l10n.noVitalsRecorded),
                  style: valueText == null
                      ? theme.textTheme.bodyLarge
                      : theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                ),
              if (reading != null && bandColor != null) ...[
                Text(unit, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bandColor.withValues(alpha: isDark ? 0.25 : 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_bandIcon(reading.band), color: bandColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _summaryBandLabel(l10n, reading.band),
                        style: TextStyle(
                          color: bandColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.lastReadingAt(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(reading.recordedAt.toLocal()),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
