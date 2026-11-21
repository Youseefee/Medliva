import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class PreferencesStorage {
  Future<double?> readFontScale();
  Future<void> writeFontScale(double scale);

  Future<ThemeMode?> readThemeMode();
  Future<void> writeThemeMode(ThemeMode mode);

  Future<bool?> readReminderSoundEnabled();
  Future<void> writeReminderSoundEnabled({required bool enabled});
}

class SecurePreferencesStorage implements PreferencesStorage {
  SecurePreferencesStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _fontScaleKey = 'medliva_pref_font_scale';
  static const _themeModeKey = 'medliva_pref_theme_mode';
  static const _reminderSoundKey = 'medliva_pref_reminder_sound';

  @override
  Future<double?> readFontScale() async {
    try {
      final raw = await _storage.read(key: _fontScaleKey);
      if (raw == null) return null;
      final parsed = double.tryParse(raw);
      if (parsed == null) return null;
      return parsed.clamp(1.0, 1.3);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeFontScale(double scale) async {
    try {
      await _storage.write(
        key: _fontScaleKey,
        value: scale.clamp(1.0, 1.3).toStringAsFixed(2),
      );
    } catch (_) {}
  }

  @override
  Future<ThemeMode?> readThemeMode() async {
    try {
      final raw = await _storage.read(key: _themeModeKey);
      switch (raw) {
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
        case 'light':
          return ThemeMode.light;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    try {
      await _storage.write(key: _themeModeKey, value: mode.name);
    } catch (_) {}
  }

  @override
  Future<bool?> readReminderSoundEnabled() async {
    try {
      final raw = await _storage.read(key: _reminderSoundKey);
      if (raw == null) return null;
      return raw == 'true';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeReminderSoundEnabled({required bool enabled}) async {
    try {
      await _storage.write(
        key: _reminderSoundKey,
        value: enabled ? 'true' : 'false',
      );
    } catch (_) {}
  }
}

class InMemoryPreferencesStorage implements PreferencesStorage {
  InMemoryPreferencesStorage({
    this.fontScale,
    this.themeMode,
    this.reminderSoundEnabled,
  });

  double? fontScale;
  ThemeMode? themeMode;
  bool? reminderSoundEnabled;

  @override
  Future<double?> readFontScale() async => fontScale;

  @override
  Future<void> writeFontScale(double scale) async {
    fontScale = scale;
  }

  @override
  Future<ThemeMode?> readThemeMode() async => themeMode;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    themeMode = mode;
  }

  @override
  Future<bool?> readReminderSoundEnabled() async => reminderSoundEnabled;

  @override
  Future<void> writeReminderSoundEnabled({required bool enabled}) async {
    reminderSoundEnabled = enabled;
  }
}

final preferencesStorageProvider = Provider<PreferencesStorage>(
  (ref) => SecurePreferencesStorage(),
);
