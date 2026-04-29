import '../models/p1_scorer.dart' as p1;
import '../models/p2_scorer.dart' as p2;
import '../models/p3_scorer.dart' as p3;
import '../models/p4_scorer.dart' as p4;
import '../models/scorecard_p5.dart' as p5;
import '../models/p6_scorer.dart' as p6;
import '../models/scorecard_p7.dart' as p7;

/// COMP_16: Scoring Engine — PRODUCTION VERSION
/// Calls Dev A's m2cgen-exported XGBoost/RF/Scorecard models.
///
/// Feature slicing per contracts/feature_vector_contract.json:
///   P1 Income Stability     → features[0..12]  → 13 elements
///   P2 Payment Discipline   → features[13..27] → 15 elements
///   P3 Debt Management      → features[28..36] →  9 elements
///   P4 Savings Behaviour    → features[37..48] → 12 elements
///   P5 Work & Identity      → features[49..66] → 18 elements
///   P6 Financial Resilience → features[67..77] → 11 elements
///   P7 Social Accountability→ features[78..94] → 17 elements
class ScoringEngine {
  static const int totalFeatures = 95;

  /// Score all 7 pillars from the 95-feature vector.
  /// Returns a map of pillar name → score in [0.0, 1.0].
  Map<String, double> scorePillars(List<double> features) {
    assert(features.length == totalFeatures,
        'Expected $totalFeatures features, got ${features.length}');

    return {
      'p1': p1.scoreP1(features.sublist(0, 13)).clamp(0.0, 1.0),
      'p2': p2.scoreP2(features.sublist(13, 28)).clamp(0.0, 1.0),
      'p3': p3.scoreP3(features.sublist(28, 37)).clamp(0.0, 1.0),
      'p4': p4.scoreP4(features.sublist(37, 49)).clamp(0.0, 1.0),
      'p5': p5.scoreP5(features.sublist(49, 67)).clamp(0.0, 1.0),
      'p6': p6.scoreP6(features.sublist(67, 78)).clamp(0.0, 1.0),
      'p7': p7.scoreP7(features.sublist(78, 95)).clamp(0.0, 1.0),
    };
  }

  /// Human-readable pillar labels for the report UI.
  static const Map<String, String> pillarLabels = {
    'p1': 'Income Stability',
    'p2': 'Payment Discipline',
    'p3': 'Debt Management',
    'p4': 'Savings Behaviour',
    'p5': 'Work & Identity',
    'p6': 'Financial Resilience',
    'p7': 'Social Accountability',
  };
}
