import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core palette
  static const Color primary = Color(0xFF1A1A2E);       // Deep navy
  static const Color accent = Color(0xFF0F3460);         // Electric blue
  static const Color accentLight = Color(0xFF1A5276);    // Lighter blue
  static const Color highlight = Color(0xFFE94560);      // Pink accent
  static const Color surface = Color(0xFF0A0A1A);        // Background (darkest)
  static const Color surfaceVariant = Color(0xFF12122A); // Slightly lighter bg
  static const Color card = Color(0xFF1E1E3A);           // Card background
  static const Color cardElevated = Color(0xFF26264A);   // Raised card bg

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textTertiary = Color(0xFF6B6B88);
  static const Color textDisabled = Color(0xFF4A4A60);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF1B5E20);  // Dark bg for success chips
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFF4A3800);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFF4A0C0C);
  static const Color verified = Color(0xFF00E676);       // Green checkmark / badges
  static const Color verifiedLight = Color(0xFF003D1A);  // Dark bg for verified chips

  // Grade colors (S→E)
  static const Color gradeS = Color(0xFF00E676);  // 800-900 Exceptional (bright green)
  static const Color gradeA = Color(0xFF4CAF50);  // 720-799 Excellent
  static const Color gradeB = Color(0xFF8BC34A);  // 640-719 Good (yellow-green)
  static const Color gradeC = Color(0xFFFFC107);  // 560-639 Fair (amber)
  static const Color gradeD = Color(0xFFFF9800);  // 480-559 Needs Improvement (orange)
  static const Color gradeE = Color(0xFFF44336);  // 300-479 Poor (red)

  // Pillar colors (P1-P7 each gets a distinct accent)
  static const Color pillar1 = Color(0xFF5C6BC0); // Income - Indigo
  static const Color pillar2 = Color(0xFF26A69A); // Payment - Teal
  static const Color pillar3 = Color(0xFFEF5350); // Debt - Red
  static const Color pillar4 = Color(0xFF66BB6A); // Savings - Green
  static const Color pillar5 = Color(0xFFAB47BC); // Work - Purple
  static const Color pillar6 = Color(0xFFFFA726); // Resilience - Orange
  static const Color pillar7 = Color(0xFF29B6F6); // Social - Light Blue

  // Dividers & borders
  static const Color divider = Color(0xFF2A2A48);
  static const Color border = Color(0xFF2E2E50);
  static const Color borderActive = Color(0xFF0F3460);
  static const Color borderVerified = Color(0xFF00E676);
  static const Color borderWarning = Color(0xFFFFC107);

  // Shimmer
  static const Color shimmerBase = Color(0xFF1E1E3A);
  static const Color shimmerHighlight = Color(0xFF2E2E52);

  // Gradient pair helpers
  static const List<Color> primaryGradient = [accent, highlight];
  static const List<Color> successGradient = [verified, Color(0xFF4CAF50)];

  // Utility
  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'S': return gradeS;
      case 'A': return gradeA;
      case 'B': return gradeB;
      case 'C': return gradeC;
      case 'D': return gradeD;
      default: return gradeE;
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
      default: return accent;
    }
  }
}

