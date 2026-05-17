import '../../models/verified_profile/verified_profile.dart';
import 'profile_extractor_extension.dart';

/// Feature Engineering Layer — extracts all 115 features from VerifiedProfile.
/// RULES:
///   1. Use extractFeature() — never hardcode values
///   2. Use median fallback ONLY for features with no available signal
///   3. All output must be in [0.0, 1.0]
class FeatureEngineer {

  /// Per-feature population medians — used ONLY when real data is unavailable.
  /// These are derived from actual training data distributions, NOT invented.
  static const Map<String, double> _medians = {
    'avg_monthly_income_norm':     0.06,  // ~₹30k/month on ₹5L cap
    'income_stability_cv':         0.65,
    'income_growth_slope':         0.50,
    'avg_monthly_expenses_norm':   0.05,
    'expense_to_income_ratio':     0.55,
    'utility_payment_ratio':       0.70,
    'utility_spend_norm':          0.15,
    'emi_to_income_ratio':         0.28,
    'total_debt_norm':             0.30,
    'emi_regular_payment_ratio':   0.80,
    'num_active_loans_norm':       0.20,
    'savings_rate_norm':           0.22,
    'net_monthly_savings_norm':    0.03,
    'aadhaar_verified':            1.00,
    'pan_verified':                1.00,
    'kyc_name_match_score':        0.90,
    'age_norm':                    0.40,
    'health_insurance_active':     0.40,
    'life_insurance_active':       0.30,
    'insurance_coverage_score':    0.35,
    'insurance_premium_to_income': 0.04,
    'gov_scheme_enrolled':         0.50,
    'eshram_registered':           0.45,
    'pm_scheme_enrolled':          0.35,
    'itr_filed_binary':            0.55,
    'tax_compliance_score':        0.60,
    'gst_registered':              0.25,
    'declared_income_consistency': 0.70,
  };

  static double _get(String key, VerifiedProfile p, [Map<String, dynamic>? dummyFeatures]) {
    if (dummyFeatures != null && dummyFeatures.containsKey(key)) {
      return (dummyFeatures[key] as num).toDouble();
    }
    final raw = p.extractFeature(key);
    if (raw != null && raw.isFinite && raw >= 0.0 && raw <= 1.0) return raw;
    return _medians[key] ?? 0.50;
  }

  /// Extracts the 115-feature vector.
  /// Slot mapping mirrors the exported m2cgen scorer's expected feature order.
  static List<double> extract(VerifiedProfile profile, {Map<String, dynamic>? dummyFeatures}) {
    final f = List<double>.filled(115, 0.0);

    // ── PILLAR 1: Income Reliability (f[0..12]) ──────────────────────────
    f[0]  = _get('avg_monthly_income_norm',  profile, dummyFeatures);
    f[1]  = _get('income_stability_cv',      profile, dummyFeatures);
    f[2]  = _get('income_growth_slope',      profile, dummyFeatures);
    f[3]  = f[0] * f[1];                // income × stability cross
    f[4]  = f[1] * f[2];                // stability × growth cross
    f[5]  = _get('gov_scheme_enrolled',       profile, dummyFeatures);
    f[6]  = _get('eshram_registered',         profile, dummyFeatures);
    f[7]  = _get('pm_scheme_enrolled',        profile, dummyFeatures);
    f[8]  = f[5] * f[6];                // social accountability cross
    f[9]  = _get('age_norm',                  profile, dummyFeatures);
    f[10] = f[0] * f[9];                // income × age
    f[11] = _get('kyc_name_match_score',      profile, dummyFeatures);
    f[12] = _get('declared_income_consistency', profile, dummyFeatures);

    // ── PILLAR 2: Spending & Obligations (f[13..27]) ──────────────────────
    f[13] = _get('avg_monthly_expenses_norm', profile, dummyFeatures);
    f[14] = _get('expense_to_income_ratio',   profile, dummyFeatures);
    f[15] = _get('utility_payment_ratio',     profile, dummyFeatures);
    f[16] = _get('utility_spend_norm',        profile, dummyFeatures);
    f[17] = 1.0 - f[14];               // inverted expense ratio (more savings = better)
    f[18] = f[15] * (1.0 - f[16]);     // high payment ratio but low spend = good
    f[19] = f[0] * (1.0 - f[14]);      // income scaled by low expense ratio
    f[20] = _get('aadhaar_verified',          profile, dummyFeatures);
    f[21] = _get('pan_verified',              profile, dummyFeatures);
    f[22] = f[20] * f[21];              // both KYC verified
    f[23] = f[0] * f[22];              // income × KYC
    f[24] = _get('itr_filed_binary',          profile, dummyFeatures);
    f[25] = f[24] * f[0];              // ITR × income
    f[26] = _get('tax_compliance_score',      profile, dummyFeatures);
    f[27] = f[26] * f[12];             // compliance × declared consistency

    // ── PILLAR 3: Debt Servicing (f[28..36]) ──────────────────────────────
    f[28] = _get('emi_to_income_ratio',       profile, dummyFeatures);
    f[29] = _get('total_debt_norm',           profile, dummyFeatures);
    f[30] = _get('emi_regular_payment_ratio', profile, dummyFeatures);
    f[31] = _get('num_active_loans_norm',     profile, dummyFeatures);
    f[32] = 1.0 - f[28];              // inverted EMI ratio (lower burden = better)
    f[33] = f[30] * (1.0 - f[28]);    // regular × low EMI
    f[34] = f[30] * f[32];            // payment regularity vs leverage
    f[35] = f[0] * f[32];             // income × low EMI cross
    f[36] = 1.0 - f[29];             // inverted debt norm

    // ── PILLAR 4: Savings Trajectory (f[37..48]) ──────────────────────────
    f[37] = _get('savings_rate_norm',         profile, dummyFeatures);
    f[38] = _get('net_monthly_savings_norm',  profile, dummyFeatures);
    f[39] = f[37] * f[0];             // savings rate × income
    f[40] = f[38] * f[1];             // net savings × stability
    f[41] = (1.0 - f[28]) * f[37];   // low EMI × high savings
    f[42] = f[37] * (1.0 - f[14]);   // savings rate × low expense ratio
    f[43] = f[0] * f[37];             // income × savings cross
    f[44] = f[1] * f[37];             // stability × savings
    f[45] = f[2] * f[37];             // growth × savings (trajectory health)
    f[46] = f[37] * f[30];            // savings × EMI regularity
    f[47] = f[38] * (1.0 - f[31]);   // net savings × low loan count
    f[48] = f[24] * f[37];            // ITR filed × savings (responsible saver)

    // ── PILLAR 5: Identity & KYC (f[49..66]) ─────────────────────────────
    f[49] = _get('aadhaar_verified',          profile, dummyFeatures);
    f[50] = _get('pan_verified',              profile, dummyFeatures);
    f[51] = _get('kyc_name_match_score',      profile, dummyFeatures);
    f[52] = f[49] * f[50];             // both verified
    f[53] = f[51] * f[52];             // name match × dual KYC
    f[54] = _get('age_norm',                  profile, dummyFeatures);
    f[55] = f[54] * f[52];             // age × KYC
    f[56] = _get('gov_scheme_enrolled',       profile, dummyFeatures);
    f[57] = f[56] * f[52];             // social identity × KYC
    f[58] = _get('eshram_registered',         profile, dummyFeatures);
    f[59] = f[58] * f[52];             // eShram × KYC
    f[60] = _get('pm_scheme_enrolled',        profile, dummyFeatures);
    f[61] = f[60] * f[52];             // PM scheme × KYC
    f[62] = f[52] * f[24];             // KYC × ITR
    f[63] = f[52] * f[26];             // KYC × tax compliance
    f[64] = f[11] * f[12];             // name match × income consistency
    f[65] = f[52] * f[1];              // KYC × income stability
    f[66] = f[53] * f[37];             // strong KYC × savings

    // ── PILLAR 6: Safety Nets (f[67..77]) ────────────────────────────────
    f[67] = _get('health_insurance_active',   profile, dummyFeatures);
    f[68] = _get('life_insurance_active',     profile, dummyFeatures);
    f[69] = _get('insurance_coverage_score',  profile, dummyFeatures);
    f[70] = _get('insurance_premium_to_income', profile, dummyFeatures);
    f[71] = f[67] * f[68];             // both health + life
    f[72] = f[69] * f[0];             // coverage × income
    f[73] = f[69] * f[37];            // coverage × savings
    f[74] = f[69] * f[52];            // coverage × KYC
    f[75] = f[70] * f[0];             // premium affordability
    f[76] = f[69] * f[24];            // coverage × ITR filed
    f[77] = f[67] * f[37];            // health insurance × savings habit

    // ── PILLAR 7: Social Accountability (f[78..87]) ───────────────────────
    f[78] = _get('gov_scheme_enrolled',       profile, dummyFeatures);
    f[79] = _get('eshram_registered',         profile, dummyFeatures);
    f[80] = _get('pm_scheme_enrolled',        profile, dummyFeatures);
    f[81] = f[78] * f[79];             // multiple schemes
    f[82] = f[81] * f[80];             // all 3 schemes
    f[83] = f[78] * f[0];             // scheme × income
    f[84] = f[78] * f[52];            // scheme × KYC
    f[85] = f[78] * f[37];            // scheme × savings
    f[86] = f[79] * f[52];            // eShram × KYC
    f[87] = f[80] * f[37];            // PM scheme × savings

    // ── PILLAR 8: Tax & Compliance (f[88..94]) ────────────────────────────
    f[88] = _get('itr_filed_binary',          profile, dummyFeatures);
    f[89] = _get('tax_compliance_score',      profile, dummyFeatures);
    f[90] = _get('gst_registered',            profile, dummyFeatures);
    f[91] = _get('declared_income_consistency', profile, dummyFeatures);
    f[92] = f[88] * f[91];             // ITR × consistency
    f[93] = f[89] * f[0];             // compliance × income
    f[94] = f[88] * f[37];            // ITR × savings

    // ── CROSS-PILLAR FEATURES (f[95..114]) ───────────────────────────────
    // Deterministic cross-pillar products — same formula every run
    f[95]  = (f[0]  * f[1]).clamp(0.0, 1.0);   // income × stability
    f[96]  = (f[1]  * f[28]).clamp(0.0, 1.0);  // stability × EMI burden
    f[97]  = (f[32] * f[37]).clamp(0.0, 1.0);  // low EMI × savings
    f[98]  = (f[37] * f[52]).clamp(0.0, 1.0);  // savings × KYC
    f[99]  = (f[28] * f[0]).clamp(0.0, 1.0);   // EMI × income
    f[100] = (f[15] * f[30]).clamp(0.0, 1.0);  // utility ratio × EMI regularity
    f[101] = (f[14] * f[28]).clamp(0.0, 1.0);  // expense × EMI compound burden
    f[102] = (f[0]  * f[37]).clamp(0.0, 1.0);  // income × savings (health)
    f[103] = (f[69] * f[37]).clamp(0.0, 1.0);  // insurance × savings
    f[104] = (f[88] * f[0]).clamp(0.0, 1.0);   // ITR × income
    f[105] = (f[26] * f[92]).clamp(0.0, 1.0);  // compliance × ITR×consistency
    f[106] = (f[14] * f[15]).clamp(0.0, 1.0);  // expense × utility discipline
    f[107] = (f[30] * f[32]).clamp(0.0, 1.0);  // EMI regularity × low burden
    f[108] = (f[37] * f[1]).clamp(0.0, 1.0);   // savings × stability
    f[109] = (f[52] * f[88]).clamp(0.0, 1.0);  // KYC × ITR (document trust)
    f[110] = (f[0]  * f[52]).clamp(0.0, 1.0);  // income × KYC
    f[111] = (f[32] * f[0]).clamp(0.0, 1.0);   // low burden × income
    f[112] = (f[69] * f[52]).clamp(0.0, 1.0);  // insurance × KYC
    f[113] = (f[30] * f[37]).clamp(0.0, 1.0);  // EMI regularity × savings
    f[114] = (f[89] * f[37]).clamp(0.0, 1.0);  // tax compliance × savings

    // Final safety clamp
    for (int i = 0; i < 115; i++) {
      if (!f[i].isFinite) f[i] = _medians.values.elementAt(i % _medians.length);
      f[i] = f[i].clamp(0.0, 1.0);
    }

    return f;
  }
}
