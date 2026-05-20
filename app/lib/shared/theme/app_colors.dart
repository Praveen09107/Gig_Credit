import 'package:flutter/material.dart';

/// GigCredit Design System — Green-Dominant Fintech Palette
/// Light mode base with green brand accents throughout
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════
  // BRAND GREENS
  // ═══════════════════════════════════════════════════════════════════════
  static const Color greenPrimary = Color(0xFF1A6B3C);   // Deep forest green
  static const Color greenMid     = Color(0xFF2E8B57);   // Sea green
  static const Color greenBright  = Color(0xFF3CC068);   // Bright accent green
  static const Color greenMint    = Color(0xFFA8E6CF);   // Mint highlight
  static const Color greenMuted   = Color(0xFFE8F5E9);   // Very light green tint

  // ═══════════════════════════════════════════════════════════════════════
  // BACKGROUNDS
  // ═══════════════════════════════════════════════════════════════════════
  static const Color bgScreen    = Color(0xFFF5F7F5);   // Screen background
  static const Color bgCard      = Color(0xFFFFFFFF);   // Card / elevated surface
  static const Color bgInput     = Color(0xFFFAFAFA);   // Input fields

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT
  // ═══════════════════════════════════════════════════════════════════════
  static const Color textPrimary   = Color(0xFF1A1F1A);   // Near-black on light
  static const Color textSecondary = Color(0xFF5A6B5A);   // Body text
  static const Color textMuted     = Color(0xFF8A9B8A);   // Muted / captions
  static const Color textDisabled  = Color(0xFFB0BEB0);   // Disabled

  // ═══════════════════════════════════════════════════════════════════════
  // BORDERS & DIVIDERS
  // ═══════════════════════════════════════════════════════════════════════
  static const Color borderCard    = Color(0xFFE0E8E0);   // Card border
  static const Color borderActive  = Color(0xFF1A6B3C);   // Focused input border
  static const Color borderVerified = Color(0xFF00C853);   // Success border

  // ═══════════════════════════════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════════════════════════════
  static const Color success       = Color(0xFF00C853);
  static const Color successLight  = Color(0xFFE8F5E9);
  static const Color warning       = Color(0xFFFFA726);
  static const Color warningLight  = Color(0xFFFFF3E0);
  static const Color error         = Color(0xFFE53935);
  static const Color errorLight    = Color(0xFFFCE4EC);
  static const Color errorBg       = Color(0xFFFFF5F5);
  static const Color verified      = Color(0xFF00C853);
  static const Color verifiedLight = Color(0xFFE8F5E9);

  // ═══════════════════════════════════════════════════════════════════════
  // GRADE COLORS (A+→D, aligned with score_pipeline.dart)
  // ═══════════════════════════════════════════════════════════════════════
  static const Color gradeAPlus = Color(0xFF00C853);  // 800-900 Exceptional
  static const Color gradeA = Color(0xFF4CAF50);  // 750-799 Excellent
  static const Color gradeBPlus = Color(0xFF66BB6A); // 700-749 Very Good
  static const Color gradeB = Color(0xFF8BC34A);  // 650-699 Good
  static const Color gradeCPlus = Color(0xFFFFC107); // 600-649 Fair
  static const Color gradeC = Color(0xFFFF9800);  // 550-599 Medium Risk
  static const Color gradeD = Color(0xFFE53935);  // 300-549 High Risk

  // Legacy aliases for backward compat
  static const Color gradeS = gradeAPlus;
  static const Color gradeE = gradeD;

  // ═══════════════════════════════════════════════════════════════════════
  // PILLAR COLORS (P1-P7)
  // ═══════════════════════════════════════════════════════════════════════
  static const Color pillar1 = Color(0xFF5C6BC0); // Income - Indigo
  static const Color pillar2 = Color(0xFF26A69A); // Payment - Teal
  static const Color pillar3 = Color(0xFFEF5350); // Debt - Red
  static const Color pillar4 = Color(0xFF66BB6A); // Savings - Green
  static const Color pillar5 = Color(0xFFAB47BC); // Work - Purple
  static const Color pillar6 = Color(0xFFFFA726); // Resilience - Orange
  static const Color pillar7 = Color(0xFF29B6F6); // Social - Light Blue

  // ═══════════════════════════════════════════════════════════════════════
  // SCHEME COLORS (Schemes screen accent per category)
  // ═══════════════════════════════════════════════════════════════════════
  static const Color schemeLoan        = Color(0xFF1A6B3C);
  static const Color schemePension     = Color(0xFF5C6BC0);
  static const Color schemeMudra       = Color(0xFFFF8F00);
  static const Color schemeInsurance   = Color(0xFFE53935);
  static const Color schemeRegistration = Color(0xFF26A69A);

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER
  // ═══════════════════════════════════════════════════════════════════════
  static const Color shimmerBase      = Color(0xFFE8E8E8);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ═══════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment(-0.5, -0.6),
    end: Alignment(0.5, 0.8),
    colors: [greenPrimary, greenMid, greenBright],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [greenPrimary, greenBright],
  );

  static const List<Color> primaryGradient = [greenPrimary, greenBright];
  static const List<Color> successGradient = [verified, Color(0xFF4CAF50)];

  // ═══════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════════════
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: greenPrimary.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> cardShadowHover = [
    BoxShadow(
      color: greenPrimary.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // LEGACY ALIASES (for backward compat with existing code)
  // ═══════════════════════════════════════════════════════════════════════
  static const Color primary       = greenPrimary;
  static const Color accent        = greenBright;
  static const Color accentLight   = greenMid;
  static const Color highlight     = greenMint;
  static const Color surface       = bgScreen;
  static const Color surfaceVariant = bgInput;
  static const Color card          = bgCard;
  static const Color cardElevated  = bgCard;
  static const Color textTertiary  = textMuted;
  static const Color divider       = borderCard;
  static const Color border        = borderCard;
  static const Color borderWarning = warning;

  // ═══════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════
  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+': return gradeAPlus;
      case 'S': return gradeAPlus; // Legacy alias
      case 'A': return gradeA;
      case 'B+': return gradeBPlus;
      case 'B': return gradeB;
      case 'C+': return gradeCPlus;
      case 'C': return gradeC;
      case 'D': return gradeD;
      default: return gradeD;
    }
  }

  static Color pillarColor(String pillarCode) {
    switch (pillarCode) {
      case 'P1': return pillar1;
      case 'P2': return pillar2;
      case 'P3': return pillar3;
      case 'P4': return pillar4;
      case 'P5': return pillar5;
      case 'P6': return pillar6;
      case 'P7': return pillar7;
      default: return greenBright;
    }
  }
}
