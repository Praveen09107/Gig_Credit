import 'dart:math';

class MetaLearnerLR {
  static const List<double> weights = [
    1.958723, 2.307520, -0.005181, 0.747076, 0.772355, 1.329725, 0.261285, 0.212566, -0.414957, -0.414957, -0.414957, -0.414957, -0.414957, -0.414957, -0.414957, -0.414957, -0.085551, 0.110737, -0.113928, 0.097271
  ];
  static const double intercept = -0.534658;

  static double score(List<double> features) {
    if (features.length != 20) {
      throw ArgumentError('Meta Learner requires exactly 20 features');
    }

    double total = intercept;
    for (int i = 0; i < 20; i++) {
      total += features[i] * weights[i];
    }

    // Sigmoid
    return 1.0 / (1.0 + exp(-total));
  }
}
