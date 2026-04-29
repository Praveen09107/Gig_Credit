import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/models/verified_profile/verified_profile.dart';
import 'package:gigcredit/scoring/features/feature_engineer.dart';
import 'package:gigcredit/scoring/constants/scoring_constants.dart';

void main() {
  group('FeatureEngineer', () {
    test('extract() returns exactly 115 features', () {
      final profile = VerifiedProfile();
      final features = FeatureEngineer.extract(profile);
      expect(features.length, 115);
    });

    test('extract() correctly applies featureDefaults when profile returns null', () {
      final profile = VerifiedProfile(); 
      // Because bankInfo and others are empty, extractFeature should return null for some fields.
      // E.g. income_stability_cv mock in extension returns 0.6. Wait, the extension currently mocks this.
      // Let's test a feature that falls back to defaults.
      // In the extension: 'utility_ontime_ratio' returns 0.8.
      // Wait, let's look at a key not mapped in switch, e.g. 'emi_to_income_ratio' which was mapped.
      // 'savings_rate_norm' is not mapped in extension, so it should fallback to 0.5 (from FeatureEngineer fallback code).
      
      final features = FeatureEngineer.extract(profile);
      
      // Index 47 is savings_rate_norm
      expect(features[47], 0.5); 
    });

    test('Work-type normalisation clamps base features properly', () {
      final profile = VerifiedProfile();
      final features = FeatureEngineer.extract(profile);
      
      // Stage 1: income_stability_cv (index 1) is divided by median
      // Extension mocks it to 0.6. Median is 0.5.
      // 0.6 / 0.5 = 1.2
      // clamped to [0, 2] = 1.2
      // divided by 2 = 0.6
      expect(features[1], closeTo(0.6, 0.0001));
    });

    test('Cross-pillar features are deterministically calculated', () {
      final profile = VerifiedProfile();
      final features = FeatureEngineer.extract(profile);
      
      // Index 95: f[0] * f[10]
      // f[0] falls back to ScoringConstants (0.42). f[10] falls back to 0.5.
      // So f[95] should be 0.42 * 0.5 = 0.21
      expect(features[95], closeTo(0.21, 0.0001));
    });
  });
}
