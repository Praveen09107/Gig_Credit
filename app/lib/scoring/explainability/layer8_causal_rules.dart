import '../../models/causal_chain.dart';

class Layer8CausalRules {
  /// Evaluates all rules against the feature set and returns up to 3 matched chains.
  static List<CausalRule> evaluate(
    List<double> features,
    String workType,
    List<dynamic> causalChainsJsonList,
  ) {
    List<CausalRule> matchedRules = [];

    for (var ruleJson in causalChainsJsonList) {
      CausalRule rule = CausalRule.fromJson(ruleJson);

      // Check applicability by work type
      if (!rule.workTypes.contains('all') && !rule.workTypes.contains(workType)) {
        continue;
      }

      if (_evaluateRule(rule, features)) {
        matchedRules.add(rule);
        if (matchedRules.length >= 3) break;
      }
    }

    return matchedRules;
  }

  /// Exact Evaluator Logic from Dev B Guide
  static bool _evaluateRule(CausalRule rule, List<double> features) {
    List<bool> results = rule.triggers.map((t) {
      // Ensure we don't index out of bounds
      if (t.featureIndex >= features.length) return false;

      double val = features[t.featureIndex];
      return switch (t.operator) {
        ">"  => val > t.threshold,
        "<"  => val < t.threshold,
        ">=" => val >= t.threshold,
        "<=" => val <= t.threshold,
        _    => false,
      };
    }).toList();
    
    return rule.triggerLogic == "AND"
        ? results.every((r) => r)
        : results.any((r) => r);
  }
}
