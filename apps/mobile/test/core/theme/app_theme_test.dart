import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/storage/preferences_storage.dart';
import 'package:medliva/core/theme/app_theme.dart';
import 'package:medliva/main.dart';

void main() {
  group('AppTheme font configuration', () {
    test('fontFamily constant is configured as Cairo', () {
      expect(AppTheme.fontFamily, 'Cairo');
    });

    test('lightTheme textTheme applies Cairo to all text styles', () {
      final textTheme = AppTheme.lightTheme.textTheme;

      expect(textTheme.headlineLarge?.fontFamily, 'Cairo');
      expect(textTheme.headlineMedium?.fontFamily, 'Cairo');
      expect(textTheme.headlineSmall?.fontFamily, 'Cairo');
      expect(textTheme.titleLarge?.fontFamily, 'Cairo');
      expect(textTheme.titleMedium?.fontFamily, 'Cairo');
      expect(textTheme.titleSmall?.fontFamily, 'Cairo');
      expect(textTheme.bodyLarge?.fontFamily, 'Cairo');
      expect(textTheme.bodyMedium?.fontFamily, 'Cairo');
      expect(textTheme.bodySmall?.fontFamily, 'Cairo');
      expect(textTheme.labelLarge?.fontFamily, 'Cairo');
      expect(textTheme.labelMedium?.fontFamily, 'Cairo');
      expect(textTheme.labelSmall?.fontFamily, 'Cairo');
      expect(textTheme.displayLarge?.fontFamily, 'Cairo');
      expect(textTheme.displayMedium?.fontFamily, 'Cairo');
      expect(textTheme.displaySmall?.fontFamily, 'Cairo');
    });

    test('component themes explicitly inherit Cairo font', () {
      final theme = AppTheme.lightTheme;

      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Cairo');
      expect(theme.dialogTheme.titleTextStyle?.fontFamily, 'Cairo');
      expect(theme.dialogTheme.contentTextStyle?.fontFamily, 'Cairo');
      expect(theme.inputDecorationTheme.labelStyle?.fontFamily, 'Cairo');
      expect(theme.inputDecorationTheme.hintStyle?.fontFamily, 'Cairo');

      final elevatedTextStyle =
          theme.elevatedButtonTheme.style?.textStyle?.resolve({});
      expect(elevatedTextStyle?.fontFamily, 'Cairo');

      final outlinedTextStyle =
          theme.outlinedButtonTheme.style?.textStyle?.resolve({});
      expect(outlinedTextStyle?.fontFamily, 'Cairo');

      final textBtnStyle =
          theme.textButtonTheme.style?.textStyle?.resolve({});
      expect(textBtnStyle?.fontFamily, 'Cairo');
    });

    test('darkTheme has Cairo on textTheme and primaryTextTheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Cairo');
      expect(theme.textTheme.titleLarge?.fontFamily, 'Cairo');
      expect(theme.textTheme.headlineMedium?.fontFamily, 'Cairo');
    });

    testWidgets('renders Text with Cairo font without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: Text('ميدليفا للأدوية - Medliva'),
            ),
          ),
        ),
      );

      expect(find.text('ميدليفا للأدوية - Medliva'), findsOneWidget);
    });

    test('elderly font floor and focusedErrorBorder configured on both themes',
        () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(
          theme.dialogTheme.contentTextStyle?.fontSize,
          greaterThanOrEqualTo(18),
        );
        expect(
          theme.snackBarTheme.contentTextStyle?.fontSize,
          greaterThanOrEqualTo(18),
        );
        expect(theme.inputDecorationTheme.focusedErrorBorder, isNotNull);
        expect(theme.outlinedButtonTheme.style?.foregroundColor, isNotNull);
      }
    });
  });

  group('Persisted UI preferences', () {
    test('ThemeModeNotifier.toggle resolves ThemeMode.system dark brightness',
        () async {
      final prefs = InMemoryPreferencesStorage();
      final container = ProviderContainer(
        overrides: [
          preferencesStorageProvider.overrideWithValue(prefs),
          initialThemeModeProvider.overrideWithValue(ThemeMode.system),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
      container.read(themeModeProvider.notifier).toggle(isCurrentlyDark: true);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.themeMode, ThemeMode.light);

      container.read(themeModeProvider.notifier).toggle(isCurrentlyDark: false);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.themeMode, ThemeMode.dark);
    });

    test('FontScaleNotifier and ReminderSoundNotifier persist updates', () {
      final prefs = InMemoryPreferencesStorage();
      final container = ProviderContainer(
        overrides: [preferencesStorageProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(fontScaleProvider.notifier).updateScale(1.3);
      expect(container.read(fontScaleProvider), 1.3);
      expect(prefs.fontScale, 1.3);

      container.read(reminderSoundProvider.notifier).setEnabled(enabled: false);
      expect(container.read(reminderSoundProvider), isFalse);
      expect(prefs.reminderSoundEnabled, isFalse);
    });
  });
}
