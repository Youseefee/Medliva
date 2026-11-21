import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({this.existingMedication, super.key});

  final MedicationModel? existingMedication;

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _strengthController;
  late final TextEditingController _formController;
  late final TextEditingController _stockController;
  late final TextEditingController _alertDaysController;
  String? _expiryDate;
  bool _formDefaultApplied = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingMedication;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _strengthController = TextEditingController(text: existing?.strength ?? '');
    _formController = TextEditingController(text: existing?.form ?? '');
    _stockController = TextEditingController(
      text: (existing?.stockCount ?? 30).toString(),
    );
    _alertDaysController = TextEditingController(
      text: (existing?.alertThresholdDays ?? 5).toString(),
    );
    _expiryDate = existing?.expiryDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_formDefaultApplied && _formController.text.isEmpty) {
      _formDefaultApplied = true;
      final isAr = AppLocalizations.of(context)?.localeName == 'ar';
      _formController.text = isAr ? 'قرص' : 'Tablet';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _formController.dispose();
    _stockController.dispose();
    _alertDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final initial = _expiryDate != null
        ? (DateTime.tryParse(_expiryDate!) ?? now)
        : now.add(const Duration(days: 180));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() => _expiryDate = formatted);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final strength = _strengthController.text.trim();
    final defaultForm = l10n.localeName == 'ar' ? 'قرص' : 'Tablet';
    final form = _formController.text.trim().isEmpty
        ? defaultForm
        : _formController.text.trim();
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final alertDays = int.tryParse(_alertDaysController.text.trim()) ?? 5;

    try {
      final notifier = ref.read(medicationsNotifierProvider.notifier);
      if (widget.existingMedication != null) {
        await notifier.updateMedication(
          widget.existingMedication!.id,
          MedicationUpdateInput(
            name: name,
            strength: strength.isEmpty ? null : strength,
            form: form,
            stockCount: stock,
            alertThresholdDays: alertDays,
            expiryDate: _expiryDate,
            clearExpiryDate:
                _expiryDate == null &&
                widget.existingMedication!.expiryDate != null,
          ),
        );
      } else {
        await notifier.createMedication(
          MedicationCreateInput(
            name: name,
            strength: strength.isEmpty ? null : strength,
            form: form,
            stockCount: stock,
            alertThresholdDays: alertDays,
            expiryDate: _expiryDate,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.medicationSavedSuccess)),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
    final isEditing = widget.existingMedication != null;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.editMedicationTitle : l10n.addMedicationTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('med_name_field'),
                  controller: _nameController,
                  style: theme.textTheme.bodyLarge,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.medicationNameLabel,
                    prefixIcon: Icon(
                      Icons.medication_rounded,
                      size: 28,
                      color: accentColor,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.medicationNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('med_strength_field'),
                        controller: _strengthController,
                        style: theme.textTheme.bodyLarge,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.medicationStrengthLabel,
                          prefixIcon: Icon(
                            Icons.scale_rounded,
                            size: 24,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('med_form_field'),
                        controller: _formController,
                        style: theme.textTheme.bodyLarge,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.medicationFormLabel,
                          prefixIcon: Icon(
                            Icons.local_pharmacy_rounded,
                            size: 24,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('med_stock_field'),
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.bodyLarge,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.medicationStockLabel,
                          prefixIcon: Icon(
                            Icons.inventory_2_outlined,
                            size: 24,
                            color: accentColor,
                          ),
                        ),
                        validator: (val) {
                          final parsed = int.tryParse((val ?? '').trim());
                          if (parsed == null || parsed < 0) {
                            return l10n.invalidStockNumber;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('med_alert_days_field'),
                        controller: _alertDaysController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: l10n.medicationAlertDaysLabel,
                          prefixIcon: Icon(
                            Icons.notifications_active_outlined,
                            size: 24,
                            color: accentColor,
                          ),
                        ),
                        validator: (val) {
                          final parsed = int.tryParse((val ?? '').trim());
                          if (parsed == null || parsed < 1) {
                            return l10n.invalidStockNumber;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    key: const ValueKey('med_expiry_picker'),
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(Icons.event_rounded, color: accentColor),
                    title: Text(
                      l10n.medicationExpiryLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      _expiryDate ?? '—',
                      style: theme.textTheme.bodyLarge,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_expiryDate != null)
                          IconButton(
                            tooltip: l10n.cancelButton,
                            onPressed: () =>
                                setState(() => _expiryDate = null),
                            icon: const Icon(Icons.clear_rounded),
                          ),
                        const Icon(Icons.calendar_month_rounded),
                      ],
                    ),
                    onTap: _pickExpiryDate,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    key: const ValueKey('submit_medication_form_btn'),
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(l10n.saveButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
