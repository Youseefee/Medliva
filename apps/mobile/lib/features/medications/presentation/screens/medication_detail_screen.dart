import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/features/storage/data/supabase_image_repository.dart';
import 'package:medliva/l10n/app_localizations.dart';

final _hhmmRegex = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$');

String _normalizeTime(String raw) {
  final trimmed = raw.trim();
  final parts = trimmed.split(':');
  if (parts.length != 2) return trimmed;
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}

class MedicationDetailScreen extends ConsumerStatefulWidget {
  const MedicationDetailScreen({required this.medication, super.key});

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
  String? _timeError;
  bool _isAdding = false;
  bool _isUploadingPillImage = false;
  String? _syncedFromMedicationSignature;

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

  String _mealLabel(AppLocalizations l10n, String relation) {
    switch (relation) {
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

  List<MapEntry<int, String>> _dayEntries(AppLocalizations l10n) => [
    MapEntry(1, l10n.daySat),
    MapEntry(2, l10n.daySun),
    MapEntry(4, l10n.dayMon),
    MapEntry(8, l10n.dayTue),
    MapEntry(16, l10n.dayWed),
    MapEntry(32, l10n.dayThu),
    MapEntry(64, l10n.dayFri),
  ];

  String _daysSummary(AppLocalizations l10n, int mask) {
    final entries = _dayEntries(l10n);
    final selected = entries
        .where((entry) => (mask & entry.key) != 0)
        .map((entry) => entry.value)
        .toList();
    if (selected.isEmpty) return '—';
    return selected.join(' • ');
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

  Future<void> _pickScheduleTime() async {
    final parts = _timeController.text.trim().split(':');
    final initialHour = int.tryParse(parts.first) ?? 8;
    final initialMinute =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialHour.clamp(0, 23),
        minute: initialMinute.clamp(0, 59),
      ),
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _timeController.text = formatted;
        _timeError = null;
      });
    }
  }

  void _invalidateDependentProviders() {
    ref
      ..invalidate(medicationsNotifierProvider)
      ..invalidate(todayDosesNotifierProvider)
      ..invalidate(inventoryForecastProvider);
  }

  Future<void> _addSchedule(MedicationModel med) async {
    final l10n = AppLocalizations.of(context)!;
    final rawTime = _timeController.text.trim();
    if (!_hhmmRegex.hasMatch(rawTime)) {
      setState(() => _timeError = l10n.invalidTimeFormat);
      return;
    }

    final normalizedTime = _normalizeTime(rawTime);
    setState(() {
      _timeError = null;
      _isAdding = true;
    });
    try {
      final repo = ref.read(medicationRepositoryProvider);
      final created = await repo.createSchedule(
        med.id,
        ScheduleCreateInput(
          timeOfDay: normalizedTime,
          mealRelation: _mealRelation,
          daysMask: _selectedDaysMask,
        ),
      );
      if (!mounted) return;
      setState(() {
        _schedules = [..._schedules, created]
          ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));
      });
      _invalidateDependentProviders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleAddedSuccess)),
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
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _editScheduleDialog(ScheduleModel schedule) async {
    final l10n = AppLocalizations.of(context)!;
    final editTimeController = TextEditingController(text: schedule.timeOfDay);
    var editDaysMask = schedule.daysMask;
    var editMealRelation = schedule.mealRelation;
    String? dialogError;

    final updated = await showDialog<ScheduleUpdateInput>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final dayLabels = _dayEntries(l10n);
          return AlertDialog(
            title: Text(l10n.schedulesSectionTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: editTimeController,
                    decoration: InputDecoration(
                      labelText: l10n.timeOfDayLabel,
                      errorText: dialogError,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.access_time_rounded),
                        onPressed: () async {
                          final parts = editTimeController.text.split(':');
                          final h = int.tryParse(parts.first) ?? 8;
                          final m = parts.length > 1
                              ? (int.tryParse(parts[1]) ?? 0)
                              : 0;
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay(
                              hour: h.clamp(0, 23),
                              minute: m.clamp(0, 59),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              editTimeController.text =
                                  '${picked.hour.toString().padLeft(2, '0')}:'
                                  '${picked.minute.toString().padLeft(2, '0')}';
                              dialogError = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final entry in dayLabels)
                        FilterChip(
                          selected: (editDaysMask & entry.key) != 0,
                          label: Text(entry.value),
                          onSelected: (_) {
                            setDialogState(() {
                              if ((editDaysMask & entry.key) != 0) {
                                final next = editDaysMask & ~entry.key;
                                if (next != 0) editDaysMask = next;
                              } else {
                                editDaysMask |= entry.key;
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final rel in const [
                        'after_meal',
                        'before_meal',
                        'with_meal',
                        'independent',
                      ])
                        ChoiceChip(
                          label: Text(_mealLabel(l10n, rel)),
                          selected: editMealRelation == rel,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => editMealRelation = rel);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancelButton),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                onPressed: () {
                  final raw = editTimeController.text.trim();
                  if (!_hhmmRegex.hasMatch(raw)) {
                    setDialogState(() => dialogError = l10n.invalidTimeFormat);
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    ScheduleUpdateInput(
                      timeOfDay: _normalizeTime(raw),
                      mealRelation: editMealRelation,
                      daysMask: editDaysMask,
                    ),
                  );
                },
                child: Text(l10n.saveButton),
              ),
            ],
          );
        },
      ),
    );
    editTimeController.dispose();

    if (updated == null) return;
    try {
      final saved = await ref
          .read(medicationRepositoryProvider)
          .updateSchedule(schedule.id, updated);
      if (!mounted) return;
      setState(() {
        _schedules = _schedules
            .map((s) => s.id == schedule.id ? saved : s)
            .toList()
          ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));
      });
      _invalidateDependentProviders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.medicationSavedSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteSchedule(ScheduleModel schedule) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteButton),
        content: Text(l10n.deleteScheduleConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    try {
      await ref.read(medicationRepositoryProvider).deleteSchedule(schedule.id);
      await ref
          .read(localReminderServiceProvider)
          .cancelScheduleReminders(schedule.id);
      if (!mounted) return;
      setState(() {
        _schedules = _schedules.where((s) => s.id != schedule.id).toList();
      });
      _invalidateDependentProviders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleDeletedSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _uploadPillImage(
    MedicationModel med,
    ImageSource source,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isUploadingPillImage = true);
    try {
      final file = await ref
          .read(mediaImagePickerProvider)
          .pickImage(source);
      if (file == null) return;

      final key = (patientId: med.patientId, medicationId: med.id);
      await ref
          .read(supabaseImageRepositoryProvider)
          .uploadPillImage(
            patientId: key.patientId,
            medicationId: key.medicationId,
            file: file,
          );
      ref.invalidate(pillImageSignedUrlProvider(key));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pillImageUploadSuccess)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.pillImageUploadFailed}: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPillImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Reactively stay in sync with edits from MedicationFormScreen or deep links.
    final medsList = ref.watch(medicationsNotifierProvider).value;
    final liveMed = medsList
        ?.where((m) => m.id == widget.medication.id)
        .firstOrNull;
    final med = liveMed ?? widget.medication;

    if (liveMed != null) {
      final sig = liveMed.schedules
          .map((s) => '${s.id}:${s.timeOfDay}:${s.mealRelation}:${s.daysMask}')
          .join('|');
      if (sig != _syncedFromMedicationSignature) {
        _syncedFromMedicationSignature = sig;
        _schedules = List<ScheduleModel>.from(liveMed.schedules)
          ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));
      }
    }

    final pillImageKey = (patientId: med.patientId, medicationId: med.id);
    final pillImage = ref.watch(pillImageSignedUrlProvider(pillImageKey));
    final dayLabels = _dayEntries(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(med.name),
        actions: [
          IconButton(
            tooltip: l10n.editMedicationTitle,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push(
              '/medications/${med.id}/edit',
              extra: med,
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
              // Medication info summary
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication_rounded,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              med.name,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (med.strength != null && med.strength!.isNotEmpty)
                            Text(
                              '${med.strength!} • ${med.form}',
                              style: theme.textTheme.bodyLarge,
                            )
                          else
                            Text(med.form, style: theme.textTheme.bodyLarge),
                          Text(
                            l10n.medicationStockCount(med.stockCount),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (med.expiryDate != null &&
                              med.expiryDate!.isNotEmpty)
                            Text(
                              '${l10n.medicationExpiryLabel}: ${med.expiryDate}',
                              style: theme.textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pill image card
              Card(
                key: const ValueKey('pill_image_card'),
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.pillImageTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          child: pillImage.when(
                            data: (url) => url == null
                                ? _PillImagePlaceholder(
                                    label: l10n.pillImageEmpty,
                                  )
                                : Image.network(
                                    url,
                                    key: const ValueKey('pill_image_preview'),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) =>
                                        _PillImagePlaceholder(
                                          label: l10n.pillImageUnavailable,
                                        ),
                                  ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, _) => _PillImagePlaceholder(
                              label: l10n.pillImageUnavailable,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              key: const ValueKey('pill_image_upload_btn'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                              ),
                              onPressed: _isUploadingPillImage
                                  ? null
                                  : () => _uploadPillImage(
                                      med,
                                      ImageSource.gallery,
                                    ),
                              icon: _isUploadingPillImage
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.photo_library_rounded),
                              label: Text(l10n.pillImageUploadButton),
                            ),
                          ),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              key: const ValueKey('pill_image_camera_btn'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                              ),
                              onPressed: _isUploadingPillImage
                                  ? null
                                  : () => _uploadPillImage(
                                      med,
                                      ImageSource.camera,
                                    ),
                              icon: const Icon(Icons.add_a_photo_rounded),
                              label: Text(l10n.pickFromCameraButton),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                l10n.schedulesSectionTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_schedules.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 12),
                  child: Text(
                    l10n.medicationNoSchedule,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              for (final sched in _schedules)
                Card(
                  key: ValueKey('schedule_item_${sched.id}'),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  margin: const EdgeInsetsDirectional.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.access_time_filled_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    title: Text(
                      sched.timeOfDay,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mealLabel(l10n, sched.mealRelation),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          _daysSummary(l10n, sched.daysMask),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: ValueKey('edit_schedule_btn_${sched.id}'),
                          tooltip: l10n.editMedicationTitle,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editScheduleDialog(sched),
                        ),
                        IconButton(
                          key: ValueKey('delete_schedule_btn_${sched.id}'),
                          tooltip: l10n.deleteButton,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: isDark
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                          ),
                          onPressed: () => _deleteSchedule(sched),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Add schedule card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
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
                        onChanged: (_) {
                          if (_timeError != null) {
                            setState(() => _timeError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: l10n.timeOfDayLabel,
                          hintText: '08:00',
                          errorText: _timeError,
                          prefixIcon: const Icon(Icons.schedule_rounded),
                          suffixIcon: IconButton(
                            key: const ValueKey('schedule_time_picker_btn'),
                            tooltip: l10n.timeOfDayLabel,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(Icons.access_time_rounded),
                            onPressed: _pickScheduleTime,
                          ),
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
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              selected: (_selectedDaysMask & entry.key) != 0,
                              label: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 16),
                              ),
                              onSelected: (_) => _toggleDay(entry.key),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in [
                            (
                              value: 'after_meal',
                              label: l10n.mealAfter,
                              key: const ValueKey('meal_after_btn'),
                            ),
                            (
                              value: 'before_meal',
                              label: l10n.mealBefore,
                              key: const ValueKey('meal_before_btn'),
                            ),
                            (
                              value: 'with_meal',
                              label: l10n.mealWith,
                              key: const ValueKey('meal_with_btn'),
                            ),
                            (
                              value: 'independent',
                              label: l10n.mealAnytime,
                              key: const ValueKey('meal_anytime_btn'),
                            ),
                          ])
                            Semantics(
                              selected: _mealRelation == option.value,
                              button: true,
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  key: option.key,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    backgroundColor:
                                        _mealRelation == option.value
                                        ? theme.colorScheme.primaryContainer
                                        : null,
                                    foregroundColor:
                                        _mealRelation == option.value
                                        ? theme.colorScheme.onPrimaryContainer
                                        : null,
                                  ),
                                  onPressed: () => setState(
                                    () => _mealRelation = option.value,
                                  ),
                                  icon: Icon(
                                    _mealRelation == option.value
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: _mealRelation == option.value
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                  label: Text(option.label),
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
                          onPressed: _isAdding ? null : () => _addSchedule(med),
                          icon: _isAdding
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_alarm_rounded),
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

class _PillImagePlaceholder extends StatelessWidget {
  const _PillImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ColoredBox(
      color: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
