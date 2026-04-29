class P5Scorecard {
  static const List<double> weights = [
    0.15, 0.15, 0.10, 0.08, 0.08, 0.06, 0.05, 0.04,
    0.03, 0.06, 0.04, 0.04, 0.02, 0.02, 0.02, 0.03, 0.02, 0.01
  ];

  static double score(List<double> features) {
    if (features.length != 18) {
      throw ArgumentError('P5 requires exactly 18 features');
    }

    // KYC Gate: Aadhaar (index 0) and PAN (index 1) must be verified
    if (features[0] < 0.5 || features[1] < 0.5) {
      return 0.0;
    }

    double total = 0.0;
    for (int i = 0; i < 18; i++) {
      total += features[i] * weights[i];
    }

    return total.clamp(0.0, 1.0);
  }
}
