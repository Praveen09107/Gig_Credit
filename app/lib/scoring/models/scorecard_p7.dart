class P7Scorecard {
  static const List<double> weights = [
    0.15, 0.12, 0.10, 0.10, 0.08, 0.10, 0.08, 0.12, 0.10, 0.05
  ];

  static double score(List<double> features) {
    if (features.length != 10) {
      throw ArgumentError('P7 requires exactly 10 features');
    }

    double total = 0.0;
    for (int i = 0; i < 10; i++) {
      total += features[i] * weights[i];
    }

    return total.clamp(0.0, 1.0);
  }
}


