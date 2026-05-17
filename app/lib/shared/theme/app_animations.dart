import 'package:flutter/material.dart';

/// GigCredit Design Token System — Animation Constants
/// All animation durations, curves, and spring configs from the Frontend Specification
class AppAnimations {
  AppAnimations._();

  // ═══════════════════════════════════════════════════════════════════════
  // DURATIONS
  // ═══════════════════════════════════════════════════════════════════════

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration standard = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 600);
  static const Duration hero = Duration(milliseconds: 450);
  static const Duration sheet = Duration(milliseconds: 420);
  static const Duration sheetExit = Duration(milliseconds: 300);
  static const Duration toast = Duration(milliseconds: 420);
  static const Duration toastExit = Duration(milliseconds: 320);

  // ═══════════════════════════════════════════════════════════════════════
  // CURVES
  // ═══════════════════════════════════════════════════════════════════════

  /// Standard ease — smooth enter/exit
  static const Curve standardEase = Cubic(0.22, 1.0, 0.36, 1.0);

  /// Spring bounce — popup/sheet overshoot
  static const Curve springBounce = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Ease in — exit animations
  static const Curve easeIn = Curves.easeIn;

  /// Ease out — gentle decel
  static const Curve easeOut = Curves.easeOut;

  /// Linear — progress bars, spinners
  static const Curve linear = Curves.linear;

  /// Ease in-out — hero band gradient shift
  static const Curve easeInOut = Curves.easeInOut;

  // ═══════════════════════════════════════════════════════════════════════
  // STAGGER INTERVALS
  // ═══════════════════════════════════════════════════════════════════════

  /// Stagger per card in a list
  static const Duration staggerCard = Duration(milliseconds: 60);

  /// Stagger per input row
  static const Duration staggerInput = Duration(milliseconds: 40);

  /// Stagger per chip/pill
  static const Duration staggerChip = Duration(milliseconds: 40);

  /// Stagger per stat block
  static const Duration staggerStat = Duration(milliseconds: 80);

  /// Stagger per popup content item
  static const Duration staggerPopup = Duration(milliseconds: 60);

  // ═══════════════════════════════════════════════════════════════════════
  // SPRING PARAMETERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Button press spring
  static SpringDescription get buttonSpring => const SpringDescription(
    mass: 1.0,
    stiffness: 400.0,
    damping: 22.0,
  );

  /// Card entrance spring
  static SpringDescription get cardSpring => const SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 18.0,
  );

  /// Sheet snap-back spring
  static SpringDescription get sheetSpring => const SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 28.0,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // TOAST AUTO-DISMISS DURATIONS
  // ═══════════════════════════════════════════════════════════════════════

  static const Duration toastSuccessDuration = Duration(milliseconds: 3000);
  static const Duration toastErrorDuration = Duration(milliseconds: 3500);
  static const Duration toastWarningDuration = Duration(milliseconds: 3500);
  static const Duration toastInfoDuration = Duration(milliseconds: 3000);

  // ═══════════════════════════════════════════════════════════════════════
  // LOADER MINIMUM SHOW TIMES
  // ═══════════════════════════════════════════════════════════════════════

  static const Duration loaderButtonMin = Duration(milliseconds: 300);
  static const Duration loaderCardMin = Duration(milliseconds: 500);
  static const Duration loaderFullMin = Duration(milliseconds: 600);
  static const Duration loaderSplashMin = Duration(milliseconds: 2000);

  // ═══════════════════════════════════════════════════════════════════════
  // PAGE TRANSITIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Slide-up from bottom (popup/sheet style)
  static const Offset slideUpBegin = Offset(0.0, 1.0);
  static const Offset slideUpEnd = Offset.zero;

  /// Slide-left (push navigation)
  static const Offset slideLeftBegin = Offset(1.0, 0.0);
  static const Offset slideLeftEnd = Offset.zero;

  /// Fade + rise (standard content entrance)
  static const Offset riseBegin = Offset(0.0, 0.06);
  static const Offset riseEnd = Offset.zero;

  // ═══════════════════════════════════════════════════════════════════════
  // HERO BAND GRADIENT ANIMATION
  // ═══════════════════════════════════════════════════════════════════════

  static const Duration heroGradientCycle = Duration(seconds: 8);
}
