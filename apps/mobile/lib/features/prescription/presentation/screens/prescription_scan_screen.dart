import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/features/prescription/data/prescription_repository.dart';
import 'package:medliva/features/prescription/domain/models/prescription.dart';
import 'package:medliva/l10n/app_localizations.dart';

class _EditableScanItem {
  _EditableScanItem({
    required this.source,
    required this.nameController,
    required this.dosageController,
    List<String>? times,
    String? mealRelation,
    TextEditingController? stockController,
  }) : times = times ?? List<String>.from(source.times),
       mealRelation = mealRelation ??
           (source.mealRelation.isNotEmpty ? source.mealRelation : 'after_meal'),
       stockController = stockController ??
           TextEditingController(
             text: '${source.inventoryPills > 0 ? source.inventoryPills : 30}',
           ),
       selected = true;

  final ExtractedDrugModel source;
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final List<String> times;
  String mealRelation;
  final TextEditingController stockController;
  bool selected;

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    stockController.dispose();
  }
}

class PrescriptionScanScreen extends ConsumerStatefulWidget {
  const PrescriptionScanScreen({super.key});

  @override
  ConsumerState<PrescriptionScanScreen> createState() =>
      _PrescriptionScanScreenState();
}

class _PrescriptionScanScreenState
    extends ConsumerState<PrescriptionScanScreen> {
  final List<_EditableScanItem> _items = [];
  Uint8List? _capturedImageBytes;
  bool _isLoading = false;
  bool _scanFoundNothing = false;

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  List<String> _defaultTimesForFrequency(int freq) {
    if (freq <= 1) return ['08:00'];
    if (freq == 2) return ['08:00', '20:00'];
    if (freq == 3) return ['08:00', '14:00', '20:00'];
    return ['08:00', '12:00', '16:00', '20:00'];
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

  Future<void> _pickAndScan(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.prescriptionPatientRequired),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final picker = ref.read(prescriptionImagePickerProvider);
      final file = await picker.pickImage(source);
      if (file == null) return;
      final bytes = await file.readAsBytes();

      final repo = ref.read(prescriptionRepositoryProvider);
      final scanResult = await repo.scanPrescription(
        file,
        patientId: patientId,
      );
      if (!mounted) return;

      for (final old in _items) {
        old.dispose();
      }

      setState(() {
        _capturedImageBytes = bytes;
        _scanFoundNothing = scanResult.medications.isEmpty;
        _items
          ..clear()
          ..addAll(
            scanResult.medications.map((m) {
              final initialTimes = m.times.isNotEmpty
                  ? List<String>.from(m.times)
                  : _defaultTimesForFrequency(m.frequencyPerDay);
              return _EditableScanItem(
                source: m,
                nameController: TextEditingController(text: m.drugTradeName),
                dosageController: TextEditingController(
                  text: m.dosageMg ?? '',
                ),
                times: initialTimes,
                mealRelation: m.mealRelation.isNotEmpty
                    ? m.mealRelation
                    : 'after_meal',
                stockController: TextEditingController(
                  text: '${m.inventoryPills > 0 ? m.inventoryPills : 30}',
                ),
              );
            }),
          );
      });
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _addManualItem() {
    setState(() {
      _scanFoundNothing = false;
      _items.add(
        _EditableScanItem(
          source: const ExtractedDrugModel(
            drugTradeName: '',
            dosageMg: '',
            frequencyPerDay: 1,
            mealRelation: 'after_meal',
            times: ['08:00'],
            inventoryPills: 30,
            confidenceScore: 1,
          ),
          nameController: TextEditingController(),
          dosageController: TextEditingController(),
          times: ['08:00'],
          mealRelation: 'after_meal',
          stockController: TextEditingController(text: '30'),
        ),
      );
    });
  }

  void _cancelReview() {
    for (final item in _items) {
      item.dispose();
    }
    setState(() {
      _items.clear();
      _capturedImageBytes = null;
      _scanFoundNothing = false;
    });
  }

  Future<void> _confirmAndCreate() async {
    final l10n = AppLocalizations.of(context)!;
    final eligibleItems = _items
        .where((item) => item.selected && item.nameController.text.trim().isNotEmpty)
        .toList();

    if (eligibleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.prescriptionSelectAtLeastOne),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    var createdCount = 0;
    try {
      final medsNotifier = ref.read(medicationsNotifierProvider.notifier);
      for (final item in eligibleItems) {
        final editedName = item.nameController.text.trim();
        final editedStrength = item.dosageController.text.trim();
        final strength = editedStrength.isEmpty
            ? (item.source.dosageMg?.isNotEmpty == true
                ? item.source.dosageMg
                : null)
            : editedStrength;

        final scheduleTimes = item.times.isNotEmpty
            ? item.times
            : (item.source.times.isNotEmpty
                ? item.source.times
                : _defaultTimesForFrequency(item.source.frequencyPerDay));

        final schedules = scheduleTimes
            .map(
              (t) => ScheduleCreateInput(
                timeOfDay: t,
                mealRelation: item.mealRelation,
              ),
            )
            .toList();

        final parsedStock = int.tryParse(item.stockController.text.trim());
        final stockCount = (parsedStock != null && parsedStock >= 0)
            ? parsedStock
            : item.source.inventoryPills;

        await medsNotifier.createMedication(
          MedicationCreateInput(
            name: editedName,
            tradeName: editedName,
            activeIngredient: item.source.activeIngredient,
            strength: strength,
            stockCount: stockCount,
            schedules: schedules,
          ),
        );
        createdCount++;

        // Remove succeeded item immediately so partial failures never duplicate
        // already-created medications on retry.
        if (mounted) {
          setState(() {
            _items.remove(item);
            item.dispose();
          });
        }
      }
      if (!mounted) return;

      ref
        ..invalidate(todayDosesNotifierProvider)
        ..invalidate(inventoryForecastProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.prescriptionAddedCount(createdCount)),
          backgroundColor: const Color(0xFF00796B),
        ),
      );

      _cancelReview();
    } catch (e) {
      if (createdCount > 0) {
        ref
          ..invalidate(todayDosesNotifierProvider)
          ..invalidate(inventoryForecastProvider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanPrescriptionTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        key: const ValueKey('scan_camera_btn'),
                        onPressed: _isLoading
                            ? null
                            : () => _pickAndScan(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(l10n.pickFromCameraButton),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        key: const ValueKey('scan_gallery_btn'),
                        onPressed: _isLoading
                            ? null
                            : () => _pickAndScan(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(l10n.pickFromGalleryButton),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(top: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surfaceContainerHigh
                                : const Color(0xFF0F2942),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            margin: const EdgeInsetsDirectional.all(24),
                            padding: const EdgeInsetsDirectional.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white70,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _scanFoundNothing
                                          ? Icons.search_off_rounded
                                          : Icons.document_scanner_rounded,
                                      size: 72,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _scanFoundNothing
                                          ? l10n.scanNoMedicationsFound
                                          : l10n.scanFrameHint,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_scanFoundNothing) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.scanNoMedicationsFoundHint,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.white70),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('scan_add_manual_btn'),
                          onPressed: _addManualItem,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(l10n.prescriptionAddManual),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Expanded(
                  child: ListView(
                    children: [
                      if (_capturedImageBytes != null &&
                          _capturedImageBytes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 12),
                          child: RepaintBoundary(
                            child: Card(
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 160,
                                ),
                                child: Image.memory(
                                  _capturedImageBytes!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsetsDirectional.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0C4A6E).withValues(alpha: 0.6)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.aiExtractedNotice,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? const Color(0xFFBAE6FD)
                                      : const Color(0xFF075985),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var index = 0; index < _items.length; index++) ...[
                        _buildReviewCard(context, index, l10n, theme, isDark),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          key: const ValueKey('scan_add_manual_btn'),
                          onPressed: _addManualItem,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.prescriptionAddManual),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          key: const ValueKey('scan_cancel_btn'),
                          onPressed: _cancelReview,
                          child: Text(l10n.cancelButton),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          key: const ValueKey('scan_confirm_btn'),
                          onPressed: _confirmAndCreate,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l10n.confirmPrescriptionButton),
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
  }

  Widget _buildReviewCard(
    BuildContext context,
    int index,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final item = _items[index];
    final isHighConf = item.source.confidenceScore >= 0.85;

    return Card(
      key: ValueKey('scan_review_card_$index'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  key: ValueKey('scan_select_checkbox_$index'),
                  semanticLabel: l10n.medicationNameLabel,
                  value: item.selected,
                  onChanged: (val) =>
                      setState(() => item.selected = val ?? false),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isHighConf
                          ? (isDark
                              ? const Color(0xFF14532D).withValues(alpha: 0.5)
                              : const Color(0xFFE8F5E9))
                          : (isDark
                              ? const Color(0xFF78350F).withValues(alpha: 0.5)
                              : const Color(0xFFFFF8E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHighConf
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 18,
                          color: isHighConf
                              ? (isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF2E7D32))
                              : (isDark
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFB45309)),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isHighConf
                                ? l10n.highConfidenceBadge
                                : l10n.needsReviewBadge,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isHighConf
                                  ? (isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF2E7D32))
                                  : (isDark
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFFB45309)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 24,
                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                  ),
                  tooltip: l10n.deleteButton,
                  onPressed: () {
                    setState(() {
                      _items.removeAt(index).dispose();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('scan_name_field_$index'),
              controller: item.nameController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: l10n.medicationNameLabel,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.dosageController,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: l10n.medicationStrengthLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: item.stockController,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: l10n.medicationStockLabel,
                      prefixIcon: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.schedulesSectionTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Quick frequency presets that directly update schedule times
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(l10n.onceDaily),
                  selected: item.times.length == 1,
                  onSelected: (_) => setState(() {
                    item.times
                      ..clear()
                      ..addAll(_defaultTimesForFrequency(1));
                  }),
                ),
                ChoiceChip(
                  label: Text(l10n.twiceDaily),
                  selected: item.times.length == 2,
                  onSelected: (_) => setState(() {
                    item.times
                      ..clear()
                      ..addAll(_defaultTimesForFrequency(2));
                  }),
                ),
                ChoiceChip(
                  label: Text(l10n.medicationFreqCount(3)),
                  selected: item.times.length == 3,
                  onSelected: (_) => setState(() {
                    item.times
                      ..clear()
                      ..addAll(_defaultTimesForFrequency(3));
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var tIdx = 0; tIdx < item.times.length; tIdx++)
                  Chip(
                    label: Text(
                      item.times[tIdx],
                      style: const TextStyle(fontSize: 16),
                    ),
                    avatar: const Icon(Icons.access_time_rounded, size: 18),
                    deleteIcon: item.times.length > 1
                        ? const Icon(Icons.close_rounded, size: 18)
                        : null,
                    onDeleted: item.times.length > 1
                        ? () {
                            setState(() => item.times.removeAt(tIdx));
                          }
                        : null,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(
                    l10n.addScheduleButton,
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (!mounted || picked == null) return;
                    final hh = picked.hour.toString().padLeft(2, '0');
                    final mm = picked.minute.toString().padLeft(2, '0');
                    final formatted = '$hh:$mm';
                    if (!item.times.contains(formatted)) {
                      setState(() {
                        item.times
                          ..add(formatted)
                          ..sort();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
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
                    selected: item.mealRelation == rel,
                    onSelected: (val) {
                      if (val) {
                        setState(() => item.mealRelation = rel);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
