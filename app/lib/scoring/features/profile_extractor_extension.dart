import 'dart:math';
import '../../models/verified_profile/verified_profile.dart';

/// Data Completion Layer — fills missing values using intelligent estimation.
/// Rule: Use real OCR data first. Estimate ONLY if missing.
class DataCompletionLayer {
  static const double _MAX_INCOME = 500000.0; // ₹5L/month normalisation cap

  /// Returns estimated monthly income if bank data not available.
  /// Uses declared tax income ÷ 12 as fallback.
  static double estimateIncome(VerifiedProfile p) {
    if (p.bankInfo.avgMonthlyIncome > 0) return p.bankInfo.avgMonthlyIncome;
    if (p.taxInfo.declaredAnnualIncome > 0) {
      return p.taxInfo.declaredAnnualIncome / 12.0;
    }
    // Last resort: estimate from work type (population median)
    switch (p.personalInfo.workType.toLowerCase()) {
      case 'daily_wage':   return 8000.0;
      case 'gig_worker':   return 14000.0;
      case 'self_employed': return 22000.0;
      case 'salaried':     return 30000.0;
      default:             return 12000.0;
    }
  }

  static double estimateEmi(VerifiedProfile p) {
    if (p.emiLoansInfo.totalMonthlyEmi > 0) return p.emiLoansInfo.totalMonthlyEmi;
    // No EMI data = assume 0 (not 20-40% — that overpunishes)
    return 0.0;
  }

  static double estimateBills(VerifiedProfile p) {
    if (p.utilityInfo.totalMonthlyBills > 0) return p.utilityInfo.totalMonthlyBills;
    // Estimate 8% of income
    return estimateIncome(p) * 0.08;
  }
}

extension ProfileFeatureExtractor on VerifiedProfile {
  static const double _maxIncome = 500000.0;
  static const double _maxCv     = 2.0;

  /// Master feature extractor — ZERO hardcoded values.
  /// All features computed from real profile data or intelligent estimation.
  double? extractFeature(String key) {
    final income = DataCompletionLayer.estimateIncome(this);
    final emi    = DataCompletionLayer.estimateEmi(this);
    final bills  = DataCompletionLayer.estimateBills(this);

    switch (key) {
      // ── PILLAR 1: Income Reliability ─────────────────────────────────────
      case 'avg_monthly_income_norm':
        return (income / _maxIncome).clamp(0.0, 1.0);

      case 'income_stability_cv':
        if (bankInfo.monthlyCredits.length < 2) return null; // let default handle
        final mean = bankInfo.avgMonthlyIncome;
        if (mean == 0) return 0.0;
        final sqDiffs = bankInfo.monthlyCredits.map((x) => pow(x - mean, 2));
        final stdDev  = sqrt(sqDiffs.reduce((a, b) => a + b) / bankInfo.monthlyCredits.length);
        final cv      = stdDev / mean;
        // Lower CV = more stable. Invert: stability = 1 - normalised_cv
        return (1.0 - (cv / _maxCv).clamp(0.0, 1.0));

      case 'income_growth_slope':
        if (bankInfo.monthlyCredits.length < 3) return null;
        final n = bankInfo.monthlyCredits.length.toDouble();
        final xs = List.generate(bankInfo.monthlyCredits.length, (i) => i.toDouble());
        final meanX = xs.reduce((a, b) => a + b) / n;
        final meanY = bankInfo.avgMonthlyIncome;
        double num = 0.0, den = 0.0;
        for (int i = 0; i < xs.length; i++) {
          num += (xs[i] - meanX) * (bankInfo.monthlyCredits[i] - meanY);
          den += pow(xs[i] - meanX, 2);
        }
        final slope = den == 0 ? 0.0 : num / den;
        // Normalise: slope relative to mean income, capped
        return ((slope / (meanY + 1.0) + 1.0) / 2.0).clamp(0.0, 1.0);

      // ── PILLAR 2: Spending & Obligations ─────────────────────────────────
      case 'avg_monthly_expenses_norm':
        return (bankInfo.avgMonthlyExpenses / _maxIncome).clamp(0.0, 1.0);

      case 'expense_to_income_ratio':
        if (income == 0) return 1.0;
        return (bankInfo.avgMonthlyExpenses / income).clamp(0.0, 1.0);

      case 'utility_payment_ratio':
        return utilityInfo.paymentVerificationRatio;

      case 'utility_spend_norm':
        return (bills / 50000.0).clamp(0.0, 1.0);

      // ── PILLAR 3: Debt Servicing ──────────────────────────────────────────
      case 'emi_to_income_ratio':
        if (income == 0) return 1.0; // Worst case
        return (emi / income).clamp(0.0, 1.0);

      case 'total_debt_norm':
        final totalOutstanding = emiLoansInfo.loans
            .fold(0.0, (sum, l) => sum + l.outstandingBalance);
        return (totalOutstanding / (income * 60)).clamp(0.0, 1.0); // vs 5yr income

      case 'emi_regular_payment_ratio':
        return emiLoansInfo.regularPaymentRatio;

      case 'num_active_loans_norm':
        return (emiLoansInfo.loans.length / 5.0).clamp(0.0, 1.0); // 5+ = max

      // ── PILLAR 4: Savings Trajectory ─────────────────────────────────────
      case 'savings_rate_norm':
        if (income == 0) return 0.0;
        final savings = (income - emi - bills).clamp(0.0, income);
        return (savings / income).clamp(0.0, 1.0);

      case 'net_monthly_savings_norm':
        final savings = (income - emi - bills).clamp(0.0, double.infinity);
        return (savings / _maxIncome).clamp(0.0, 1.0);

      // ── PILLAR 5: Identity & KYC ─────────────────────────────────────────
      case 'aadhaar_verified':
        return kycInfo.isVerified ? 1.0 : 0.0;

      case 'pan_verified':
        return kycInfo.panVerified ? 1.0 : 0.0;

      case 'kyc_name_match_score':
        return kycInfo.nameMatchScore;

      case 'age_norm':
        if (personalInfo.age <= 0) return 0.5;
        // Age 18-65 maps to 0-1, clamp extremes
        return ((personalInfo.age - 18) / 47.0).clamp(0.0, 1.0);

      // ── PILLAR 6: Safety Nets (Insurance) ────────────────────────────────
      case 'health_insurance_active':
        return insuranceInfo.hasHealthInsurance ? 1.0 : 0.0;

      case 'life_insurance_active':
        return insuranceInfo.hasLifeInsurance ? 1.0 : 0.0;

      case 'insurance_coverage_score':
        return insuranceInfo.coverageScore;

      case 'insurance_premium_to_income':
        if (income == 0) return 0.0;
        final annualPremium = insuranceInfo.annualPremiumHealth +
            insuranceInfo.annualPremiumLife;
        return ((annualPremium / 12.0) / income).clamp(0.0, 1.0);

      // ── PILLAR 7: Social Accountability (Gov Schemes) ────────────────────
      case 'gov_scheme_enrolled':
        return govSchemesInfo.isVerified ? 1.0 : 0.0;

      case 'eshram_registered':
        return govSchemesInfo.hasEshram ? 1.0 : 0.0;

      case 'pm_scheme_enrolled':
        return govSchemesInfo.hasPmScheme ? 1.0 : 0.0;

      // ── PILLAR 8: Tax & Compliance ────────────────────────────────────────
      case 'itr_filed_binary':
        return taxInfo.itrFiled ? 1.0 : 0.0;

      case 'tax_compliance_score':
        return taxInfo.complianceScore;

      case 'gst_registered':
        return taxInfo.gstRegistered ? 1.0 : 0.0;

      case 'declared_income_consistency':
        // Compare tax declared income vs bank average
        if (income == 0 || taxInfo.declaredAnnualIncome == 0) return null;
        final bankAnnual = income * 12.0;
        final taxAnnual  = taxInfo.declaredAnnualIncome;
        final ratio = (taxAnnual / bankAnnual).clamp(0.1, 2.0);
        // Perfect match = 1.0, divergence reduces score
        return (1.0 - (ratio - 1.0).abs()).clamp(0.0, 1.0);

      default:
        return null; // Triggers FeatureEngineer fallback
    }
  }
}
