class P8Scorecard {
  static const List<double> weights = [
    0.25, 0.15, 0.20, 0.15, 0.10, 0.08, 0.07
  ];

  static double score(List<double> features) {
    if (features.length != 7) {
      throw ArgumentError('P8 requires exactly 7 features');
    }

    double total = 0.0;
    for (int i = 0; i < 7; i++) {
      total += features[i] * weights[i];
    }

    return total.clamp(0.0, 1.0);
  }
}


