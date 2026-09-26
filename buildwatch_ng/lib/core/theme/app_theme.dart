import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF64D2FF);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
  static const Color danger = Color(0xFFFF453A);
  static const Color background = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);
  static const Color border = Color(0xFF38383A);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF64D2FF), Color(0xFF5E5CE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  AppTextStyles._();
  static TextStyle get displayLarge => GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get displayMedium => GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get displaySmall => GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600);
  static TextStyle get headlineLarge => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get headlineMedium => GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600);
  static TextStyle get headlineSmall => GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600);
  static TextStyle get bodyLarge => GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get labelLarge => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500);
  static TextStyle get labelMedium => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);
  static TextStyle get labelSmall => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);
}

class AppTheme {
  AppTheme._();
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTextStyles.headlineSmall,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5),
  );
}
