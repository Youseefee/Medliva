import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailPasswordScreen extends ConsumerStatefulWidget {
  const EmailPasswordScreen({super.key});

  @override
  ConsumerState<EmailPasswordScreen> createState() =>
      _EmailPasswordScreenState();
}

class _EmailPasswordScreenState extends ConsumerState<EmailPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isLoading = false;
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _mapAuthError(BuildContext context, Object error) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final errorStr = error.toString().toLowerCase();

    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final msg = error.message.toLowerCase();
      if (code == 'user_already_exists' ||
          msg.contains('already registered') ||
          msg.contains('already in use') ||
          msg.contains('user already exists')) {
        return isEn
            ? 'Email is already registered. Please sign in instead.'
            : 'البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول بدلاً من ذلك';
      }
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials') ||
          msg.contains('invalid email or password')) {
        return isEn
            ? 'Invalid email or password.'
            : 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      if (code == 'weak_password' ||
          msg.contains('password should be at least') ||
          msg.contains('weak password')) {
        return isEn
            ? 'Password must be at least 6 characters.'
            : 'كلمة المرور يجب ألا تقل عن 6 أحرف';
      }
      if (code == 'email_not_confirmed' ||
          msg.contains('email not confirmed')) {
        return isEn
            ? 'Please confirm your email before signing in.'
            : 'يرجى تأكيد بريدك الإلكتروني أولاً عبر الرابط المرسل إليك';
      }
      return error.message;
    }

    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection closed') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection error') ||
        errorStr.contains('connecttimeout')) {
      return isEn
          ? 'Unable to connect. Please check your internet connection.'
          : 'تعذر الاتصال، يرجى التحقق من اتصال الإنترنت';
    }

    return error.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      if (_isSignUp) {
        final hasSession = await notifier.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _selectedRole,
        );
        if (!mounted) return;
        if (!hasSession) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.confirmationEmailSent,
              ),
            ),
          );
          return;
        }
      } else {
        await notifier.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      final user = ref.read(authNotifierProvider).value;
      context.go(user?.isCaregiver == true ? '/caregiver' : '/patient');
    } catch (error) {
      if (!mounted) return;
      final message = _mapAuthError(context, error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
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
                  const SizedBox(height: 40),
                  Text(l10n.loginTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(l10n.loginSubtitle, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: l10n.nameLabel,
                        hintText: l10n.nameHint,
                        prefixIcon: const Icon(Icons.person_rounded, size: 28),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.nameRequiredError
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.roleLabel, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              key: const ValueKey('signup_role_patient_btn'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedRole == 'patient'
                                    ? theme.colorScheme.primaryContainer
                                    : null,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedRole = 'patient'),
                              icon: Icon(
                                _selectedRole == 'patient'
                                    ? Icons.check_circle_rounded
                                    : Icons.elderly_rounded,
                              ),
                              label: Text(l10n.rolePatient),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              key: const ValueKey('signup_role_caregiver_btn'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedRole == 'caregiver'
                                    ? theme.colorScheme.primaryContainer
                                    : null,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedRole = 'caregiver'),
                              icon: Icon(
                                _selectedRole == 'caregiver'
                                    ? Icons.check_circle_rounded
                                    : Icons.family_restroom_rounded,
                              ),
                              label: Text(l10n.roleCaregiver),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      hintText: l10n.emailHint,
                      prefixIcon: const Icon(Icons.email_rounded, size: 28),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return l10n.emailRequiredError;
                      if (!email.contains('@') || !email.contains('.')) {
                        return l10n.emailInvalidError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: _isSignUp
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequiredError;
                      }
                      if (value.length < 6) return l10n.passwordShortError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
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
                          : Text(
                              _isSignUp ? l10n.signUpButton : l10n.signInButton,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? l10n.switchToSignIn : l10n.switchToSignUp,
                      style: theme.textTheme.bodyLarge,
                    ),
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
