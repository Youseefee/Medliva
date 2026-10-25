import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/config/app_config.dart';
import 'package:medliva/core/router/app_router.dart';
import 'package:medliva/core/theme/app_theme.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  // Local medication reminders are optional: if the platform refuses to
  // initialize them the app still starts and every dose stays usable.
  final reminderService = LocalReminderService();
  await reminderService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localReminderServiceProvider.overrideWithValue(reminderService),
      ],
      child: const MedlivaApp(),
    ),
  );
}

class FontScaleNotifier extends Notifier<double> {
  @override
  double build() => 1;

  double updateScale(double scale) => state = scale;
}

final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);

class MedlivaApp extends ConsumerWidget {
  const MedlivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final userLanguage = ref.watch(authNotifierProvider).value?.language;
    final locale = Locale(userLanguage == 'en' ? 'en' : 'ar');
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      title: 'ميدليفا | Medliva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(fontScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
