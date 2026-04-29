enum ActionabilityTier { immediate, behavioural, nonActionable }

class ActionableItem {
  final String featureName;
  final ActionabilityTier tier;
  final String difficulty;
  final String horizon;
  final int expectedGainPts;
  final String actionText;
  final String pillar;
  final String fixCategory;

  const ActionableItem({
    required this.featureName,
    required this.tier,
    required this.difficulty,
    required this.horizon,
    required this.expectedGainPts,
    required this.actionText,
    required this.pillar,
    required this.fixCategory,
  });

  factory ActionableItem.fromJson(String featureName, Map<String, dynamic> json) {
    ActionabilityTier tier;
    switch (json['actionable']) {
      case 'immediate':
        tier = ActionabilityTier.immediate;
        break;
      case 'behavioural':
        tier = ActionabilityTier.behavioural;
        break;
      default:
        tier = ActionabilityTier.nonActionable;
        break;
    }

    return ActionableItem(
      featureName: featureName,
      tier: tier,
      difficulty: json['difficulty'] as String? ?? 'none',
      horizon: json['horizon'] as String? ?? 'N/A',
      expectedGainPts: (json['expected_gain_pts'] as num?)?.toInt() ?? 0,
      actionText: json['action_text'] as String? ?? '',
      pillar: json['pillar'] as String? ?? '',
      fixCategory: json['fix_category'] as String? ?? '',
    );
  }
}
