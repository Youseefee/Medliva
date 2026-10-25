import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/features/prescription/data/prescription_repository.dart';
import 'package:medliva/features/prescription/domain/models/prescription.dart';
import 'package:medliva/l10n/app_localizations.dart';

class _EditableScanItem {
  _EditableScanItem({
    required this.source,
    required this.nameController,
    required this.dosageController,
    required this.freqController,
  }) : selected = true;

  final ExtractedDrugModel source;
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController freqController;
  bool selected;
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
  bool _isLoading = false;
  bool _scanFoundNothing = false;

  @override
  void dispose() {
    for (final item in _items) {
      item.nameController.dispose();
      item.dosageController.dispose();
      item.freqController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final picker = ref.read(prescriptionImagePickerProvider);
      final file = await picker.pickImage(source);
      if (file == null) return;

      final repo = ref.read(prescriptionRepositoryProvider);
      final scanResult = await repo.scanPrescription(file);
      if (!mounted) return;

      for (final old in _items) {
        old.nameController.dispose();
        old.dosageController.dispose();
        old.freqController.dispose();
      }

      setState(() {
        _scanFoundNothing = scanResult.medications.isEmpty;
        _items
          ..clear()
          ..addAll(
            scanResult.medications.map(
              (m) => _EditableScanItem(
                source: m,
                nameController: TextEditingController(text: m.drugTradeName),
                dosageController: TextEditingController(
                  text: m.dosageMg ?? '5 mg',
                ),
                freqController: TextEditingController(
                  text: m.frequencyPerDay >= 2
                      ? l10n.doseFrequencyTwice
                      : l10n.doseFrequencyOnce,
                ),
              ),
            ),
          );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelReview() {
    for (final item in _items) {
      item.nameController.dispose();
      item.dosageController.dispose();
      item.freqController.dispose();
    }
    setState(_items.clear);
  }

  Future<void> _confirmAndCreate() async {
    setState(() => _isLoading = true);
    try {
      final medsNotifier = ref.read(medicationsNotifierProvider.notifier);
      for (final item in _items) {
        if (!item.selected) continue;
        final editedName = item.nameController.text.trim();
        if (editedName.isEmpty) continue;
        final schedules = item.source.times
            .map(
              (t) => ScheduleCreateInput(
                timeOfDay: t,
                mealRelation: item.source.mealRelation,
              ),
            )
            .toList();

        await medsNotifier.createMedication(
          MedicationCreateInput(
            name: editedName,
            tradeName: editedName,
            activeIngredient: item.source.activeIngredient,
            strength: item.source.dosageMg,
            stockCount: item.source.inventoryPills,
            schedules: schedules,
          ),
        );
      }
      if (!mounted) return;
      _cancelReview();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanPrescriptionTitle),
      ),
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
              const SizedBox(height: 20),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(top: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2942),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsetsDirectional.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white70,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _scanFoundNothing
                                      ? Icons.search_off_rounded
                                      : Icons.document_scanner_rounded,
                                  size: 80,
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _scanFoundNothing
                                      ? l10n.scanNoMedicationsFound
                                      : l10n.scanFrameHint,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_scanFoundNothing) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.scanNoMedicationsFoundHint,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsetsDirectional.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.aiExtractedNotice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF075985),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isHighConf = item.source.confidenceScore >= 0.85;
                      return Card(
                        key: ValueKey('scan_review_card_$index'),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    key: ValueKey(
                                      'scan_select_checkbox_$index',
                                    ),
                                    semanticLabel: l10n.medicationNameLabel,
                                    value: item.selected,
                                    onChanged: (val) => setState(
                                      () => item.selected = val ?? false,
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isHighConf
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isHighConf
                                              ? Icons.check_circle_rounded
                                              : Icons.warning_amber_rounded,
                                          size: 16,
                                          color: isHighConf
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFB45309),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isHighConf
                                              ? l10n.highConfidenceBadge
                                              : l10n.needsReviewBadge,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isHighConf
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
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
                                  suffixIcon: const Icon(Icons.edit_rounded),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: item.dosageController,
                                      style: theme.textTheme.bodyMedium,
                                      decoration: InputDecoration(
                                        labelText: l10n.medicationStrengthLabel,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: item.freqController,
                                      style: theme.textTheme.bodyMedium,
                                      decoration: InputDecoration(
                                        labelText: l10n.schedulesSectionTitle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
}
