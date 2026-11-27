import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color navyBlue = Color(0xFF0A1628);
  static const Color navyBlueMid = Color(0xFF142241);
  static const Color navyBlueLight = Color(0xFF1E3A5F);
  static const Color teal = Color(0xFF00BCD4);
  static const Color tealLight = Color(0xFF4DD0E1);
  static const Color tealDark = Color(0xFF00838F);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F7FA);
  static const Color lightGrey = Color(0xFFE8ECF1);
  static const Color grey = Color(0xFF9EA8B4);
  static const Color darkGrey = Color(0xFF4A5568);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Role accent colours
  static const Color citizenAccent = Color(0xFF00BCD4);
  static const Color adminAccent = Color(0xFF8B5CF6);
  static const Color operatorAccent = Color(0xFFF59E0B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.teal,
          onPrimary: AppColors.navyBlue,
          secondary: AppColors.tealLight,
          surface: AppColors.navyBlueMid,
          onSurface: AppColors.white,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.navyBlue,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navyBlueMid,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.navyBlueMid,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.navyBlue,
            minimumSize: const Size(112, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(96, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(72, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.navyBlueLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.navyBlueLight, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          labelStyle: const TextStyle(color: AppColors.grey),
          hintStyle: const TextStyle(color: AppColors.grey),
        ),
      );
}
