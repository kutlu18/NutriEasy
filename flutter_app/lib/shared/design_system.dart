import 'package:flutter/material.dart';

class NutriColors {
  static const background = Color(0xFFFAF9F6);
  static const surface = Colors.white;
  static const surfaceLow = Color(0xFFF4F3F1);
  static const surfaceHigh = Color(0xFFE9E8E5);
  static const ink = Color(0xFF1A1C1A);
  static const muted = Color(0xFF3F4945);
  static const outline = Color(0xFFBFC9C4);
  static const leaf = Color(0xFF004D40);
  static const leafDark = Color(0xFF00342B);
  static const mint = Color(0xFFBEEBE7);
  static const mintSoft = Color(0xFFE6F3EF);
  static const coral = Color(0xFFFD8863);
  static const amber = Color(0xFFFFB59E);
  static const analysisBackground = Color(0xFF09090B);
  static const analysisSurface = Color(0xFF121215);
  static const analysisBorder = Color(0xFF27272A);
  static const analysisAccent = Color(0xFFA78BFA);
  static const success = Color(0xFF34D399);

  static const cardShadow = BoxShadow(
    color: Color(0x0D004D40),
    blurRadius: 20,
    offset: Offset(0, 8),
  );
}

class NutriTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: NutriColors.leaf,
      surface: NutriColors.surface,
      brightness: Brightness.light,
    ).copyWith(
      primary: NutriColors.leaf,
      secondary: NutriColors.coral,
      tertiary: NutriColors.mint,
      surface: NutriColors.surface,
      onSurface: NutriColors.ink,
      outline: NutriColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: NutriColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: NutriColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: NutriColors.ink,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
            fontSize: 34,
            height: 1.18,
            fontWeight: FontWeight.w800,
            color: NutriColors.ink),
        headlineLarge: TextStyle(
            fontSize: 34,
            height: 1.18,
            fontWeight: FontWeight.w800,
            color: NutriColors.ink),
        headlineMedium: TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: NutriColors.ink),
        headlineSmall: TextStyle(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: NutriColors.ink),
        titleLarge: TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: NutriColors.ink),
        titleMedium: TextStyle(
            fontSize: 17,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: NutriColors.ink),
        titleSmall: TextStyle(
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: NutriColors.ink),
        bodyLarge:
            TextStyle(fontSize: 17, height: 1.45, color: NutriColors.ink),
        bodyMedium:
            TextStyle(fontSize: 15, height: 1.45, color: NutriColors.ink),
        bodySmall:
            TextStyle(fontSize: 13, height: 1.35, color: NutriColors.muted),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
      cardTheme: const CardThemeData(
        color: NutriColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NutriColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: NutriColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NutriColors.leaf, width: 1.4),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: NutriColors.leaf,
        unselectedItemColor: NutriColors.muted,
        backgroundColor: NutriColors.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
