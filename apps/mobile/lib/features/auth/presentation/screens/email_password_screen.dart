import 'dart:async' show unawaited;

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
  bool _obscurePassword = true;
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _mapAuthError(AppLocalizations l10n, Object error) {
    final errorStr = error.toString().toLowerCase();

    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final msg = error.message.toLowerCase();
      if (code == 'user_already_exists' ||
          msg.contains('already registered') ||
          msg.contains('already in use') ||
          msg.contains('user already exists')) {
        return l10n.authErrorUserAlreadyExists;
      }
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials') ||
          msg.contains('invalid email or password')) {
        return l10n.authErrorInvalidCredentials;
      }
      if (code == 'weak_password' ||
          msg.contains('password should be at least') ||
          msg.contains('weak password')) {
        return l10n.authErrorWeakPassword;
      }
      if (code == 'email_not_confirmed' ||
          msg.contains('email not confirmed')) {
        return l10n.authErrorEmailNotConfirmed;
      }
      return error.message.isNotEmpty ? error.message : l10n.authErrorGeneric;
    }

    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection closed') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection error') ||
        errorStr.contains('connecttimeout')) {
      return l10n.authErrorNetwork;
    }

    return l10n.authErrorGeneric;
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
      if (GoRouter.maybeOf(context) != null) {
        context.go(user?.isCaregiver == true ? '/caregiver' : '/patient');
      }
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = _mapAuthError(l10n, error);
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
    final cardBgColor =
        theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
    final cardBorderColor = theme.colorScheme.outlineVariant;
    final unselectedBtnBg =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.appName,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appTagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSignUp ? l10n.signUpTitle : l10n.loginTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSignUp ? l10n.signUpSubtitle : l10n.loginSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.nameLabel,
                              hintText: l10n.nameHint,
                              prefixIcon: const Icon(
                                Icons.person_rounded,
                                size: 28,
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? l10n.nameRequiredError
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.roleLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 54,
                                  ),
                                  child: OutlinedButton.icon(
                                    key: const ValueKey(
                                      'signup_role_patient_btn',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      backgroundColor:
                                          _selectedRole == 'patient'
                                              ? theme.colorScheme.primary
                                              : unselectedBtnBg,
                                      foregroundColor:
                                          _selectedRole == 'patient'
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                      side: BorderSide(
                                        color: _selectedRole == 'patient'
                                            ? theme.colorScheme.primary
                                            : cardBorderColor,
                                      ),
                                    ),
                                    onPressed: () => setState(
                                      () => _selectedRole = 'patient',
                                    ),
                                    icon: Icon(
                                      _selectedRole == 'patient'
                                          ? Icons.check_circle_rounded
                                          : Icons.elderly_rounded,
                                      color: _selectedRole == 'patient'
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                    ),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        l10n.rolePatient,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 54,
                                  ),
                                  child: OutlinedButton.icon(
                                    key: const ValueKey(
                                      'signup_role_caregiver_btn',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      backgroundColor:
                                          _selectedRole == 'caregiver'
                                              ? theme.colorScheme.primary
                                              : unselectedBtnBg,
                                      foregroundColor:
                                          _selectedRole == 'caregiver'
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                      side: BorderSide(
                                        color: _selectedRole == 'caregiver'
                                            ? theme.colorScheme.primary
                                            : cardBorderColor,
                                      ),
                                    ),
                                    onPressed: () => setState(
                                      () => _selectedRole = 'caregiver',
                                    ),
                                    icon: Icon(
                                      _selectedRole == 'caregiver'
                                          ? Icons.check_circle_rounded
                                          : Icons.family_restroom_rounded,
                                      color: _selectedRole == 'caregiver'
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                    ),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        l10n.roleCaregiver,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
                          textDirection: TextDirection.ltr,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.emailLabel,
                            hintText: l10n.emailHint,
                            prefixIcon: const Icon(
                              Icons.email_rounded,
                              size: 28,
                            ),
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
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_isLoading) unawaited(_submit());
                          },
                          autofillHints: _isSignUp
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            prefixIcon: const Icon(
                              Icons.lock_rounded,
                              size: 28,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? l10n.showPassword
                                  : l10n.hidePassword,
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 24,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.passwordRequiredError;
                            }
                            if (value.length < 6) {
                              return l10n.passwordShortError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? SizedBox(
                                    height: 28,
                                    width: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : Text(
                                    _isSignUp
                                        ? l10n.signUpButton
                                        : l10n.signInButton,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp
                                ? l10n.switchToSignIn
                                : l10n.switchToSignUp,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
