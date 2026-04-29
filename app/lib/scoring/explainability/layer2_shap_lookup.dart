import '../../models/shap_factor_model.dart';
import '../../models/actionable_item.dart';

class Layer2ShapLookup {
  /// Looks up SHAP impacts, sorts them, and returns top strengths and concerns.
  static Map<String, dynamic> computeShap(
    List<double> features,
    String workType,
    Map<String, dynamic> shapLookupJson,
    Map<String, dynamic> displayNamesJson,
    Map<String, dynamic> actionabilityJson,
  ) {
    List<ShapFactorModel> allFactors = [];
    Map<String, double> pillarAggregations = {};

    // For each feature defined in the SHAP JSON
    shapLookupJson.forEach((featureKey, featureData) {
      int index = featureData['index'];
      if (index >= features.length) return;
      
      double value = features[index];
      
      // Find bin
      List<double> edges = List<double>.from((featureData['bin_edges'] as List).map((x) => (x as num).toDouble()));
      int binIdx = _findBin(value, edges);

      // Get work-type specific SHAP array
      var workTypeData = featureData['shap_values'][workType] ?? featureData['shap_values']['all'];
      if (workTypeData == null) return;

      List<double> shapVals = List<double>.from((workTypeData as List).map((x) => (x as num).toDouble()));
      if (binIdx >= shapVals.length) binIdx = shapVals.length - 1;

      double impact = shapVals[binIdx];
      if (impact == 0.0) return;

      // Map details
      String name = displayNamesJson[featureKey] ?? featureKey;
      var actionTag = actionabilityJson[featureKey];
      String pillar = actionTag != null ? actionTag['pillar'] : 'Unknown';
      
      ActionabilityTier? tier;
      String? actionText;
      if (actionTag != null) {
        actionText = actionTag['action_text'];
        switch (actionTag['actionable']) {
          case 'immediate': tier = ActionabilityTier.immediate; break;
          case 'behavioural': tier = ActionabilityTier.behavioural; break;
          case 'non_actionable': tier = ActionabilityTier.nonActionable; break;
        }
      }

      allFactors.add(ShapFactorModel(
        featureName: name,
        description: _generateDescription(name, impact > 0),
        direction: impact > 0 ? 'positive' : 'negative',
        impactStrength: impact.abs(),
        pillarLabel: pillar,
        actionType: tier,
        actionText: actionText,
      ));

      // Aggregate by pillar
      pillarAggregations[pillar] = (pillarAggregations[pillar] ?? 0.0) + impact;
    });

    // Sort by absolute impact descending
    allFactors.sort((a, b) => b.impactStrength.compareTo(a.impactStrength));

    List<ShapFactorModel> strengths = allFactors.where((f) => f.direction == 'positive').take(5).toList();
    List<ShapFactorModel> concerns = allFactors.where((f) => f.direction == 'negative').take(5).toList();

    return {
      'topStrengths': strengths,
      'topConcerns': concerns,
      'pillarAggregations': pillarAggregations,
    };
  }

  static int _findBin(double value, List<double> edges) {
    for (int i = 0; i < edges.length - 1; i++) {
      if (value >= edges[i] && value <= edges[i + 1]) {
        return i;
      }
    }
    return edges.length - 2; // last bin
  }

  static String _generateDescription(String name, bool isPositive) {
    if (isPositive) return "$name is strengthening your profile.";
    return "$name is negatively impacting your profile.";
  }
}
