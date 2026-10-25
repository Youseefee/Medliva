import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:medliva/main.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  String _selectedLanguage = 'ar';
  String _selectedRole = 'patient';
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save({String? overrideLanguage, String? overrideRole}) async {
    final language = overrideLanguage ?? _selectedLanguage;
    setState(() {
      _isSaving = true;
      _selectedLanguage = language;
      if (overrideRole != null) {
        _selectedRole = overrideRole;
      }
    });

    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
            language: language,
            role: overrideRole,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSaved)),
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;
    final fontScale = ref.watch(fontScaleProvider);

    if (!_initialized && user != null) {
      _nameController.text = user.name ?? '';
      _selectedLanguage = user.language;
      _selectedRole = user.role;
      _initialized = true;
    }

    final displayName =
        (user?.name != null && user!.name!.isNotEmpty)
            ? user.name!
            : (user?.email ?? l10n.appName);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF00796B),
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF00796B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Header Card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFE0F2F1),
                            child: Icon(
                              Icons.person_rounded,
                              size: 38,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.settingsTitle,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.nameLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('profile_name_field'),
                        controller: _nameController,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: l10n.nameHint,
                          prefixIcon: const Icon(
                            Icons.person_rounded,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Language Toggle Card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.language_rounded,
                            color: Color(0xFF00796B),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.languageLabel,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton.icon(
                                key: const ValueKey('lang_ar_button'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _selectedLanguage == 'ar'
                                      ? const Color(0xFF00796B)
                                      : Colors.grey.shade100,
                                  foregroundColor: _selectedLanguage == 'ar'
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideLanguage: 'ar'),
                                icon: Icon(
                                  _selectedLanguage == 'ar'
                                      ? Icons.check_circle_rounded
                                      : Icons.language_rounded,
                                ),
                                label: Text(
                                  l10n.languageArabic,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton.icon(
                                key: const ValueKey('lang_en_button'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _selectedLanguage == 'en'
                                      ? const Color(0xFF00796B)
                                      : Colors.grey.shade100,
                                  foregroundColor: _selectedLanguage == 'en'
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideLanguage: 'en'),
                                icon: Icon(
                                  _selectedLanguage == 'en'
                                      ? Icons.check_circle_rounded
                                      : Icons.language_rounded,
                                ),
                                label: Text(
                                  l10n.languageEnglish,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Font Size Scaling Card (عادي / كبير / كبير جداً)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.text_fields_rounded,
                            color: Color(0xFF00796B),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.fontSizeLabel,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final option in [
                            (
                              key: 'font_scale_normal',
                              scale: 1.0,
                              label: l10n.fontSizeNormal,
                            ),
                            (
                              key: 'font_scale_large',
                              scale: 1.15,
                              label: l10n.fontSizeLarge,
                            ),
                            (
                              key: 'font_scale_xlarge',
                              scale: 1.3,
                              label: l10n.fontSizeExtraLarge,
                            ),
                          ])
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.symmetric(
                                  horizontal: 4,
                                ),
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    key: ValueKey(option.key),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          (fontScale - option.scale).abs() <
                                                  0.05
                                              ? const Color(0xFF00796B)
                                              : Colors.grey.shade100,
                                      foregroundColor:
                                          (fontScale - option.scale).abs() <
                                                  0.05
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                    onPressed: () => ref
                                        .read(fontScaleProvider.notifier)
                                        .updateScale(option.scale),
                                    child: Text(
                                      option.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Account Role Switcher Card (Patient / Caregiver)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.switch_account_rounded,
                            color: Color(0xFF00796B),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.roleLabel,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                key: const ValueKey('role_patient_button'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _selectedRole == 'patient'
                                      ? const Color(0xFF00796B)
                                      : Colors.grey.shade100,
                                  foregroundColor: _selectedRole == 'patient'
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideRole: 'patient'),
                                icon: const Icon(Icons.elderly_rounded),
                                label: Text(l10n.rolePatient),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                key: const ValueKey('role_caregiver_button'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      _selectedRole == 'caregiver'
                                          ? const Color(0xFF00796B)
                                          : Colors.grey.shade100,
                                  foregroundColor:
                                      _selectedRole == 'caregiver'
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideRole: 'caregiver'),
                                icon:
                                    const Icon(Icons.family_restroom_rounded),
                                label: Text(l10n.roleCaregiver),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Caregivers Navigation Card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  key: const ValueKey('settings_caregivers_tile'),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  title: Text(
                    l10n.caregiversSettingsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(l10n.caregiversSettingsSub),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    _selectedRole == 'caregiver'
                        ? '/caregiver/pair'
                        : '/caregiver/pairing-code',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notification Sound Card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  title: Text(
                    l10n.notificationSoundTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(l10n.notificationSoundSub),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Offline Sync Status Card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(
                      Icons.cloud_done_rounded,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  title: Text(
                    l10n.offlineSyncTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(l10n.offlineSyncSub),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  key: const ValueKey('profile_save_button'),
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(l10n.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
