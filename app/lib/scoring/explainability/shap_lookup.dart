import 'dart:convert';
import 'dart:math';

import '../../models/shap_factor_model.dart';

/// COMP_21: SHAP Explainability — PRODUCTION VERSION
/// Uses Dev A's real shap_lookup.json with binned SHAP values
/// from TreeExplainer on the trained pillar models.
///
/// JSON structure per feature:
/// {
///   "f_0": {
///     "name": "income_to_anchor_ratio",
///     "pillar": "P1",
///     "pillar_label": "Income Stability",
///     "bins": [0.0, 0.1, 0.2, ..., 1.0],   // 11 bin edges
///     "shap_values": [-0.019, -0.015, ...],  // 10 bin values
///     "mean_abs_shap": 0.009817
///   }
/// }
class ShapLookup {
  final Map<String, dynamic> _lookup;

  ShapLookup(this._lookup);

  /// Create from pre-loaded JSON string
  factory ShapLookup.fromJsonString(String jsonString) {
    return ShapLookup(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Analyze a 95-feature vector and return top SHAP factors.
  /// Returns exactly 3 positive (strengths) and 3 negative (concerns).
  ShapResult analyze(List<double> features) {
    final impacts = <ShapFactor>[];

    for (final entry in _lookup.entries) {
      final featureKey = entry.key; // e.g. "f_0"
      final data = entry.value as Map<String, dynamic>;

      // Extract feature index from key
      final featureIndex = int.tryParse(featureKey.replaceAll('f_', ''));
      if (featureIndex == null || featureIndex >= features.length) continue;

      final bins = List<double>.from(data['bins'] as List);
      final shapValues = List<double>.from(data['shap_values'] as List);
      final name = data['name'] as String? ?? featureKey;
      final pillar = data['pillar'] as String? ?? '';
      final pillarLabel = data['pillar_label'] as String? ?? '';

      final value = features[featureIndex];
      final binIndex = _findBin(value, bins);
      final impact = shapValues[binIndex];

      impacts.add(ShapFactor(
        featureName: name,
        displayLabel: _humanize(name),
        pillar: pillar,
        pillarLabel: pillarLabel,
        impact: impact,
        featureValue: value,
      ));
    }

    // Sort by absolute impact (most impactful first)
    impacts.sort((a, b) => b.impact.abs().compareTo(a.impact.abs()));

    // Get top 3 positive and top 3 negative
    final positives = impacts.where((f) => f.impact > 0).take(3).toList();
    final negatives = impacts.where((f) => f.impact < 0).take(3).toList();

    // Guarantee exactly 3 of each with fallbacks
    while (positives.length < 3) {
      positives.add(ShapFactor(
        featureName: _fallbackPositiveNames[positives.length],
        displayLabel: _fallbackPositiveLabels[positives.length],
        pillar: 'P5',
        pillarLabel: 'Work & Identity',
        impact: 0.001,
        featureValue: 0.5,
      ));
    }
    while (negatives.length < 3) {
      negatives.add(ShapFactor(
        featureName: _fallbackNegativeNames[negatives.length],
        displayLabel: _fallbackNegativeLabels[negatives.length],
        pillar: 'P6',
        pillarLabel: 'Financial Resilience',
        impact: -0.001,
        featureValue: 0.3,
      ));
    }

    return ShapResult(
      positiveFactors: positives,
      negativeFactors: negatives,
    );
  }

  /// Find the correct bin index for a value.
  /// bins has 11 edges for 10 bins: [0.0, 0.1, ..., 1.0]
  int _findBin(double value, List<double> bins) {
    for (int i = 0; i < bins.length - 1; i++) {
      if (value >= bins[i] && value < bins[i + 1]) return i;
    }
    // Edge case: value == 1.0 → last bin
    return max(0, bins.length - 2);
  }

  /// Convert snake_case feature name to human-readable label
  String _humanize(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }

  // Fallback names/labels when not enough real factors exist
  static const _fallbackPositiveNames = [
    'identity_verified',
    'mobile_verified',
    'platform_active',
  ];
  static const _fallbackPositiveLabels = [
    'Identity Verified',
    'Mobile Verified',
    'Active Platform Account',
  ];
  static const _fallbackNegativeNames = [
    'insurance_gap',
    'savings_low',
    'tax_compliance_gap',
  ];
  static const _fallbackNegativeLabels = [
    'Insurance Coverage Gap',
    'Low Savings Rate',
    'Tax Compliance Gap',
  ];
}

/// A single SHAP factor with its impact direction and magnitude.
class ShapFactor {
  final String featureName;
  final String displayLabel;
  final String pillar;
  final String pillarLabel;
  final double impact;
  final double featureValue;

  const ShapFactor({
    required this.featureName,
    required this.displayLabel,
    required this.pillar,
    required this.pillarLabel,
    required this.impact,
    required this.featureValue,
  });
}

/// Result containing top positive and negative SHAP factors.
class ShapResult {
  final List<ShapFactor> positiveFactors;
  final List<ShapFactor> negativeFactors;

  const ShapResult({
    required this.positiveFactors,
    required this.negativeFactors,
  });
}
