class AppConfig {
  AppConfig._();

  /// Set to true for production builds with
  /// `--dart-define=PRODUCTION=true`. Production builds require an HTTPS
  /// API base URL (see [apiBaseUrl]).
  static const bool isProductionBuild = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  /// API base URL.
  ///
  /// Pass it explicitly with `--dart-define=API_BASE_URL=...`.
  /// The default is the Android emulator host and is for local development
  /// only; it does not work on a physical device or in production.
  /// Production builds refuse any non-HTTPS value.
  static String get apiBaseUrl {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    );
    if (isProductionBuild && !url.startsWith('https://')) {
      throw StateError(
        'Production builds require an HTTPS API_BASE_URL. '
        'Pass it with --dart-define=API_BASE_URL=https://...',
      );
    }
    return url;
  }

  /// Supabase project URL. There is deliberately no hard-coded default:
  /// pass it with `--dart-define=SUPABASE_URL=https://YOUR_SUPABASE_URL`
  /// (see infra/.env.example and run.ps1, which forward it for you).
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    if (url.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL. Pass it with '
        '--dart-define=SUPABASE_URL=https://YOUR_SUPABASE_URL',
      );
    }
    if (!url.startsWith('https://')) {
      throw StateError('SUPABASE_URL must be an https URL.');
    }
    return url;
  }

  /// Supabase publishable key. There is deliberately no hard-coded default:
  /// pass it with `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`
  /// (or the legacy `--dart-define=SUPABASE_ANON_KEY=...`).
  /// Never commit a real key to this repository.
  static String get supabasePublishableKey {
    const key = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
    if (key.isEmpty) {
      throw StateError(
        'Missing SUPABASE_PUBLISHABLE_KEY. Pass it with '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY',
      );
    }
    return key;
  }
}
