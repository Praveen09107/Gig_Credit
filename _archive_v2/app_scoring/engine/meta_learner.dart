import '../models/meta_scorer.dart' as meta;
import '../models/scoring_constants.dart';

/// COMP_16: Meta-Learner — PRODUCTION VERSION
/// Uses Dev A's XGBoost-exported meta_scorer.dart instead of
/// manual logistic regression dot-products.
///
/// Input: 19-element vector per contracts/decisions.md:
///   [p1, p2, p3, p4, p5, p6, p7,                     // 7 pillar scores
///    w_platform, w_vendor, w_trades, w_free,           // 4 work-type one-hot
///    p1×platform, p2×platform,                         // 8 interaction terms
///    p1×vendor, p2×vendor,
///    p1×trades, p2×trades,
///    p1×free, p2×free]
///
/// Output: GigCredit score 300-900
class MetaLearner {
  static const int metaInputSize = 19;

  /// Build the 19-element meta input vector from pillar scores and work type.
  static List<double> buildMetaInput(
      Map<String, double> pillarScores, String workType) {
    final p1 = pillarScores['p1'] ?? 0.4;
    final p2 = pillarScores['p2'] ?? 0.4;
    final p3 = pillarScores['p3'] ?? 0.4;
    final p4 = pillarScores['p4'] ?? 0.4;
    final p5 = pillarScores['p5'] ?? 0.4;
    final p6 = pillarScores['p6'] ?? 0.4;
    final p7 = pillarScores['p7'] ?? 0.4;

    // Work-type one-hot encoding
    final wt = workType.toLowerCase();
    final wPlatform = wt == 'platform_worker' ? 1.0 : 0.0;
    final wVendor = wt == 'vendor' ? 1.0 : 0.0;
    final wTrades = wt == 'tradesperson' ? 1.0 : 0.0;
    final wFree = wt == 'freelancer' ? 1.0 : 0.0;

    return <double>[
      p1, p2, p3, p4, p5, p6, p7,
      wPlatform, wVendor, wTrades, wFree,
      p1 * wPlatform, p2 * wPlatform,
      p1 * wVendor, p2 * wVendor,
      p1 * wTrades, p2 * wTrades,
      p1 * wFree, p2 * wFree,
    ];
  }

  /// Run the full meta-learner pipeline.
  /// Returns the GigCredit score in [300, 900].
  static int predict(Map<String, double> pillarScores, String workType) {
    final input = buildMetaInput(pillarScores, workType);
    assert(input.length == metaInputSize,
        'Meta input must be $metaInputSize elements, got ${input.length}');

    // Call Dev A's XGBoost RandomForest regressor export
    final probability = meta.scoreMeta(input);

    // Convert probability → 300-900 scale using scoring_constants.dart
    return probabilityToScore(probability);
  }

  /// Get the letter grade from a score.
  static String getGrade(int score) => scoreToGrade(score);

  /// Get the risk level from a score.
  static String getRiskLevel(int score) => scoreToRiskLevel(score);
}
