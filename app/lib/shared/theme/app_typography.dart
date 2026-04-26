import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Display styles
  static final TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
  );
  static final TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static final TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  // Headline
  static final TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static final TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Title
  static final TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Body
  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // Label
  static final TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
  static final TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );

  // Specialty
  static final TextStyle scoreNumber = GoogleFonts.inter(
    fontSize: 72, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
    letterSpacing: -2,
  );
  static final TextStyle gradeLetter = GoogleFonts.inter(
    fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
  );
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textTertiary,
  );
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );
  static final TextStyle chip = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
  );

  // Convenience textTheme getter (for ThemeData)
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}

