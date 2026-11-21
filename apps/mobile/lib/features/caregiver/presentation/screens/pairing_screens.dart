import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:medliva/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

String _localizedCaregiverError(Object error, AppLocalizations l10n) {
  if (error is CaregiverRepositoryException) {
    return switch (error.code) {
      'INVALID_CODE' => l10n.pairingErrorInvalid,
      'ALREADY_LINKED' => l10n.pairingErrorAlreadyLinked,
      _ => l10n.pairingErrorGeneric,
    };
  }
  return l10n.pairingErrorGeneric;
}

class _PairingCodeDigitFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = CaregiverRepository.normalizeDigits(
      newValue.text,
    ).replaceAll(RegExp('[^0-9]'), '');
    final clamped = normalized.length > 6
        ? normalized.substring(0, 6)
        : normalized;
    return TextEditingValue(
      text: clamped,
      selection: TextSelection.collapsed(offset: clamped.length),
    );
  }
}

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
  String? _errorMessage;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_generate));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    final diff = expiresAt.toUtc().difference(DateTime.now().toUtc());
    _remaining = diff.isNegative ? Duration.zero : diff;
    if (_remaining > Duration.zero) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final next = expiresAt.toUtc().difference(DateTime.now().toUtc());
        if (next <= Duration.zero) {
          timer.cancel();
          setState(() => _remaining = Duration.zero);
        } else {
          setState(() => _remaining = next);
        }
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(caregiverRepositoryProvider);
      final res = await repo.generatePairingCode();
      if (!mounted) return;
      _startCountdown(res.expiresAt);
      setState(() => _codeModel = res);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final msg = _localizedCaregiverError(e, l10n);
      setState(() => _errorMessage = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _copyCode() async {
    final code = _codeModel?.code;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.codeCopiedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasCode = _codeModel != null;
    final isExpired = hasCode && _remaining <= Duration.zero;
    final remainingMinutes = (_remaining.inSeconds / 60).ceil();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pairingCodeTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.pairingCodeSubtitle,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            vertical: 16,
                          ),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _codeModel?.code ?? '------',
                            key: const ValueKey('pairing_code_display'),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 10,
                              color: isExpired
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        if (hasCode) ...[
                          const SizedBox(height: 16),
                          Container(
                            key: const ValueKey('pairing_code_expiry'),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? (isDark
                                        ? Colors.red.shade900.withValues(
                                            alpha: 0.45,
                                          )
                                        : Colors.red.shade50)
                                  : theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpired
                                      ? Icons.timer_off_rounded
                                      : Icons.schedule_rounded,
                                  size: 20,
                                  color: isExpired
                                      ? (isDark
                                            ? Colors.red.shade200
                                            : Colors.red.shade800)
                                      : theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isExpired
                                        ? l10n.pairingErrorExpired
                                        : l10n.codeExpiresIn(remainingMinutes),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isExpired
                                          ? (isDark
                                                ? Colors.red.shade200
                                                : Colors.red.shade900)
                                          : theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_errorMessage != null && !hasCode) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (hasCode) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: OutlinedButton.icon(
                    key: const ValueKey('copy_pairing_code_btn'),
                    onPressed: _isLoading ? null : _copyCode,
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l10n.copyCodeButton),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: ElevatedButton.icon(
                  key: const ValueKey('generate_pairing_code_btn'),
                  onPressed: _isLoading ? null : _generate,
                  icon: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
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
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final normalizedCode = CaregiverRepository.normalizeDigits(
      _codeController.text,
    ).replaceAll(RegExp('[^0-9]'), '');

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(caregiverRepositoryProvider);
      final linked = await repo.pairWithPatient(normalizedCode);
      ref
          .read(selectedPatientIdProvider.notifier)
          .selectPatient(linked.patientId);
      ref.invalidate(linkedPatientsProvider);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pairSuccessMessage)));
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_localizedCaregiverError(e, l10n)),
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
      appBar: AppBar(title: Text(l10n.pairPatientTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.pairPatientSubtitle, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    key: const ValueKey('caregiver_pair_code_field'),
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
                    inputFormatters: [_PairingCodeDigitFormatter()],
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
                    validator: (value) {
                      final normalized = CaregiverRepository.normalizeDigits(
                        value ?? '',
                      ).replaceAll(RegExp('[^0-9]'), '');
                      if (normalized.length != 6) {
                        return l10n.pairingCodeInvalidLength;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: ElevatedButton.icon(
                    key: const ValueKey('caregiver_pair_submit_btn'),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.link_rounded),
                    label: Text(l10n.pairSubmitButton),
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
