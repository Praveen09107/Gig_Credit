"""
GigCredit ML Pipeline — Shared Configuration
==============================================
Central config for all training, export, and validation scripts.
Version 3.0 | April 2026
"""

from pathlib import Path

# ─── Paths ──────────────────────────────────────────────────────────────────
ROOT_DIR    = Path(__file__).resolve().parent
DATA_DIR    = ROOT_DIR / "data" / "generated"
MODELS_DIR  = ROOT_DIR / "output" / "models"
ASSETS_DIR  = ROOT_DIR / "output" / "assets"
EXPORT_DIR  = ROOT_DIR / "output" / "dart_export"
GOLDEN_DIR  = ROOT_DIR / "output" / "golden"

# Flutter app asset target
FLUTTER_ASSETS = ROOT_DIR.parent / "app" / "assets" / "constants"
FLUTTER_MODELS = ROOT_DIR.parent / "app" / "lib" / "scoring" / "models"

# Ensure all output dirs exist
for d in [DATA_DIR, MODELS_DIR, ASSETS_DIR, EXPORT_DIR, GOLDEN_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# ─── Constants ──────────────────────────────────────────────────────────────
SEED          = 42
N_PROFILES    = 15_000
N_FEATURES    = 95
N_PILLARS_ML  = 5         # P1, P2, P3, P4, P6 (ML-scored)
N_PILLARS     = 8         # P1–P8 total

ML_PILLARS    = ["P1", "P2", "P3", "P4", "P6"]
RULE_PILLARS  = ["P5", "P7", "P8"]
ALL_PILLARS   = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]

WORK_TYPES    = ["platform_worker", "street_vendor",
                 "skilled_tradesperson", "freelancer"]

# ─── 95-Feature Schema ─────────────────────────────────────────────────────
FEATURE_NAMES = [
    # P1 Income Stability (0–12, 13 features)
    "avg_monthly_income_norm",
    "income_stability_cv",
    "income_growth_slope",
    "income_months_active",
    "income_platform_verified_ratio",
    "income_bank_deposit_match_ratio",
    "income_zero_month_count",
    "income_irregular_spike_count",
    "income_state_percentile_rank",
    "income_seasonality_amplitude",
    "income_source_diversity",
    "multi_platform_count_norm",
    "platform_tenure_months_norm",

    # P2 Payment Discipline (13–27, 15 features)
    "utility_ontime_ratio",
    "emi_ontime_ratio",
    "bounce_count_norm",
    "late_payment_frequency",
    "payment_regularity_streak",
    "standing_instruction_success_rate",
    "rent_ontime_ratio",
    "mobile_recharge_regularity",
    "postpaid_ontime_ratio",
    "loan_prepayment_indicator",
    "digital_payment_adoption",
    "autopay_enrollment",
    "payment_channel_diversity",
    "oldest_active_credit_months_norm",
    "credit_utilization_ratio",

    # P3 Debt Management (28–36, 9 features)
    "emi_to_income_ratio",
    "debt_count_norm",
    "debt_service_coverage_ratio",
    "debt_to_asset_ratio",
    "short_term_debt_ratio",
    "avg_loan_tenure_norm",
    "debt_reduction_trend",
    "new_debt_last_3m_indicator",
    "debt_consolidation_flag",

    # P4 Savings Behaviour (37–48, 12 features)
    "savings_rate",
    "avg_month_end_balance_norm",
    "emergency_fund_months",
    "savings_consistency_score",
    "balance_volatility_norm",
    "liquid_asset_to_income",
    "recurring_savings_deposit_indicator",
    "fixed_deposit_indicator",
    "digital_wallet_balance_norm",
    "gold_investment_indicator",
    "savings_growth_slope",
    "financial_shock_recovery",

    # P5 Work & Identity (49–66, 18 features)
    "aadhaar_verified",
    "pan_verified",
    "work_proof_present",
    "gig_experience_months_norm",
    "eshram_enrolled",
    "customer_rating_norm",
    "platform_level_norm",
    "professional_certification",
    "multi_skill_indicator",
    "work_regularity_score",
    "avg_daily_hours_norm",
    "weekly_active_days_norm",
    "peak_season_availability",
    "reference_count_norm",
    "professional_network_size_norm",
    "repeat_client_ratio",
    "dispute_resolution_ratio",
    "work_area_stability_score",

    # P6 Financial Resilience (67–77, 11 features)
    "health_insurance_active",
    "life_insurance_active",
    "pm_sym_enrollment",
    "vehicle_insurance_active",
    "crop_insurance_active",
    "welfare_scheme_active",
    "self_help_group_member",
    "family_support_index",
    "asset_ownership_score",
    "income_replacement_ratio",
    "pm_svanidhi_enrolled",

    # P7 Social Accountability (78–87, 10 features)
    "community_standing_score",
    "group_lending_participant",
    "trade_association_member",
    "cooperative_member",
    "mentor_mentee_active",
    "social_media_business_presence",
    "community_event_participation",
    "neighbourhood_trust_score",
    "years_at_current_address_norm",
    "family_dependents_norm",

    # P8 Tax & Compliance (88–94, 7 features)
    "itr_filed_this_year",
    "itr_years_filed_norm",
    "gst_registered",
    "pan_linked_to_bank",
    "udyam_registered",
    "fssai_license_active",
    "professional_tax_paid",
]

assert len(FEATURE_NAMES) == N_FEATURES, \
    f"Expected {N_FEATURES} features, got {len(FEATURE_NAMES)}"

# ─── Pillar Feature Slicing ────────────────────────────────────────────────
PILLAR_FEATURE_SLICES = {
    "P1": FEATURE_NAMES[0:13],
    "P2": FEATURE_NAMES[13:28],
    "P3": FEATURE_NAMES[28:37],
    "P4": FEATURE_NAMES[37:49],
    "P5": FEATURE_NAMES[49:67],
    "P6": FEATURE_NAMES[67:78],
    "P7": FEATURE_NAMES[78:88],
    "P8": FEATURE_NAMES[88:95],
}

PILLAR_FEATURE_RANGES = {
    "P1": (0, 13),   "P2": (13, 28),  "P3": (28, 37),
    "P4": (37, 49),  "P5": (49, 67),  "P6": (67, 78),
    "P7": (78, 88),  "P8": (88, 95),
}

# ─── Pillar Weights (for final score composition) ──────────────────────────
PILLAR_WEIGHTS = {
    "P1": 0.22, "P2": 0.18, "P3": 0.12, "P4": 0.13,
    "P5": 0.10, "P6": 0.10, "P7": 0.08, "P8": 0.07,
}

# ─── Scorecard Weights (P5, P7, P8 — rule-based) ──────────────────────────
P5_WEIGHTS = {
    "aadhaar_verified": 0.15, "pan_verified": 0.15,
    "work_proof_present": 0.10, "gig_experience_months_norm": 0.08,
    "eshram_enrolled": 0.08, "customer_rating_norm": 0.06,
    "platform_level_norm": 0.05, "professional_certification": 0.04,
    "multi_skill_indicator": 0.03, "work_regularity_score": 0.06,
    "avg_daily_hours_norm": 0.04, "weekly_active_days_norm": 0.04,
    "peak_season_availability": 0.02, "reference_count_norm": 0.02,
    "professional_network_size_norm": 0.02, "repeat_client_ratio": 0.03,
    "dispute_resolution_ratio": 0.02, "work_area_stability_score": 0.01,
}

P7_WEIGHTS = {
    "community_standing_score": 0.15, "group_lending_participant": 0.12,
    "trade_association_member": 0.10, "cooperative_member": 0.10,
    "mentor_mentee_active": 0.08, "social_media_business_presence": 0.10,
    "community_event_participation": 0.08,
    "neighbourhood_trust_score": 0.12,
    "years_at_current_address_norm": 0.10,
    "family_dependents_norm": 0.05,
}

P8_WEIGHTS = {
    "itr_filed_this_year": 0.25, "itr_years_filed_norm": 0.15,
    "gst_registered": 0.20, "pan_linked_to_bank": 0.15,
    "udyam_registered": 0.10, "fssai_license_active": 0.08,
    "professional_tax_paid": 0.07,
}

# ─── Display Names ─────────────────────────────────────────────────────────
FEATURE_DISPLAY_NAMES = {
    "avg_monthly_income_norm":        "Average Monthly Income",
    "income_stability_cv":            "Income Stability",
    "income_growth_slope":            "Income Growth Trend",
    "income_months_active":           "Active Income Months",
    "income_platform_verified_ratio": "Platform-Verified Income",
    "income_bank_deposit_match_ratio":"Bank Deposit Match",
    "income_zero_month_count":        "Zero-Income Months",
    "income_irregular_spike_count":   "Irregular Income Spikes",
    "income_state_percentile_rank":   "State Income Rank",
    "income_seasonality_amplitude":   "Income Seasonality",
    "income_source_diversity":        "Income Source Diversity",
    "multi_platform_count_norm":      "Multi-Platform Count",
    "platform_tenure_months_norm":    "Platform Tenure",
    "utility_ontime_ratio":           "Utility Bills On-Time",
    "emi_ontime_ratio":               "EMI Payments On-Time",
    "bounce_count_norm":              "ECS Bounces",
    "late_payment_frequency":         "Late Payment Frequency",
    "payment_regularity_streak":      "Payment Streak",
    "standing_instruction_success_rate": "Standing Instructions",
    "rent_ontime_ratio":              "Rent On-Time",
    "mobile_recharge_regularity":     "Mobile Recharge Regularity",
    "postpaid_ontime_ratio":          "Postpaid Bills On-Time",
    "loan_prepayment_indicator":      "Loan Prepayment",
    "digital_payment_adoption":       "Digital Payment Adoption",
    "autopay_enrollment":             "Autopay Enrolled",
    "payment_channel_diversity":      "Payment Channels",
    "oldest_active_credit_months_norm": "Credit History Length",
    "credit_utilization_ratio":       "Credit Utilization",
    "emi_to_income_ratio":            "EMI-to-Income Ratio",
    "debt_count_norm":                "Number of Active Loans",
    "debt_service_coverage_ratio":    "Debt Service Coverage",
    "debt_to_asset_ratio":            "Debt-to-Asset Ratio",
    "short_term_debt_ratio":          "Short-Term Debt Ratio",
    "avg_loan_tenure_norm":           "Average Loan Tenure",
    "debt_reduction_trend":           "Debt Reduction Trend",
    "new_debt_last_3m_indicator":     "New Debt (Last 3m)",
    "debt_consolidation_flag":        "Debt Consolidation",
    "savings_rate":                   "Monthly Savings Rate",
    "avg_month_end_balance_norm":     "Average Bank Balance",
    "emergency_fund_months":          "Emergency Fund Months",
    "savings_consistency_score":      "Savings Consistency",
    "balance_volatility_norm":        "Balance Volatility",
    "liquid_asset_to_income":         "Liquid Assets",
    "recurring_savings_deposit_indicator": "Recurring Savings",
    "fixed_deposit_indicator":        "Fixed Deposits",
    "digital_wallet_balance_norm":    "Digital Wallet Balance",
    "gold_investment_indicator":      "Gold Investment",
    "savings_growth_slope":           "Savings Growth Trend",
    "financial_shock_recovery":       "Shock Recovery",
    "aadhaar_verified":               "Aadhaar Verified",
    "pan_verified":                   "PAN Verified",
    "work_proof_present":             "Work Proof Document",
    "gig_experience_months_norm":     "Gig Work Experience",
    "eshram_enrolled":                "e-Shram Registered",
    "customer_rating_norm":           "Customer Rating",
    "platform_level_norm":            "Platform Level",
    "professional_certification":     "Professional Certification",
    "multi_skill_indicator":          "Multi-Skill",
    "work_regularity_score":          "Work Regularity",
    "avg_daily_hours_norm":           "Daily Work Hours",
    "weekly_active_days_norm":        "Weekly Active Days",
    "peak_season_availability":       "Peak Season Availability",
    "reference_count_norm":           "References",
    "professional_network_size_norm": "Professional Network",
    "repeat_client_ratio":            "Repeat Clients",
    "dispute_resolution_ratio":       "Dispute Resolution",
    "work_area_stability_score":      "Work Area Stability",
    "health_insurance_active":        "Health Insurance",
    "life_insurance_active":          "Life Insurance",
    "pm_sym_enrollment":              "PM-SYM Enrollment",
    "vehicle_insurance_active":       "Vehicle Insurance",
    "crop_insurance_active":          "Crop Insurance",
    "welfare_scheme_active":          "Welfare Scheme",
    "self_help_group_member":         "SHG Member",
    "family_support_index":           "Family Support",
    "asset_ownership_score":          "Asset Ownership",
    "income_replacement_ratio":       "Income Replacement",
    "pm_svanidhi_enrolled":           "PM SVANidhi",
    "community_standing_score":       "Community Standing",
    "group_lending_participant":      "Group Lending",
    "trade_association_member":       "Trade Association",
    "cooperative_member":             "Cooperative Member",
    "mentor_mentee_active":           "Mentor/Mentee",
    "social_media_business_presence": "Social Media Business",
    "community_event_participation":  "Community Events",
    "neighbourhood_trust_score":      "Neighbourhood Trust",
    "years_at_current_address_norm":  "Years at Address",
    "family_dependents_norm":         "Family Dependents",
    "itr_filed_this_year":            "ITR Filed",
    "itr_years_filed_norm":           "ITR History",
    "gst_registered":                 "GST Registered",
    "pan_linked_to_bank":             "PAN Linked to Bank",
    "udyam_registered":               "Udyam Registered",
    "fssai_license_active":           "FSSAI License",
    "professional_tax_paid":          "Professional Tax",
}

# ─── Actionable Feature Tags ──────────────────────────────────────────────
ACTIONABLE_TAGS = {
    "health_insurance_active":  {"actionable": True, "difficulty": "easy",
                                  "horizon": "1-7 days", "expected_gain_pts": 18,
                                  "action_text": "Upload health insurance in Documents tab"},
    "eshram_enrolled":          {"actionable": True, "difficulty": "easy",
                                  "horizon": "1-7 days", "expected_gain_pts": 12,
                                  "action_text": "Register on eshram.gov.in (free)"},
    "itr_filed_this_year":      {"actionable": True, "difficulty": "easy",
                                  "horizon": "1-7 days", "expected_gain_pts": 10,
                                  "action_text": "Upload ITR acknowledgement"},
    "life_insurance_active":    {"actionable": True, "difficulty": "easy",
                                  "horizon": "7-14 days", "expected_gain_pts": 10,
                                  "action_text": "Upload life insurance policy"},
    "pan_verified":             {"actionable": True, "difficulty": "easy",
                                  "horizon": "1 day", "expected_gain_pts": 15,
                                  "action_text": "Complete PAN verification"},
    "pan_linked_to_bank":       {"actionable": True, "difficulty": "easy",
                                  "horizon": "1 day", "expected_gain_pts": 7,
                                  "action_text": "Link PAN to bank account"},
    "work_proof_present":       {"actionable": True, "difficulty": "easy",
                                  "horizon": "1-3 days", "expected_gain_pts": 10,
                                  "action_text": "Upload work ID or platform screenshot"},
    "pm_svanidhi_enrolled":     {"actionable": True, "difficulty": "easy",
                                  "horizon": "1-7 days", "expected_gain_pts": 8,
                                  "action_text": "Apply for PM SVANidhi scheme"},
    "gst_registered":           {"actionable": True, "difficulty": "medium",
                                  "horizon": "7-30 days", "expected_gain_pts": 8,
                                  "action_text": "Register for GST on gst.gov.in"},
    "savings_rate":             {"actionable": True, "difficulty": "medium",
                                  "horizon": "3-6 months", "expected_gain_pts": 10,
                                  "action_text": "Increase monthly savings by ₹500"},
    "emi_to_income_ratio":      {"actionable": True, "difficulty": "hard",
                                  "horizon": "3-6 months", "expected_gain_pts": 20,
                                  "action_text": "Reduce EMI burden by closing one loan"},
    "debt_count_norm":          {"actionable": True, "difficulty": "hard",
                                  "horizon": "3-12 months", "expected_gain_pts": 15,
                                  "action_text": "Consolidate or close existing loans"},
    "bounce_count_norm":        {"actionable": True, "difficulty": "medium",
                                  "horizon": "1-3 months", "expected_gain_pts": 12,
                                  "action_text": "Ensure sufficient balance for auto-debits"},
    "pm_sym_enrollment":        {"actionable": True, "difficulty": "easy",
                                  "horizon": "1-7 days", "expected_gain_pts": 5,
                                  "action_text": "Enroll in PM-SYM pension scheme"},
    "income_bank_deposit_match_ratio": {"actionable": True, "difficulty": "easy",
                                  "horizon": "immediate", "expected_gain_pts": 8,
                                  "action_text": "Route all platform income through bank"},
    "utility_ontime_ratio":     {"actionable": True, "difficulty": "medium",
                                  "horizon": "1-3 months", "expected_gain_pts": 8,
                                  "action_text": "Pay utility bills on time consistently"},
    # Non-actionable features
    "gig_experience_months_norm":    {"actionable": False, "difficulty": "none",
                                      "horizon": "N/A", "expected_gain_pts": 0},
    "income_state_percentile_rank":  {"actionable": False, "difficulty": "none",
                                      "horizon": "N/A", "expected_gain_pts": 0},
    "income_seasonality_amplitude":  {"actionable": False, "difficulty": "none",
                                      "horizon": "N/A", "expected_gain_pts": 0},
}

# ─── State Income Anchors (for normalization) ─────────────────────────────
STATE_INCOME_ANCHORS = {
    "Tamil Nadu": 1.05, "Karnataka": 1.10, "Maharashtra": 1.15,
    "Delhi": 1.20, "Telangana": 1.08, "Gujarat": 1.05,
    "West Bengal": 0.90, "Uttar Pradesh": 0.85, "Rajasthan": 0.88,
    "Kerala": 1.02, "Andhra Pradesh": 0.95, "Bihar": 0.80,
    "Madhya Pradesh": 0.85, "Punjab": 1.00, "Haryana": 1.05,
}
NATIONAL_P90_INCOME = 45000  # INR

# ─── Magnitude Thresholds (SHAP) ──────────────────────────────────────────
MAGNITUDE_THRESHOLDS = {
    "high":       0.05,
    "medium":     0.02,
    "low":        0.005,
    "negligible": 0.0,
}

# ─── XGBoost Training Params ─────────────────────────────────────────────
XGB_DISTILL_PARAMS = {
    "n_estimators": 300,
    "max_depth": 6,
    "learning_rate": 0.05,
    "subsample": 0.8,
    "colsample_bytree": 0.8,
    "reg_alpha": 0.1,
    "reg_lambda": 1.0,
    "tree_method": "exact",  # REQUIRED for m2cgen export
    "random_state": SEED,
    "n_jobs": -1,
}
