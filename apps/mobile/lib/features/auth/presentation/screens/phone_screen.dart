import 'package:careelder/core/utils/phone_validator.dart';
import 'package:careelder/features/auth/presentation/auth_notifier.dart';
import 'package:careelder/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawPhone = _phoneController.text.trim();
    final normalized = PhoneValidator.normalizeEgyptianPhone(rawPhone);
    if (normalized == null) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await ref.read(authNotifierProvider.notifier).requestOtp(normalized);

      if (!mounted) return;

      if (result.devCode != null && result.devCode!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رمز التجربة: ${result.devCode}'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      context.push(
        '/otp',
        extra: {
          'phone': result.phone,
          'devCode': result.devCode,
        },
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 72,
                    color: Color(0xFF00796B),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appName,
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appTagline,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Text(
                    l10n.loginTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: l10n.phoneLabel,
                      hintText: l10n.phoneHint,
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 28),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال رقم الهاتف';
                      }
                      if (!PhoneValidator.isValidEgyptianPhone(val.trim())) {
                        return 'رقم الموبايل غير صحيح (مثال: 01012345678)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.sendOtpButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
