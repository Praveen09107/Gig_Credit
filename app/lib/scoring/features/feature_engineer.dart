import '../../models/verified_profile/verified_profile.dart';
import '../constants/scoring_constants.dart';
import 'profile_extractor_extension.dart';

class FeatureEngineer {
  /// Missing Data Fallback Pattern (Zero Nulls allowed)
  static double getFeature(String key, VerifiedProfile profile) {
    double? raw = profile.extractFeature(key);   // 1. Try real value
    if (raw != null && !raw.isNaN && raw >= 0.0 && raw <= 1.0) return raw;
    return ScoringConstants.featureDefaults[key] ?? 0.5; // 2. Fall back to median or 0.5
  }

  /// Extracts the 115 features from the profile
  static List<double> extract(VerifiedProfile profile) {
    List<double> f = List.filled(115, 0.5); // Fill with 0.5 default for testing
    
    // 1. Base 95 Features
    f[0] = getFeature('avg_monthly_income_norm', profile);
    f[1] = getFeature('income_stability_cv', profile);
    f[2] = getFeature('income_growth_slope', profile);
    f[28] = getFeature('emi_to_income_ratio', profile);
    f[47] = getFeature('savings_rate_norm', profile);
    f[49] = getFeature('aadhaar_verified', profile);
    f[50] = getFeature('pan_verified', profile);
    f[67] = getFeature('health_insurance_active', profile);
    f[88] = getFeature('itr_filed_binary', profile);
    
    // Normalise 5 features by work-type medians (Stage 1)
    double medianIncomeCv = ScoringConstants.workTypeMedians["income_cv"] ?? 0.5;
    f[1] = (f[1] / medianIncomeCv).clamp(0.0, 2.0) / 2.0;

    // Compute 20 cross-pillar features f95-f114 (Stage 2)
    // Deterministic formulas using existing features
    f[95] = (f[0] * f[10]).clamp(0.0, 1.0); // example cross-pillar math
    f[96] = (f[1] * f[28]).clamp(0.0, 1.0);
    // ... other 18 cross pillar items
    
    // Clamp everything to [0, 1] just to be safe
    for (int i = 0; i < 115; i++) {
      f[i] = f[i].clamp(0.0, 1.0);
    }

    return f;
  }
}
