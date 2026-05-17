import 'actionable_item.dart';

class ShapFactorModel {
  final String featureName;
  final String featureKey;
  final String description;
  final String direction; // 'positive' or 'negative'
  final double impactStrength; // absolute SHAP value for scaling bars
  final String pillarLabel;
  final ActionabilityTier? actionType;
  final String? actionText;

  const ShapFactorModel({
    required this.featureName,
    required this.featureKey,
    required this.description,
    required this.direction,
    required this.impactStrength,
    required this.pillarLabel,
    this.actionType,
    this.actionText,
  });

  factory ShapFactorModel.fromJson(Map<String, dynamic> json) {
    ActionabilityTier? type;
    if (json['actionType'] != null) {
      switch (json['actionType']) {
        case 'immediate': type = ActionabilityTier.immediate; break;
        case 'behavioural': type = ActionabilityTier.behavioural; break;
        case 'non_actionable': type = ActionabilityTier.nonActionable; break;
      }
    }

    return ShapFactorModel(
      featureName: json['featureName'] as String,
      featureKey: json['featureKey'] as String? ?? json['featureName'] as String,
      description: json['description'] as String,
      direction: json['direction'] as String,
      impactStrength: (json['impactStrength'] as num).toDouble(),
      pillarLabel: json['pillarLabel'] as String? ?? '',
      actionType: type,
      actionText: json['actionText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'featureName': featureName,
    'featureKey': featureKey,
    'description': description,
    'direction': direction,
    'impactStrength': impactStrength,
  };
}
