import '../../models/shap_factor_model.dart';
import '../../models/actionable_item.dart';

class Layer3Actionable {
  /// Filters negative SHAP factors and tags them with actionability.
  /// Removes 'non_actionable' completely from the improvement list.
  /// Sorts by Immediate -> Behavioural -> Expected Gain. Max 8 items.
  static List<ActionableItem> generateActionableItems(
    List<ShapFactorModel> topConcerns,
    Map<String, dynamic> actionabilityJson,
  ) {
    List<ActionableItem> actionableList = [];

    for (var factor in topConcerns) {
      if (factor.actionType == null || factor.actionType == ActionabilityTier.nonActionable) {
        continue;
      }

      var tagData = actionabilityJson[factor.featureKey];
      if (tagData == null) continue;

      actionableList.add(ActionableItem.fromJson(factor.featureKey, tagData));
    }

    // Sort: Immediate first, then Behavioural.
    // Within same tier, sort by expected gain descending.
    actionableList.sort((a, b) {
      if (a.tier == b.tier) {
        return b.expectedGainPts.compareTo(a.expectedGainPts);
      }
      if (a.tier == ActionabilityTier.immediate) return -1;
      if (b.tier == ActionabilityTier.immediate) return 1;
      return 0; // fallback
    });

    if (actionableList.length > 8) {
      actionableList = actionableList.sublist(0, 8);
    }

    return actionableList;
  }
}
