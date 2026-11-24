import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Brand colors
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color primaryTealDark = Color(0xFF115E59);
  static const Color primaryTealLight = Color(0xFF14B8A6);

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  // Light Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceMuted = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Palette
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF1E2640);
  static const Color darkSurfaceMuted = Color(0xFF28334E);
  static const Color darkBorder = Color(0xFF2D3748);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // ===================== LIGHT THEME =====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      fontFamily: 'DM Sans',
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightSurface,
      canvasColor: lightBg,
      dividerColor: lightBorder,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        onPrimary: Colors.white,
        secondary: primaryBlue,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        background: lightBg,
        onBackground: lightTextPrimary,
        error: Color(0xFFDC2626),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: lightBorder),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTeal,
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ===================== DARK THEME =====================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      fontFamily: 'DM Sans',
      primaryColor: primaryTealLight,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      canvasColor: darkBg,
      dividerColor: darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: primaryTealLight,
        onPrimary: Colors.white,
        secondary: Color(0xFF38BDF8),
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        background: darkBg,
        onBackground: darkTextPrimary,
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTealLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTealLight,
          side: const BorderSide(color: darkBorder),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTealLight,
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryTealLight, width: 1.5),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

// Backward-compatibility alias
final ThemeData appTheme = AppTheme.lightTheme;
