// lib/theme/app_theme.dart
// Central theme configuration for TenderPro AI
// Uses a professional navy + gold palette

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette — deep navy professionalism
  static const Color primary = Color(0xFF0D1B4B);       // Deep Navy
  static const Color primaryLight = Color(0xFF1A2E6E);   // Mid Navy
  static const Color primarySurface = Color(0xFFE8ECFB); // Navy tint bg

  // Accent — warm gold for CTAs
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFF3DC);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Neutrals
  static const Color text = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF1F5F9);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.white,
        background: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.text,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppColors.textMuted,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySurface,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
