import '../../models/verified_profile/verified_profile.dart';

extension ProfileFeatureExtractor on VerifiedProfile {
  double? extractFeature(String key) {
    switch (key) {
      // SOURCE 1 — Bank Statement OCR
      case 'avg_monthly_income_norm': return bankInfo.isVerified ? 0.42 : null; // scale down usually
      case 'income_stability_cv': return 0.6; // Mock
      case 'income_growth_slope': return 0.5; // Mock
      case 'utility_ontime_ratio': return 0.8; // Mock
      case 'emi_to_income_ratio': return 0.3; // Mock
      
      // SOURCE 2 — KYC API Response
      case 'aadhaar_verified': return kycInfo.isVerified ? 1.0 : 0.0;
      case 'pan_verified': return kycInfo.isVerified ? 1.0 : 0.0;
      
      // SOURCE 3 — Insurance
      case 'health_insurance_active': return insuranceInfo.isVerified ? 1.0 : 0.0;
      
      // SOURCE 4 — ITR/GST
      case 'itr_filed_binary': return taxInfo.isVerified ? 1.0 : 0.0;
      
      // Default null triggers getFeature fallback
      default: return null;
    }
  }
}
