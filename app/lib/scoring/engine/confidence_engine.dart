class ConfidenceEngine {
  /// Uses conformal_intervals.json to compute per-pillar confidence
  /// Returns a map of pillar code to confidence value (0.0 to 1.0)
  static Map<String, double> computeConfidence(String workType, Map<String, dynamic> conformalIntervalsJson) {
    Map<String, double> confidences = {};

    List<String> mlPillars = ['P1', 'P2', 'P3', 'P4', 'P6'];
    List<String> scorecardPillars = ['P5', 'P7', 'P8'];

    // 1. ML Pillars
    for (String pillar in mlPillars) {
      double confidence = 0.50; // Default to LOW
      
      // JSON structure: {"P1": {"platform_worker": 0.015, ...}, ...}
      if (conformalIntervalsJson.containsKey(pillar) && conformalIntervalsJson[pillar].containsKey(workType)) {
        double halfWidth = (conformalIntervalsJson[pillar][workType] as num).toDouble();
        double intervalWidth = 2 * halfWidth;

        if (intervalWidth <= 0.12) {
          confidence = 1.0; // HIGH
        } else if (intervalWidth <= 0.20) {
          confidence = 0.75; // MEDIUM
        } else {
          confidence = 0.50; // LOW
        }
      }
      
      confidences[pillar] = confidence;
    }

    // 2. Scorecard pillars always get 1.0 confidence
    for (String pillar in scorecardPillars) {
      confidences[pillar] = 1.0;
    }

    return confidences;
  }

  /// Adjusts a raw/calibrated score using its confidence
  /// adjusted = score × confidence + 0.50 × (1 - confidence)
  static Map<String, double> adjustScores(Map<String, double> scores, Map<String, double> confidences) {
    Map<String, double> adjusted = {};

    scores.forEach((pillar, score) {
      double conf = confidences[pillar] ?? 0.50;
      double adj = score * conf + 0.50 * (1.0 - conf);
      adjusted[pillar] = adj.clamp(0.0, 1.0);
    });

    return adjusted;
  }
}
