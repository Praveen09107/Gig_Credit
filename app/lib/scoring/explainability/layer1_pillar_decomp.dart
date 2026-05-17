class Layer1PillarDecomp {
  /// Decomposes the final score into per-pillar point contributions.
  /// Normalises to sum exactly to (finalScore - 300).
  /// [adjustedScores] are the scores after confidence adjustment.
  static Map<String, int> computeContributions(
    int finalScore,
    Map<String, double> adjustedScores,
    Map<String, dynamic> weightsJson,
    Map<String, dynamic> metaJson,
  ) {
    List<double> metaCoeffs = List<double>.from(
        (metaJson['coefficients'] as List).map((x) => (x as num).toDouble()));
    
    // First 8 coeffs are for the 8 pillars
    Map<String, double> rawContributions = {};
    double sumRaw = 0.0;

    List<String> pillars = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'];
    
    for (int i = 0; i < pillars.length; i++) {
      String p = pillars[i];
      double score = adjustedScores[p] ?? 0.0;
      double weight = (weightsJson[p] as num?)?.toDouble() ?? 1.0;
      double coeff = metaCoeffs.length > i ? metaCoeffs[i] : 1.0;

      double rawContrib = score * weight * coeff;
      rawContributions[p] = rawContrib;
      sumRaw += rawContrib;
    }

    Map<String, int> finalContributions = {};
    int targetPoints = finalScore - 300;
    
    if (sumRaw == 0.0 || targetPoints <= 0) {
      // Fallback if something is 0
      for (var p in pillars) {
        finalContributions[p] = 0;
      }
      return finalContributions;
    }

    int currentSum = 0;
    for (int i = 0; i < pillars.length; i++) {
      String p = pillars[i];
      if (i == pillars.length - 1) {
        // Last one gets the remainder to avoid rounding errors
        finalContributions[p] = targetPoints - currentSum;
      } else {
        int pts = ((rawContributions[p]! / sumRaw) * targetPoints).round();
        finalContributions[p] = pts;
        currentSum += pts;
      }
    }

    return finalContributions;
  }
}
