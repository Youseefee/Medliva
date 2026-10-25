import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({
    this.existingMedication,
    super.key,
  });

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingMedication;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _strengthController = TextEditingController(text: existing?.strength ?? '');
    _formController = TextEditingController(text: existing?.form ?? 'قرص');
    _stockController = TextEditingController(
      text: (existing?.stockCount ?? 30).toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _formController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final strength = _strengthController.text.trim();
    final form = _formController.text.trim().isEmpty
        ? 'قرص'
        : _formController.text.trim();
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    try {
      final notifier = ref.read(medicationsNotifierProvider.notifier);
      if (widget.existingMedication != null) {
        await notifier.updateMedication(
          widget.existingMedication!.id,
          MedicationUpdateInput(
            name: name,
            stockCount: stock,
          ),
        );
      } else {
        await notifier.createMedication(
          MedicationCreateInput(
            name: name,
            strength: strength.isEmpty ? null : strength,
            form: form,
            stockCount: stock,
          ),
        );
      }
      if (!mounted) return;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.editMedicationTitle : l10n.addMedicationTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.medicationNameLabel,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('med_name_field'),
                  controller: _nameController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: l10n.medicationNameLabel,
                    prefixIcon: const Icon(Icons.medication_rounded, size: 28),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.medicationNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.medicationStrengthLabel,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('med_strength_field'),
                  controller: _strengthController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: l10n.medicationStrengthLabel,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.medicationFormLabel,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('med_form_field'),
                  controller: _formController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: l10n.medicationFormLabel,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.medicationStockLabel,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('med_stock_field'),
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: l10n.medicationStockLabel,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    key: const ValueKey('submit_medication_form_btn'),
                    onPressed: _isSaving ? null : _submit,
                    icon: const Icon(Icons.save_rounded),
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
