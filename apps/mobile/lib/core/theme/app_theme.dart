import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Cairo';

  // Light Palette
  static const Color primaryColor = Color(0xFF00796B); // Medical Teal
  static const Color primaryDark = Color(0xFF004D40);
  static const Color secondaryColor = Color(0xFF0288D1); // Soft Blue
  static const Color surfaceColor = Color(0xFFF9FAFB);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF15803D);
  static const Color warningColor = Color(0xFFD97706);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);

  // Dark Palette (high contrast, accessible medical dark)
  static const Color darkScaffoldBackground = Color(0xFF0B1120); // deep slate navy
  static const Color darkSurface = Color(0xFF0F172A); // slate 900
  static const Color darkCard = Color(0xFF1E293B); // slate 800
  static const Color darkBorder = Color(0xFF334155); // slate 700
  static const Color darkPrimary = Color(0xFF2DD4BF); // accessible teal (teal 400)
  static const Color darkPrimaryContainer = Color(0xFF115E59); // teal 800
  static const Color darkOnPrimaryContainer = Color(0xFFCCFBF1); // teal 100
  static const Color darkSecondary = Color(0xFF38BDF8); // sky 400
  static const Color darkSecondaryContainer = Color(0xFF0C4A6E); // sky 900
  static const Color darkOnSecondaryContainer = Color(0xFFE0F2FE); // sky 100
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // slate 50
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // slate 300
  static const Color darkOutline = Color(0xFF475569); // slate 600
  static const Color darkOutlineVariant = Color(0xFF334155); // slate 700
  static const Color darkError = Color(0xFFF87171); // red 400
  static const Color darkSuccessColor = Color(0xFF4ADE80); // green 400
  static const Color darkWarningColor = Color(0xFFFBBF24); // amber 400

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
    final textTheme = _buildTextTheme(
      primary: textPrimary,
      secondary: textSecondary,
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0F2F1),
      onPrimaryContainer: Color(0xFF004D40),
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE1F5FE),
      onSecondaryContainer: Color(0xFF01579B),
      error: errorColor,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFFE2E8F0),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF8FAFC),
      surfaceContainer: Color(0xFFF1F5F9),
      surfaceContainerHigh: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFFCBD5E1),
    );

    return ThemeData(
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fontFamily: fontFamily,
      fontFamilyFallback: const [fontFamily],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceColor,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFE0F2F1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
              color: primaryColor,
            );
          }
          return const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 26);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          color: textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFFE0F2F1),
        disabledColor: const Color(0xFFE2E8F0),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: textPrimary,
        iconColor: primaryColor,
        contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
          foregroundColor: primaryColor,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
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
          foregroundColor: primaryColor,
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: errorColor, width: 2.5),
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
    final textTheme = _buildTextTheme(
      primary: darkTextPrimary,
      secondary: darkTextSecondary,
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: Color(0xFF042F2E),
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkSecondary,
      onSecondary: Color(0xFF082F49),
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: darkOnSecondaryContainer,
      error: darkError,
      onError: Color(0xFF450A0A),
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      surfaceContainerLowest: darkScaffoldBackground,
      surfaceContainerLow: Color(0xFF131D31),
      surfaceContainer: darkCard,
      surfaceContainerHigh: Color(0xFF27354A),
      surfaceContainerHighest: darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fontFamily: fontFamily,
      fontFamilyFallback: const [fontFamily],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkScaffoldBackground,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: darkPrimaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
              color: darkPrimary,
            );
          }
          return const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
            color: darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkOnPrimaryContainer, size: 26);
          }
          return const IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkCard,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          color: darkTextSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF131D31),
        selectedColor: darkPrimaryContainer,
        disabledColor: darkBorder,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkPrimary,
        ),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: darkTextPrimary,
        iconColor: darkPrimary,
        contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          color: darkTextPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF042F2E),
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
          foregroundColor: darkPrimary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: darkOutline, width: 1.5),
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
          foregroundColor: darkPrimary,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: darkPrimary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: darkError, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: darkError, width: 2.5),
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

extension AppThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get successColor =>
      isDarkMode ? AppTheme.darkSuccessColor : AppTheme.successColor;
  Color get warningColor =>
      isDarkMode ? AppTheme.darkWarningColor : AppTheme.warningColor;
}
