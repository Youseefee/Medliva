import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:medliva/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class PatientPairingCodeScreen extends ConsumerStatefulWidget {
  const PatientPairingCodeScreen({super.key});

  @override
  ConsumerState<PatientPairingCodeScreen> createState() =>
      _PatientPairingCodeScreenState();
}

class _PatientPairingCodeScreenState
    extends ConsumerState<PatientPairingCodeScreen> {
  PairingCodeModel? _codeModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_generate));
  }

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(caregiverRepositoryProvider);
      final res = await repo.generatePairingCode();
      if (!mounted) return;
      setState(() => _codeModel = res);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pairingCodeTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.pairingCodeSubtitle,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            _codeModel?.code ?? '------',
                            key: const ValueKey('pairing_code_display'),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 10,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  key: const ValueKey('generate_pairing_code_btn'),
                  onPressed: _isLoading ? null : _generate,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.generatePairingCodeButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaregiverPairScreen extends ConsumerStatefulWidget {
  const CaregiverPairScreen({super.key});

  @override
  ConsumerState<CaregiverPairScreen> createState() =>
      _CaregiverPairScreenState();
}

class _CaregiverPairScreenState extends ConsumerState<CaregiverPairScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(caregiverRepositoryProvider);
      final linked = await repo.pairWithPatient(code);
      ref
          .read(selectedPatientIdProvider.notifier)
          .selectPatient(linked.patientId);
      ref.invalidate(linkedPatientsProvider);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pairSuccessMessage)),
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pairPatientTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.pairPatientSubtitle,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('caregiver_pair_code_field'),
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: l10n.pairCodeInputLabel,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  key: const ValueKey('caregiver_pair_submit_btn'),
                  onPressed: _isSubmitting ? null : _submit,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(l10n.pairSubmitButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
