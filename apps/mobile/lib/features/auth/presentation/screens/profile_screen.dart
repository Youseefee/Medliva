import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/core/theme/app_theme.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/offline_adherence_queue.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:medliva/main.dart';

final FutureProvider<int> offlinePendingCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final store = ref.watch(offlineQueueStoreProvider);
      final items = await store.readItems();
      return items.length;
    });

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
  bool _isSyncing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save({String? overrideLanguage, String? overrideRole}) async {
    final prevLanguage = _selectedLanguage;
    final prevRole = _selectedRole;
    final language = overrideLanguage ?? _selectedLanguage;
    final roleChanged = overrideRole != null && overrideRole != prevRole;

    setState(() {
      _isSaving = true;
      _selectedLanguage = language;
      if (overrideRole != null) {
        _selectedRole = overrideRole;
      }
    });

    try {
      final updated = await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(
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
      if (roleChanged) {
        ref.read(selectedPatientIdProvider.notifier).clear();
        if (GoRouter.maybeOf(context) != null) {
          context.go(updated.isCaregiver ? '/caregiver' : '/patient');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedLanguage = prevLanguage;
        _selectedRole = prevRole;
      });
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

  Future<void> _syncOfflineQueue() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await ref.read(offlineAdherenceQueueProvider).flushQueue();
      ref.invalidate(offlinePendingCountProvider);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.offlineSyncSuccess)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
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
    final currentThemeMode = ref.watch(themeModeProvider);
    final reminderSoundEnabled = ref.watch(reminderSoundProvider);
    final pendingSyncCount =
        ref.watch(offlinePendingCountProvider).value ?? 0;

    if (!_initialized && user != null) {
      _nameController.text = user.name ?? '';
      _selectedLanguage = user.language;
      _selectedRole = user.role;
      _initialized = true;
    }

    final displayName = (user?.name != null && user!.name!.trim().isNotEmpty)
        ? user.name!.trim()
        : (user?.email ?? l10n.appName);

    final cardBgColor =
        theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
    final cardBorderColor = theme.colorScheme.outlineVariant;
    final unselectedBtnBg =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
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
              // 1. User Header Card
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
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
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person_rounded,
                              size: 38,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.settingsTitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.nameLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('profile_name_field'),
                        controller: _nameController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
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

              // 2. Theme Mode Switcher Card
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.appearanceTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final option in [
                            (
                              key: 'theme_light_button',
                              mode: ThemeMode.light,
                              icon: Icons.light_mode_rounded,
                              label: l10n.themeLight,
                            ),
                            (
                              key: 'theme_dark_button',
                              mode: ThemeMode.dark,
                              icon: Icons.dark_mode_rounded,
                              label: l10n.themeDark,
                            ),
                            (
                              key: 'theme_system_button',
                              mode: ThemeMode.system,
                              icon: Icons.brightness_auto_rounded,
                              label: l10n.themeSystem,
                            ),
                          ])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 4,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 52,
                                  ),
                                  child: OutlinedButton.icon(
                                    key: ValueKey(option.key),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          currentThemeMode == option.mode
                                              ? theme.colorScheme.primary
                                              : unselectedBtnBg,
                                      foregroundColor:
                                          currentThemeMode == option.mode
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                      side: BorderSide(
                                        color: currentThemeMode == option.mode
                                            ? theme.colorScheme.primary
                                            : cardBorderColor,
                                      ),
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: 6,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: () => ref
                                        .read(themeModeProvider.notifier)
                                        .setThemeMode(option.mode),
                                    icon: Icon(
                                      option.icon,
                                      size: 20,
                                      color: currentThemeMode == option.mode
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                    ),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        option.label,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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

              // 3. Language Toggle Card
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.language_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.languageLabel,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 54),
                              child: OutlinedButton.icon(
                                key: const ValueKey('lang_ar_button'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  backgroundColor: _selectedLanguage == 'ar'
                                      ? theme.colorScheme.primary
                                      : unselectedBtnBg,
                                  foregroundColor: _selectedLanguage == 'ar'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  side: BorderSide(
                                    color: _selectedLanguage == 'ar'
                                        ? theme.colorScheme.primary
                                        : cardBorderColor,
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideLanguage: 'ar'),
                                icon: Icon(
                                  _selectedLanguage == 'ar'
                                      ? Icons.check_circle_rounded
                                      : Icons.language_rounded,
                                  color: _selectedLanguage == 'ar'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.languageArabic,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 18,
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
                              constraints: const BoxConstraints(minHeight: 54),
                              child: OutlinedButton.icon(
                                key: const ValueKey('lang_en_button'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  backgroundColor: _selectedLanguage == 'en'
                                      ? theme.colorScheme.primary
                                      : unselectedBtnBg,
                                  foregroundColor: _selectedLanguage == 'en'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  side: BorderSide(
                                    color: _selectedLanguage == 'en'
                                        ? theme.colorScheme.primary
                                        : cardBorderColor,
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideLanguage: 'en'),
                                icon: Icon(
                                  _selectedLanguage == 'en'
                                      ? Icons.check_circle_rounded
                                      : Icons.language_rounded,
                                  color: _selectedLanguage == 'en'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.languageEnglish,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 18,
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

              // 4. Font Size Scaling Card
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.text_fields_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.fontSizeLabel,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
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
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 4,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 52,
                                  ),
                                  child: OutlinedButton(
                                    key: ValueKey(option.key),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      backgroundColor:
                                          (fontScale - option.scale).abs() <
                                                  0.05
                                              ? theme.colorScheme.primary
                                              : unselectedBtnBg,
                                      foregroundColor:
                                          (fontScale - option.scale).abs() <
                                                  0.05
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                      side: BorderSide(
                                        color: (fontScale - option.scale)
                                                    .abs() <
                                                0.05
                                            ? theme.colorScheme.primary
                                            : cardBorderColor,
                                      ),
                                    ),
                                    onPressed: () => ref
                                        .read(fontScaleProvider.notifier)
                                        .updateScale(option.scale),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        option.label,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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

              // 5. Account Role Switcher Card (Patient / Caregiver)
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.switch_account_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.roleLabel,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 54),
                              child: OutlinedButton.icon(
                                key: const ValueKey('role_patient_button'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  backgroundColor: _selectedRole == 'patient'
                                      ? theme.colorScheme.primary
                                      : unselectedBtnBg,
                                  foregroundColor: _selectedRole == 'patient'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  side: BorderSide(
                                    color: _selectedRole == 'patient'
                                        ? theme.colorScheme.primary
                                        : cardBorderColor,
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideRole: 'patient'),
                                icon: Icon(
                                  Icons.elderly_rounded,
                                  color: _selectedRole == 'patient'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.rolePatient,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 54),
                              child: OutlinedButton.icon(
                                key: const ValueKey('role_caregiver_button'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  backgroundColor: _selectedRole == 'caregiver'
                                      ? theme.colorScheme.primary
                                      : unselectedBtnBg,
                                  foregroundColor: _selectedRole == 'caregiver'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  side: BorderSide(
                                    color: _selectedRole == 'caregiver'
                                        ? theme.colorScheme.primary
                                        : cardBorderColor,
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _save(overrideRole: 'caregiver'),
                                icon: Icon(
                                  Icons.family_restroom_rounded,
                                  color: _selectedRole == 'caregiver'
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.roleCaregiver,
                                    maxLines: 1,
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

              // 6. Caregivers Navigation Card
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: ListTile(
                  key: const ValueKey('settings_caregivers_tile'),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    l10n.caregiversSettingsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    l10n.caregiversSettingsSub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => context.push(
                    _selectedRole == 'caregiver'
                        ? '/caregiver/pair'
                        : '/caregiver/pairing-code',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 7. Notification Sound Toggle Card (persisted)
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: SwitchListTile(
                  key: const ValueKey('notification_sound_switch'),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      reminderSoundEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    l10n.notificationSoundTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    reminderSoundEnabled
                        ? l10n.reminderSoundEnabled
                        : l10n.reminderSoundMuted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: reminderSoundEnabled,
                  onChanged: (value) => ref
                      .read(reminderSoundProvider.notifier)
                      .setEnabled(enabled: value),
                ),
              ),
              const SizedBox(height: 12),

              // 8. Offline Sync Status Card (live queue status & sync action)
              Card(
                elevation: 0,
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cardBorderColor),
                ),
                child: ListTile(
                  key: const ValueKey('offline_sync_tile'),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      pendingSyncCount > 0
                          ? Icons.cloud_upload_rounded
                          : Icons.cloud_done_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    l10n.offlineSyncTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    pendingSyncCount > 0
                        ? l10n.offlineSyncPending(pendingSyncCount)
                        : l10n.offlineSyncSub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: pendingSyncCount > 0
                          ? context.warningColor
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: pendingSyncCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _isSyncing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : pendingSyncCount > 0
                          ? TextButton(
                              key: const ValueKey('offline_sync_now_button'),
                              onPressed: _syncOfflineQueue,
                              child: Text(l10n.offlineSyncNow),
                            )
                          : Icon(
                              Icons.check_circle_rounded,
                              color: context.successColor,
                              size: 30,
                            ),
                  onTap: pendingSyncCount > 0 ? _syncOfflineQueue : null,
                ),
              ),
              const SizedBox(height: 24),

              // 9. Save Button
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
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
