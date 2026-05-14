import 'package:flutter/material.dart';

/// GigCredit Design Token System — Spacing & Dimensions
/// All spacing values derived from the Frontend Specification
class AppSpacing {
  AppSpacing._();

  // ═══════════════════════════════════════════════════════════════════════
  // SPACING SCALE
  // ═══════════════════════════════════════════════════════════════════════

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;  // Screen padding horizontal
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ═══════════════════════════════════════════════════════════════════════
  // NAMED DIMENSIONS (from specification)
  // ═══════════════════════════════════════════════════════════════════════

  /// Horizontal padding for screens
  static const double screenPaddingH = 20.0;

  /// Vertical gap between major blocks
  static const double blockGap = 20.0;

  /// Card internal padding
  static const double cardPadding = 20.0;

  /// Header bar height
  static const double headerHeight = 56.0;

  /// Bottom nav height
  static const double bottomNavHeight = 64.0;

  /// Button height (primary CTA)
  static const double buttonHeight = 56.0;

  /// Button height (secondary)
  static const double buttonHeightSecondary = 52.0;

  /// Input field height
  static const double inputHeight = 56.0;

  /// Step tracker height
  static const double trackerHeight = 52.0;

  // ═══════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusSheet = 28.0;
  static const double radiusPill = 999.0;

  /// Card corners
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(20.0));

  /// Button corners
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(16.0));

  /// Input corners
  static const BorderRadius inputBorderRadius = BorderRadius.all(Radius.circular(14.0));

  /// Pill/chip corners
  static const BorderRadius pillBorderRadius = BorderRadius.all(Radius.circular(999.0));

  /// Bottom sheet corners
  static const BorderRadius sheetBorderRadius = BorderRadius.vertical(top: Radius.circular(28.0));

  // ═══════════════════════════════════════════════════════════════════════
  // EDGE INSETS PRESETS
  // ═══════════════════════════════════════════════════════════════════════

  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(xl);

  /// Screen horizontal padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screenPaddingH);

  /// Card padding
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);

  /// Hero band padding
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(20, 28, 20, 36);

  /// Bottom sheet padding
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(24, 0, 24, 40);

  // ═══════════════════════════════════════════════════════════════════════
  // SPACER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  static const SizedBox spaceXs = SizedBox(height: xs, width: xs);
  static const SizedBox spaceSm = SizedBox(height: sm, width: sm);
  static const SizedBox spaceMd = SizedBox(height: md, width: md);
  static const SizedBox spaceLg = SizedBox(height: lg, width: lg);
  static const SizedBox spaceXl = SizedBox(height: xl, width: xl);
  static const SizedBox spaceXxl = SizedBox(height: xxl, width: xxl);

  /// Vertical spacers (for column layouts)
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox vXxl = SizedBox(height: xxl);

  /// Horizontal spacers (for row layouts)
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
}
