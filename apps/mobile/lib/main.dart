import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medliva/core/config/app_config.dart';
import 'package:medliva/core/router/app_router.dart';
import 'package:medliva/core/storage/preferences_storage.dart';
import 'package:medliva/core/theme/app_theme.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  final prefsStorage = SecurePreferencesStorage();
  final initialFontScale = await prefsStorage.readFontScale() ?? 1.0;
  final initialThemeMode = await prefsStorage.readThemeMode() ?? ThemeMode.light;
  final initialReminderSound =
      await prefsStorage.readReminderSoundEnabled() ?? true;

  // Local medication reminders are optional: if the platform refuses to
  // initialize them the app still starts and every dose stays usable.
  final reminderService = LocalReminderService();
  await reminderService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localReminderServiceProvider.overrideWithValue(reminderService),
        preferencesStorageProvider.overrideWithValue(prefsStorage),
        initialFontScaleProvider.overrideWithValue(initialFontScale),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialReminderSoundProvider.overrideWithValue(initialReminderSound),
      ],
      child: const MedlivaApp(),
    ),
  );
}

final initialFontScaleProvider = Provider<double>((ref) => 1.0);
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);
final initialReminderSoundProvider = Provider<bool>((ref) => true);

class FontScaleNotifier extends Notifier<double> {
  @override
  double build() => ref.watch(initialFontScaleProvider);

  double updateScale(double scale) {
    final clamped = scale.clamp(1.0, 1.3);
    state = clamped;
    unawaited(ref.read(preferencesStorageProvider).writeFontScale(clamped));
    return clamped;
  }
}

final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  ThemeMode setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(ref.read(preferencesStorageProvider).writeThemeMode(mode));
    return mode;
  }

  void toggle({bool? isCurrentlyDark}) {
    final dark = isCurrentlyDark ?? (state == ThemeMode.dark);
    setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ReminderSoundNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialReminderSoundProvider);

  bool setEnabled({required bool enabled}) {
    state = enabled;
    unawaited(
      ref
          .read(preferencesStorageProvider)
          .writeReminderSoundEnabled(enabled: enabled),
    );
    return enabled;
  }

  void toggle() => setEnabled(enabled: !state);
}

final reminderSoundProvider = NotifierProvider<ReminderSoundNotifier, bool>(
  ReminderSoundNotifier.new,
);

class MedlivaApp extends ConsumerWidget {
  const MedlivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final userLanguage = ref.watch(authNotifierProvider).value?.language;
    final locale = Locale(userLanguage == 'en' ? 'en' : 'ar');
    final fontScale = ref.watch(fontScaleProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appName ?? 'Medliva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final systemScale = mediaQuery.textScaler.scale(1);
        final combinedScale = (systemScale * fontScale).clamp(1.0, 1.8);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(combinedScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
