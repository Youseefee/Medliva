import 'package:careelder/features/auth/presentation/auth_notifier.dart';
import 'package:careelder/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    required this.phone,
    this.devCode,
    super.key,
  });

  final String phone;
  final String? devCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final TextEditingController _codeController;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'patient';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.devCode ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).verifyOtp(
            phone: widget.phone,
            code: _codeController.text.trim(),
            role: _selectedRole,
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.otpTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.otpSubtitle(widget.phone),
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.otpLabel,
                    hintText: l10n.otpHint,
                    counterText: '',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 4) {
                      return 'يرجى إدخال رمز التحقق كاملاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.nameLabel,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: l10n.nameHint,
                    prefixIcon: const Icon(Icons.person_rounded, size: 28),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.roleLabel,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'patient',
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.rolePatient,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      icon: const Icon(Icons.elderly_rounded),
                    ),
                    ButtonSegment(
                      value: 'caregiver',
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.roleCaregiver,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      icon: const Icon(Icons.family_restroom_rounded),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (newSet) {
                    setState(() => _selectedRole = newSet.first);
                  },
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  child: _isLoading
                      ? const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.verifyButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
