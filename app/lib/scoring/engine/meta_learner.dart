import '../models/meta_learner_lr.dart';

class MetaLearner {
  /// Computes the final probability using a logistic regression dot-product.
  /// [calibratedScores]: The 8 adjusted pillar scores (P1-P8)
  /// [confidences]: The 8 conformal confidence values (P1-P8)
  /// [features]: The 115-element feature array
  /// [metaJson]: The meta_lr_coefficients.json object
  static double predict(
    Map<String, double> calibratedScores,
    Map<String, double> confidences,
    List<double> features,
    Map<String, dynamic> metaJson,
  ) {
    List<int> top4Indices = List<int>.from(
        (metaJson['top4_cross_pillar_indices'] as List).map((x) => x as int));

    // Build the 20-element input vector
    List<double> input = List.filled(20, 0.0);

    // [0-7]: 8 calibrated pillar scores (in order P1 to P8)
    List<String> pillars = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'];
    for (int i = 0; i < 8; i++) {
      input[i] = calibratedScores[pillars[i]] ?? 0.0;
    }

    // [8-15]: 8 conformal confidence values
    for (int i = 0; i < 8; i++) {
      input[i + 8] = confidences[pillars[i]] ?? 0.50;
    }

    // [16-19]: 4 cross-pillar features
    for (int i = 0; i < 4; i++) {
      int featureIndex = top4Indices.length > i ? top4Indices[i] : 95 + i; // fallback
      input[i + 16] = features[featureIndex];
    }

    // Call the m2cgen-exported LR model which contains the true trained weights
    return MetaLearnerLR.score(input);
  }
}
