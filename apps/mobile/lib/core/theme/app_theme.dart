import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Cairo';

  static const Color primaryColor = Color(0xFF00796B); // Medical Teal
  static const Color primaryDark = Color(0xFF004D40);
  static const Color secondaryColor = Color(0xFF0288D1); // Soft Blue
  static const Color surfaceColor = Color(0xFFF9FAFB);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        height: 1.2,
      ).copyWith(color: primary),
      displayMedium: const TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        height: 1.2,
      ).copyWith(color: primary),
      displaySmall: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        height: 1.25,
      ).copyWith(color: primary),
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        height: 1.3,
      ).copyWith(color: primary),
      headlineMedium: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        height: 1.3,
      ).copyWith(color: primary),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.3,
      ).copyWith(color: primary),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.3,
      ).copyWith(color: primary),
      titleMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.35,
      ).copyWith(color: primary),
      titleSmall: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.35,
      ).copyWith(color: primary),
      bodyLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        fontFamily: fontFamily,
        height: 1.5,
      ).copyWith(color: primary),
      bodyMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        fontFamily: fontFamily,
        height: 1.4,
      ).copyWith(color: secondary),
      bodySmall: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        fontFamily: fontFamily,
        height: 1.4,
      ).copyWith(color: secondary),
      labelLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
      ).copyWith(color: primary),
      labelMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ).copyWith(color: secondary),
      labelSmall: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ).copyWith(color: secondary),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fontFamily: fontFamily,
      fontFamilyFallback: const [fontFamily],
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: textSecondary,
        ),
      ),
      textTheme: _buildTextTheme(
        primary: textPrimary,
        secondary: textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: primaryColor, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 18,
          color: textSecondary,
          fontFamily: fontFamily,
        ),
        hintStyle: TextStyle(
          fontSize: 18,
          color: Color(0xFF94A3B8),
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkSurface = Color(0xFF121826);
    const darkTextPrimary = Color(0xFFF1F5F9);
    const darkTextSecondary = Color(0xFF94A3B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fontFamily: fontFamily,
      fontFamilyFallback: const [fontFamily],
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: const Color(0xFF26A69A),
        secondary: const Color(0xFF4FC3F7),
        surface: darkSurface,
        error: const Color(0xFFEF5350),
      ),
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: darkTextSecondary,
        ),
      ),
      textTheme: _buildTextTheme(
        primary: darkTextPrimary,
        secondary: darkTextSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF26A69A),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E293B),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF26A69A), width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 18,
          color: darkTextSecondary,
          fontFamily: fontFamily,
        ),
        hintStyle: TextStyle(
          fontSize: 18,
          color: Color(0xFF64748B),
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}
