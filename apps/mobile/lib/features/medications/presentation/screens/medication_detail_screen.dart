import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class MedicationDetailScreen extends ConsumerStatefulWidget {
  const MedicationDetailScreen({
    required this.medication,
    super.key,
  });

  final MedicationModel medication;

  @override
  ConsumerState<MedicationDetailScreen> createState() =>
      _MedicationDetailScreenState();
}

class _MedicationDetailScreenState
    extends ConsumerState<MedicationDetailScreen> {
  final _timeController = TextEditingController(text: '08:00');
  late List<ScheduleModel> _schedules;
  int _selectedDaysMask = 127;
  String _mealRelation = 'after_meal';
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _schedules = List<ScheduleModel>.from(widget.medication.schedules);
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _toggleDay(int bit) {
    setState(() {
      if ((_selectedDaysMask & bit) != 0) {
        final next = _selectedDaysMask & ~bit;
        if (next != 0) _selectedDaysMask = next;
      } else {
        _selectedDaysMask |= bit;
      }
    });
  }

  Future<void> _addSchedule() async {
    final timeStr = _timeController.text.trim();
    if (timeStr.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      final repo = ref.read(medicationRepositoryProvider);
      final created = await repo.createSchedule(
        widget.medication.id,
        ScheduleCreateInput(
          timeOfDay: timeStr,
          mealRelation: _mealRelation,
          daysMask: _selectedDaysMask,
        ),
      );
      if (!mounted) return;
      setState(() {
        _schedules = [..._schedules, created];
      });
      ref.invalidate(medicationsNotifierProvider);
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
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dayLabels = <MapEntry<int, String>>[
      MapEntry(1, l10n.daySat),
      MapEntry(2, l10n.daySun),
      MapEntry(4, l10n.dayMon),
      MapEntry(8, l10n.dayTue),
      MapEntry(16, l10n.dayWed),
      MapEntry(32, l10n.dayThu),
      MapEntry(64, l10n.dayFri),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication.name),
        actions: [
          IconButton(
            tooltip: l10n.editMedicationTitle,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push(
              '/medications/${widget.medication.id}/edit',
              extra: widget.medication,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.schedulesSectionTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final sched in _schedules)
                Card(
                  key: ValueKey('schedule_item_${sched.id}'),
                  margin: const EdgeInsetsDirectional.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Color(0xFF00796B),
                      size: 32,
                    ),
                    title: Text(
                      sched.timeOfDay,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      sched.mealRelation == 'before_meal'
                          ? l10n.mealBefore
                          : l10n.mealAfter,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.timeOfDayLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('schedule_time_field'),
                        controller: _timeController,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: l10n.timeOfDayLabel,
                          hintText: '08:00',
                          prefixIcon: const Icon(Icons.schedule_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.daysOfWeekLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in dayLabels)
                            FilterChip(
                              key: ValueKey('day_chip_${entry.key}'),
                              selected: (_selectedDaysMask & entry.key) != 0,
                              label: Text(entry.value),
                              onSelected: (_) => _toggleDay(entry.key),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              selected: _mealRelation == 'after_meal',
                              button: true,
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  key: const ValueKey('meal_after_btn'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        _mealRelation == 'after_meal'
                                            ? theme.colorScheme.primaryContainer
                                            : null,
                                  ),
                                  onPressed: () => setState(
                                    () => _mealRelation = 'after_meal',
                                  ),
                                  icon: Icon(
                                    _mealRelation == 'after_meal'
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 18,
                                  ),
                                  label: Text(l10n.mealAfter),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Semantics(
                              selected: _mealRelation == 'before_meal',
                              button: true,
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  key: const ValueKey('meal_before_btn'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        _mealRelation == 'before_meal'
                                            ? theme.colorScheme.primaryContainer
                                            : null,
                                  ),
                                  onPressed: () => setState(
                                    () => _mealRelation = 'before_meal',
                                  ),
                                  icon: Icon(
                                    _mealRelation == 'before_meal'
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 18,
                                  ),
                                  label: Text(l10n.mealBefore),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          key: const ValueKey('add_schedule_btn'),
                          onPressed: _isAdding ? null : _addSchedule,
                          icon: const Icon(Icons.add_alarm_rounded),
                          label: Text(l10n.addScheduleButton),
                        ),
                      ),
                    ],
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
