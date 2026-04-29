class ScoringConstants {
  static const Map<String, double> featureDefaults = {
    "avg_monthly_income_norm": 0.42,
    "income_stability_cv": 0.55,
    "income_growth_slope": 0.50,
    "utility_ontime_ratio": 0.72,
    "emi_to_income_ratio": 0.38,
    "aadhaar_verified": 1.00,
    "pan_verified": 0.00,
    "health_insurance_active": 0.00,
    "eshram_enrolled": 0.00,
    "itr_filed_binary": 0.00,
    // Add other defaults as necessary for testing
  };

  static const Map<String, double> workTypeMedians = {
    "income_cv": 0.5,
    "bounce_rate": 0.2,
    "cash_ratio": 0.4,
    "emi_ratio": 0.3,
    "savings_rate": 0.25,
  };
}
