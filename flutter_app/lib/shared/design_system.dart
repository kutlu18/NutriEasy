import 'package:flutter/material.dart';

class NutriColors {
  static const background = Color(0xFFF5F8F1);
  static const surface = Colors.white;
  static const ink = Color(0xFF121B17);
  static const muted = Color(0xFF707A77);
  static const leaf = Color(0xFF2E8C55);
  static const mint = Color(0xFFD0EBD6);
  static const coral = Color(0xFFE76C57);
  static const amber = Color(0xFFF0AF33);
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
      tertiary: NutriColors.amber,
      surface: NutriColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: NutriColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: NutriColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, color: NutriColors.ink),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: NutriColors.ink),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: NutriColors.ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: NutriColors.ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: NutriColors.ink),
        bodyLarge: TextStyle(color: NutriColors.ink),
        bodyMedium: TextStyle(color: NutriColors.ink),
        bodySmall: TextStyle(color: NutriColors.muted),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        color: NutriColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NutriColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: NutriColors.leaf,
        unselectedItemColor: NutriColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
