import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// GigCredit Design Token System — Typography
/// Font: Inter family (all weights from Regular to Black)
/// All text colors mapped to green-theme palette
class AppTypography {
  AppTypography._();

  // ═══════════════════════════════════════════════════════════════════════
  // DISPLAY (Hero headings on gradient backgrounds)
  // ═══════════════════════════════════════════════════════════════════════

  static final TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static final TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static final TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // HEADLINE (Section headers, card titles)
  // ═══════════════════════════════════════════════════════════════════════

  static final TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    height: 1.25,
  );
  static final TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static final TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // TITLE (App bar titles, form headings)
  // ═══════════════════════════════════════════════════════════════════════

  static final TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // BODY (Paragraphs, descriptions)
  // ═══════════════════════════════════════════════════════════════════════

  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    height: 1.5,
  );
  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    height: 1.55,
  );
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // LABEL (Buttons, chips, navigation)
  // ═══════════════════════════════════════════════════════════════════════

  static final TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
  static final TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // SPECIALTY STYLES
  // ═══════════════════════════════════════════════════════════════════════

  /// Score number (72px, very bold)
  static final TextStyle scoreNumber = GoogleFonts.inter(
    fontSize: 72, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
    letterSpacing: -2,
  );

  /// Grade letter (36px)
  static final TextStyle gradeLetter = GoogleFonts.inter(
    fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
  );

  /// Caption (11px muted)
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );

  /// Button text (CTA style)
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
    letterSpacing: 0.5,
  );

  /// Chip text
  static final TextStyle chip = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600,
  );

  /// Section label (11px uppercase tracking)
  static final TextStyle sectionLabel = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted,
    letterSpacing: 1.0,
  );

  /// Stats number on hero band
  static final TextStyle statNumber = GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
  );

  /// Stats label below number
  static final TextStyle statLabel = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70,
  );

  /// Eyebrow chip text
  static final TextStyle eyebrow = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
  );

  /// Nav pill text
  static final TextStyle navPill = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );

  /// Brand name in header
  static final TextStyle brandName = GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  /// Hero heading (white on green)
  static final TextStyle heroHeading = GoogleFonts.inter(
    fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white,
    height: 1.2,
  );

  /// Hero body (white semi-transparent)
  static final TextStyle heroBody = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xD1FFFFFF),
    height: 1.65,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // THEME INTEGRATION
  // ═══════════════════════════════════════════════════════════════════════

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
