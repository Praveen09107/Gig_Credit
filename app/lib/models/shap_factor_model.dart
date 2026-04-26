class ShapFactorModel {
  final String featureName;
  final String description;
  final String direction; // 'positive' or 'negative'
  final double impactStrength; // absolute SHAP value for scaling bars

  const ShapFactorModel({
    required this.featureName,
    required this.description,
    required this.direction,
    required this.impactStrength,
  });

  factory ShapFactorModel.fromJson(Map<String, dynamic> json) => ShapFactorModel(
    featureName: json['featureName'] as String,
    description: json['description'] as String,
    direction: json['direction'] as String,
    impactStrength: (json['impactStrength'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'featureName': featureName,
    'description': description,
    'direction': direction,
    'impactStrength': impactStrength,
  };
}
