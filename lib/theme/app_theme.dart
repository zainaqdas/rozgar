import 'package:flutter/material.dart';

class AppColors {
  // Primary Teal
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal800 = Color(0xFF115E59);
  static const Color teal900 = Color(0xFF134E4A);
  static const Color teal950 = Color(0xFF042F2E);

  // Amber for Worker
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  // Slate
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Rose (notifications, warnings)
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose500 = Color(0xFFF43F5E);

  // Emerald (online status)
  static const Color emerald400 = Color(0xFF34D399);

  static const Color white = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: AppColors.slate50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.teal600,
        secondary: AppColors.amber500,
        surface: AppColors.white,
        error: AppColors.rose500,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.slate800,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.slate200),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal600,
          foregroundColor: AppColors.white,
          elevation: 2,
          shadowColor: AppColors.teal600.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.teal600, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.slate700,
          fontFamily: 'PlusJakartaSans',
        ),
        hintStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.slate400,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slate100,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.slate700,
          fontFamily: 'PlusJakartaSans',
        ),
        side: const BorderSide(color: AppColors.slate200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate200,
        thickness: 1,
        space: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.slate800),
        displayMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.slate800),
        headlineLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slate800),
        headlineMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate800),
        titleLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate800),
        titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
        titleSmall: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate700),
        bodyLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate700),
        bodyMedium: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate600),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500),
        labelLarge: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate600),
        labelMedium: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500),
        labelSmall: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate400),
      ),
    );
  }
}
