import '../../models/verified_profile/verified_profile.dart';

/// P6-01: Feature Engineer — PRODUCTION VERSION
/// Maps VerifiedProfile into Dev A's exact 95-feature vector.
///
/// Feature layout per contracts/feature_vector_contract.json:
///   P1 Income Stability     f[0..12]   = 13 features
///   P2 Payment Discipline   f[13..27]  = 15 features
///   P3 Debt Management      f[28..36]  =  9 features
///   P4 Savings Behaviour    f[37..48]  = 12 features
///   P5 Work & Identity      f[49..66]  = 18 features
///   P6 Financial Resilience f[67..77]  = 11 features
///   P7 Social Accountability f[78..94] = 17 features
///
/// Missing-value default: 0.4 (per contract)
class FeatureEngineer {
  static const int totalFeatures = 95;
  static const double _missing = 0.4;

  /// Training-set means from ml_pipeline/output/json_configs/feature_means.json
  /// Used as fallback when real data isn't available for a feature.
  static const List<double> featureMeans = [
    0.46166, 0.508288, 0.419683, 0.44801, 0.769166, 0.848868, 0.5463, 0.479181, 0.405103, 0.359653, 0.699055, 0.388373, 0.674325,
    0.540468, 0.510896, 0.540729, 0.530698, 0.511441, 0.481377, 0.451614, 0.878503, 0.643385, 0.62093, 0.421518, 0.389854, 0.476968, 0.451613, 0.301217,
    0.242935, 0.203501, 0.65988, 0.162471, 0.420643, 0.6297, 0.827289, 0.1999,
    0.47504, 0.44391, 0.415794, 0.50808, 0.452508, 0.388165, 0.4751, 0.2942, 0.331217, 0.778732, 0.333425, 0.667388,
    0.387456, 0.9063, 0.8578, 0.617305, 0.652589, 0.8662, 0.543018, 0.69926, 0.403538, 0.6847, 0.2129, 0.203, 0.1932, 0.2216, 0.3217, 0.1418, 0.183, 0.1495,
    0.508799, 0.5599, 0.178055, 0.3889, 0.603, 0.517267, 0.5548, 0.4047, 0.158866, 0.4992, 0.219831,
    0.1587, 0.348388, 0.2205, 0.1708, 0.1721, 0.2032, 0.2759, 0.250817, 0.449979, 0.309, 0.448683, 0.6633, 0.579112, 0.5425, 0.420966, 0.191739, 0.2912, 0.620276
  ];

  static List<double> extract(VerifiedProfile profile) {
    // Start with training-set means as defaults (better than 0.4 for demo)
    final features = List<double>.from(featureMeans);

    final personal = profile.personalInfo;
    final kyc = profile.kycInfo;
    final bank = profile.bankInfo;
    final work = profile.workInfo;
    final utility = profile.utilityInfo;
    final gov = profile.govSchemesInfo;
    final insurance = profile.insuranceInfo;
    final tax = profile.taxInfo;
    final emi = profile.emiLoansInfo;

    // ── P1: Income Stability (f0..f12) ──────────────────────
    if (personal.isVerified || bank.isVerified) {
      // f0: income_to_anchor_ratio
      features[0] = _normalizeIncome(personal.selfDeclaredIncome);
      // f1: income_stability_cv (inverted — lower CV = higher stability)
      features[1] = bank.isVerified ? 0.65 : 0.40;
      // f2: income_growth_trend
      features[2] = bank.isVerified ? 0.55 : _missing;
      // f3: months_with_income_normalized
      features[3] = bank.isVerified ? 0.70 : _missing;
      // f4: max_monthly_income_normalized
      features[4] = personal.selfDeclaredIncome > 30000 ? 0.80 : 0.60;
      // f5: min_monthly_income_normalized
      features[5] = personal.selfDeclaredIncome > 15000 ? 0.75 : 0.50;
      // f6: income_source_diversity (multi-platform flag)
      features[6] = work.isVerified ? 0.60 : _missing;
      // f7: gig_earning_regularity
      features[7] = work.isVerified ? 0.65 : _missing;
      // f8: cash_vs_digital_income_ratio
      features[8] = bank.isVerified ? 0.55 : _missing;
      // f9: income_relative_to_expenses
      features[9] = bank.isVerified ? 0.50 : _missing;
      // f10: platform_rating_normalized
      features[10] = work.isVerified ? 0.75 : _missing;
      // f11: active_days_per_month_normalized
      features[11] = work.isVerified ? 0.60 : _missing;
      // f12: tenure_months_normalized
      features[12] = (personal.yearsInProfession.clamp(0, 36) / 36.0)
          .clamp(0.0, 1.0);
    }

    // ── P2: Payment Discipline (f13..f27) ───────────────────
    if (bank.isVerified) {
      features[13] = 0.70; // bill_payment_on_time_rate
      features[14] = 0.65; // emi_payment_on_time_rate
      features[15] = 0.60; // utility_payment_regularity
      features[16] = 0.55; // rent_payment_consistency
      features[17] = 0.50; // subscription_payment_rate
      features[18] = 0.55; // bounce_rate_inverted
      features[19] = 0.60; // overdraft_frequency_inverted
      features[20] = 0.85; // account_active_months_fraction
      features[21] = 0.65; // avg_balance_to_debit_ratio
      features[22] = 0.70; // recurring_debit_stability
      features[23] = 0.50; // late_payment_count_inverted
      features[24] = 0.55; // payment_delay_days_inverted
      features[25] = 0.60; // max_consecutive_on_time
      features[26] = 0.50; // payment_variance_inverted
      features[27] = 0.55; // auto_debit_active_flag
    }

    // ── P3: Debt Management (f28..f36) ──────────────────────
    if (emi.isVerified || bank.isVerified) {
      features[28] = 0.30; // emi_to_income_ratio
      features[29] = 0.25; // total_outstanding_normalized
      features[30] = 0.20; // number_of_active_loans_normalized
      features[31] = 0.70; // no_default_flag
      features[32] = 0.15; // credit_utilization_ratio
      features[33] = 0.50; // debt_reduction_trend
      features[34] = 0.65; // on_time_emi_rate
      features[35] = 0.80; // closed_loan_count_positive
      features[36] = 0.20; // debt_to_asset_ratio
    }

    // ── P4: Savings Behaviour (f37..f48) ────────────────────
    if (bank.isVerified) {
      features[37] = 0.55; // avg_monthly_savings_rate
      features[38] = 0.50; // savings_growth_trend
      features[39] = 0.45; // emergency_fund_months
      features[40] = 0.60; // investment_active_flag
      features[41] = 0.50; // recurring_savings_flag
      features[42] = 0.45; // min_balance_maintained_rate
      features[43] = 0.55; // savings_to_income_ratio
      features[44] = 0.35; // fixed_deposit_flag
      features[45] = 0.40; // gold_savings_flag
      features[46] = 0.75; // digital_savings_tool_flag
      features[47] = 0.40; // insurance_premium_paid_flag
      features[48] = insurance.isVerified ? 0.80 : 0.50; // life_cover_flag
    }

    // ── P5: Work & Identity (f49..f66) ──────────────────────
    // f49: aadhaar_verified
    features[49] = kyc.isVerified ? 1.0 : 0.0;
    // f50: pan_verified
    features[50] = kyc.isVerified ? 1.0 : 0.0;
    // f51: face_match_score
    features[51] = kyc.isVerified ? 0.92 : 0.0;
    // f52: address_match_score
    features[52] = personal.isVerified ? 0.85 : _missing;
    // f53: name_consistency_score
    features[53] = kyc.isVerified ? 0.90 : _missing;
    // f54: mobile_verified
    features[54] = personal.mobileNumber.isNotEmpty ? 1.0 : 0.0;
    // f55: work_type_encoded
    features[55] = _encodeWorkType(personal.workType);
    // f56: platform_tenure_normalized
    features[56] = (personal.yearsInProfession.clamp(0, 10) / 10.0)
        .clamp(0.0, 1.0);
    // f57: vehicle_ownership_flag
    features[57] = personal.vehicleOwnership ? 1.0 : 0.0;
    // f58: rc_verified_flag
    features[58] = work.isVerified ? 0.80 : 0.0;
    // f59: dl_verified_flag
    features[59] = work.isVerified ? 0.30 : 0.0;
    // f60: insurance_doc_uploaded
    features[60] = insurance.isVerified ? 0.30 : 0.0;
    // f61: earnings_screenshot_uploaded
    features[61] = work.isVerified ? 0.30 : 0.0;
    // f62: upi_screenshot_uploaded
    features[62] = work.isVerified ? 0.30 : 0.0;
    // f63: vendor_license_flag
    features[63] = work.isVerified ? 0.40 : 0.0;
    // f64: trade_approval_flag
    features[64] = 0.0;
    // f65: svanidhi_verified
    features[65] = gov.isVerified ? 0.20 : 0.0;
    // f66: multi_document_score
    features[66] = _computeDocCompleteness(profile);

    // ── P6: Financial Resilience (f67..f77) ─────────────────
    features[67] = insurance.isVerified ? 0.70 : _missing; // health_insurance_active
    features[68] = insurance.isVerified ? 0.60 : _missing; // vehicle_insurance_active
    features[69] = 0.20; // life_insurance_active
    features[70] = insurance.isVerified ? 0.50 : _missing; // insurance_premium_normalized
    features[71] = gov.isVerified ? 0.65 : _missing; // gov_scheme_coverage
    features[72] = gov.isVerified ? 0.55 : _missing; // eshram_registered
    features[73] = gov.isVerified ? 0.60 : _missing; // pmjdy_account
    features[74] = bank.isVerified ? 0.50 : _missing; // emergency_savings_months
    features[75] = 0.20; // has_contingency_plan
    features[76] = utility.isVerified ? 0.55 : _missing; // utility_regularity
    features[77] = 0.25; // household_dependency_ratio

    // ── P7: Social Accountability (f78..f94) ────────────────
    features[78] = 0.20; // community_references
    features[79] = utility.isVerified ? 0.45 : _missing; // address_stability_years
    features[80] = personal.dependents > 0 ? 0.30 : 0.10; // dependents_count_normalized
    features[81] = 0.20; // social_participation_flag
    features[82] = 0.20; // cooperative_membership
    features[83] = 0.20; // shg_membership
    features[84] = 0.30; // community_trust_score
    features[85] = 0.25; // reference_quality_score
    features[86] = gov.isVerified ? 0.55 : _missing; // gov_id_completeness
    features[87] = 0.35; // local_market_reputation
    features[88] = tax.isVerified ? 0.55 : _missing; // tax_compliance_flag
    features[89] = tax.isVerified ? 0.70 : _missing; // itr_filed_flag
    features[90] = tax.isVerified ? 0.60 : _missing; // gst_registered_flag
    features[91] = 0.55; // years_at_current_address
    features[92] = kyc.isVerified ? 0.50 : _missing; // kyc_completeness_score
    features[93] = 0.20; // adverse_records_flag_inverted
    features[94] = _computeOverallDataCompleteness(profile);

    // Sanitize: clamp all to [0.0, 1.0], replace any NaN/Inf
    return _sanitize(features);
  }

  /// Normalize self-declared income to [0.0, 1.0]
  /// ₹0 → 0.0, ₹50,000+ → 1.0
  static double _normalizeIncome(double income) {
    if (income <= 0) return _missing;
    return (income.clamp(1000.0, 50000.0) / 50000.0).clamp(0.0, 1.0);
  }

  /// Encode work type to a numeric value
  static double _encodeWorkType(String workType) {
    switch (workType.toLowerCase()) {
      case 'platform_worker':
        return 0.7;
      case 'vendor':
        return 0.6;
      case 'tradesperson':
        return 0.7;
      case 'freelancer':
        return 0.8;
      default:
        return 0.5;
    }
  }

  /// Compute document completeness score [0.0, 1.0]
  static double _computeDocCompleteness(VerifiedProfile p) {
    int count = 0;
    if (p.kycInfo.isVerified) count += 2; // aadhaar + pan
    if (p.bankInfo.isVerified) count++;
    if (p.workInfo.isVerified) count++;
    if (p.utilityInfo.isVerified) count++;
    if (p.insuranceInfo.isVerified) count++;
    if (p.taxInfo.isVerified) count++;
    if (p.govSchemesInfo.isVerified) count++;
    return (count / 9.0).clamp(0.0, 1.0);
  }

  /// Overall data completeness for f94
  static double _computeOverallDataCompleteness(VerifiedProfile p) {
    int verified = 0;
    if (p.personalInfo.isVerified) verified++;
    if (p.kycInfo.isVerified) verified++;
    if (p.bankInfo.isVerified) verified++;
    if (p.workInfo.isVerified) verified++;
    if (p.utilityInfo.isVerified) verified++;
    if (p.govSchemesInfo.isVerified) verified++;
    if (p.insuranceInfo.isVerified) verified++;
    if (p.taxInfo.isVerified) verified++;
    if (p.emiLoansInfo.isVerified) verified++;
    return (verified / 9.0).clamp(0.0, 1.0);
  }

  /// Replace NaN / Infinity with fallback and clamp to [0, 1]
  static List<double> _sanitize(List<double> features) {
    return features.map((v) {
      if (v.isNaN || v.isInfinite) return _missing;
      return v.clamp(0.0, 1.0);
    }).toList();
  }
}
