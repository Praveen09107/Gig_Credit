/// P6-05: Confidence Engine — PRODUCTION VERSION (7 pillars)
/// Adjusts raw pillar scores by data quality confidence.
/// Formula: adjusted = raw × confidence + 0.50 × (1 - confidence)
class ConfidenceEngine {
  /// Compute overall confidence from the 95-feature vector.
  /// Uses key verification-flag features from each pillar.
  static double computeConfidence(List<double> features) {
    // Key feature indices that indicate verified data presence:
    // P1: f0 (income_to_anchor), f7 (platform_earnings_match)
    // P2: f16 (combined_bill_score > 0.5)
    // P3: f34 (on_time_emi_rate)
    // P4: f48 (life_cover_flag)
    // P5: f49 (aadhaar_verified), f50 (pan_verified), f54 (mobile_verified)
    // P6: f67 (health_insurance_active)
    // P7: f88 (tax_compliance_flag)
    const checkIndices = [0, 7, 16, 34, 48, 49, 50, 54, 67, 88];
    int verified = 0;
    for (final idx in checkIndices) {
      if (idx < features.length && features[idx] > 0.3) verified++;
    }
    return (verified / checkIndices.length).clamp(0.0, 1.0);
  }

  /// Compute per-pillar confidence for fine-grained adjustment.
  static Map<String, double> computePillarConfidence(List<double> features) {
    return {
      'p1': _avgAboveThreshold(features, 0, 13),
      'p2': _avgAboveThreshold(features, 13, 28),
      'p3': _avgAboveThreshold(features, 28, 37),
      'p4': _avgAboveThreshold(features, 37, 49),
      'p5': _avgAboveThreshold(features, 49, 67),
      'p6': _avgAboveThreshold(features, 67, 78),
      'p7': _avgAboveThreshold(features, 78, 95),
    };
  }

  /// Adjust a raw score by confidence level.
  static double adjustScore(double rawScore, double confidence) {
    return rawScore * confidence + 0.50 * (1.0 - confidence);
  }

  /// Fraction of features in [start, end) that are above the 0.3 threshold.
  static double _avgAboveThreshold(List<double> f, int start, int end) {
    int count = 0;
    for (int i = start; i < end && i < f.length; i++) {
      if (f[i] > 0.3) count++;
    }
    return count / (end - start);
  }
}
