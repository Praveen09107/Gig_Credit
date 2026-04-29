"""
GigCredit ML Pipeline — Shared Configuration (V3.0 RESOLVED)
==============================================================
Single source of truth. All 6 gap-analysis answers locked here.
Version 3.0 | April 2026
"""

import os
from pathlib import Path

# ═══════════════════════════════════════════════════════════════════════════
# PATHS
# ═══════════════════════════════════════════════════════════════════════════
ROOT_DIR    = Path(__file__).resolve().parent
DATA_DIR    = ROOT_DIR / "data" / "generated"
MODELS_DIR  = ROOT_DIR / "output" / "models"
ASSETS_DIR  = ROOT_DIR / "output" / "assets"
EXPORT_DIR  = ROOT_DIR / "output" / "dart_export"
GOLDEN_DIR  = ROOT_DIR / "output" / "golden"

FLUTTER_ASSETS = ROOT_DIR.parent / "app" / "assets" / "constants"
FLUTTER_MODELS = ROOT_DIR.parent / "app" / "lib" / "scoring" / "models"

for d in [DATA_DIR, MODELS_DIR, ASSETS_DIR, EXPORT_DIR, GOLDEN_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# ═══════════════════════════════════════════════════════════════════════════
# RESOLVED CONSTANTS (Gap Analysis Q1–Q6, locked April 2026)
# ═══════════════════════════════════════════════════════════════════════════
SEED       = 42
N_PROFILES = 15_000          # Q6: 15K (hackathon speed)
N_FEATURES = 95              # base features
N_CROSS    = 20              # cross-pillar features
N_TOTAL    = N_FEATURES + N_CROSS  # 115 total

N_PILLARS_ML = 5             # P1, P2, P3, P4, P6
N_PILLARS    = 8             # P1–P8

ML_PILLARS   = ["P1", "P2", "P3", "P4", "P6"]
RULE_PILLARS = ["P5", "P7", "P8"]
ALL_PILLARS  = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]

# Q3: Work type distribution — 30/30/20/20 (V3_07)
WORK_TYPES = ["platform_worker", "street_vendor",
              "skilled_tradesperson", "freelancer"]
WORK_TYPE_DIST = {
    "platform_worker":      0.30,
    "street_vendor":        0.30,
    "skilled_tradesperson": 0.20,
    "freelancer":           0.20,
}

# Q4: Data split — 70/20/10 (conformal needs own set)
TRAIN_RATIO = 0.70
VAL_RATIO   = 0.20
CAL_RATIO   = 0.10

# Model types per pillar
MODEL_TYPES = {
    "P1": "lgbm", "P2": "xgb", "P3": "xgb_shallow",
    "P4": "lgbm", "P6": "extratrees",
}

# ═══════════════════════════════════════════════════════════════════════════
# Q1: FEATURE NAMES — ml A-Z spec (authoritative, single source)
# ═══════════════════════════════════════════════════════════════════════════
FEATURE_NAMES = [
    # P1 Income Stability (f0–f12, 13 features)
    "avg_monthly_income_norm",           # f0
    "income_stability_cv",               # f1
    "income_growth_slope",               # f2
    "income_months_active",              # f3
    "income_platform_verified_ratio",    # f4
    "income_seasonality_amplitude",      # f5
    "income_source_diversity",           # f6
    "income_bank_deposit_match_ratio",   # f7
    "income_lowest_to_avg_ratio",        # f8
    "income_last_3_vs_prev_3",           # f9
    "income_zero_month_count",           # f10
    "income_irregular_spike_count",      # f11
    "income_state_percentile_rank",      # f12

    # P2 Payment Discipline (f13–f27, 15 features)
    "utility_ontime_ratio",              # f13
    "emi_ontime_ratio",                  # f14
    "bounce_count_norm",                 # f15
    "late_payment_frequency",            # f16
    "payment_regularity_streak",         # f17
    "rent_ontime_ratio",                 # f18
    "credit_card_min_payment_rate",      # f19
    "p2p_repayment_ratio",              # f20
    "utility_advance_payment_ratio",     # f21
    "late_fee_incidence_norm",           # f22
    "payment_channel_digital_ratio",     # f23
    "emi_prepayment_count_norm",         # f24
    "missed_payment_recovery_speed",     # f25
    "standing_instruction_success_rate", # f26
    "payment_amount_consistency",        # f27

    # P3 Debt Management (f28–f36, 9 features)
    "emi_to_income_ratio",               # f28
    "debt_count_norm",                   # f29
    "outstanding_debt_to_income_ratio",  # f30
    "debt_repayment_progress_ratio",     # f31
    "mfi_loan_presence",                 # f32
    "informal_debt_ratio",               # f33
    "debt_stacking_indicator",           # f34
    "debt_service_coverage_ratio",       # f35
    "debt_consolidation_behavior",       # f36

    # P4 Savings Behaviour (f37–f48, 12 features)
    "avg_month_end_balance_norm",        # f37
    "savings_rate",                      # f38
    "balance_growth_slope",              # f39
    "savings_consistency_score",         # f40
    "emergency_fund_months",             # f41
    "recurring_savings_deposit_indicator",# f42
    "balance_volatility_norm",           # f43
    "withdrawal_pattern_regularity",     # f44
    "savings_to_debt_ratio",             # f45
    "digital_wallet_balance_norm",       # f46
    "surplus_after_obligations_ratio",   # f47
    "savings_goal_consistency",          # f48

    # P5 Work & Identity (f49–f66, 18 features)
    "aadhaar_verified",                  # f49
    "pan_verified",                      # f50
    "face_match_score",                  # f51
    "address_match_score",               # f52
    "dob_consistent",                    # f53
    "name_consistency_score",            # f54
    "work_proof_present",                # f55
    "work_proof_type_score",             # f56
    "platform_onboarding_verified",      # f57
    "employer_verification_score",       # f58
    "work_type_income_consistency",      # f59
    "gig_experience_months_norm",        # f60
    "multi_platform_count_norm",         # f61
    "professional_certification",        # f62
    "work_continuity_score",             # f63
    "customer_rating_norm",              # f64
    "income_to_worktype_ratio",          # f65
    "alternate_id_present",              # f66

    # P6 Financial Resilience (f67–f77, 11 features)
    "health_insurance_active",           # f67
    "life_insurance_active",             # f68
    "vehicle_insurance_active",          # f69
    "crop_insurance_active",             # f70
    "accident_coverage_active",          # f71
    "pm_sym_enrollment",                 # f72
    "total_insurance_count_norm",        # f73
    "insurance_premium_regularity",      # f74
    "medical_expense_ratio",             # f75
    "financial_shock_recovery",          # f76
    "liquid_asset_to_income",            # f77

    # P7 Social Accountability (f78–f87, 10 features)
    "eshram_enrolled",                   # f78
    "mudra_loan_history",                # f79
    "pm_svanidhi_enrolled",              # f80
    "pm_kisan_enrolled",                 # f81
    "government_scheme_count_norm",      # f82
    "welfare_scheme_active",             # f83
    "self_help_group_member",            # f84
    "community_lending_record",          # f85
    "social_reference_score",            # f86
    "civic_identity_score",              # f87

    # P8 Tax & Compliance (f88–f94, 7 features)
    "itr_filed_this_year",               # f88
    "itr_years_filed_norm",              # f89
    "itr_income_match_ratio",            # f90
    "gst_registered",                    # f91
    "gst_return_regularity",             # f92
    "pan_linked_to_bank",                # f93
    "tax_liability_settled",             # f94
]

assert len(FEATURE_NAMES) == N_FEATURES, \
    f"Expected {N_FEATURES} features, got {len(FEATURE_NAMES)}"

# ── Cross-pillar feature names (f95–f114) ────────────────────────────────
CROSS_FEATURE_NAMES = [
    # Group A: Income × Debt (4)
    "income_debt_stress_index",              # f95
    "debt_vulnerability_score",              # f96
    "income_emi_coverage",                   # f97
    "income_trend_vs_debt_trend",            # f98
    # Group B: Payment × Savings (3)
    "payment_savings_alignment",             # f99
    "buffer_payment_composite",              # f100
    "digital_savings_discipline",            # f101
    # Group C: Resilience Composite (3)
    "financial_shock_resistance",            # f102
    "resilience_debt_mismatch",              # f103
    "insurance_income_anchor",               # f104
    # Group D: Gig Stability Streaks (4)
    "consistent_earning_payment_streak",     # f105
    "income_payment_trend_alignment",        # f106
    "platform_payment_reliability",          # f107
    "income_floor_payment_consistency",      # f108
    # Group E: Formal Recognition (3)
    "formal_recognition_income_alignment",   # f109
    "tax_income_consistency_ratio",          # f110
    "scheme_income_combined",                # f111
    # Group F: Temporal (3)
    "seasonal_income_volatility",            # f112
    "payment_regularity_entropy",            # f113
    "balance_recovery_speed",                # f114
]

assert len(CROSS_FEATURE_NAMES) == N_CROSS
ALL_FEATURE_NAMES = FEATURE_NAMES + CROSS_FEATURE_NAMES

# ═══════════════════════════════════════════════════════════════════════════
# PILLAR FEATURE SLICING
# ═══════════════════════════════════════════════════════════════════════════
PILLAR_FEATURE_RANGES = {
    "P1": (0, 13),   "P2": (13, 28),  "P3": (28, 37),
    "P4": (37, 49),  "P5": (49, 67),  "P6": (67, 78),
    "P7": (78, 88),  "P8": (88, 95),
}

PILLAR_FEATURE_SLICES = {
    p: FEATURE_NAMES[s:e] for p, (s, e) in PILLAR_FEATURE_RANGES.items()
}

# Cross-pillar routing (which cross features go to which pillar)
P1_CROSS = [95, 96, 97, 98]        # Group A
P2_CROSS = [105, 106, 107, 108]    # Group D
P3_CROSS = [95, 96, 97, 98]        # Group A (shared with P1)
P4_CROSS = [99, 100, 101, 102]     # Group B + C[0]
P6_CROSS = [102, 103, 104]         # Group C

PILLAR_CROSS_INDICES = {
    "P1": P1_CROSS, "P2": P2_CROSS, "P3": P3_CROSS,
    "P4": P4_CROSS, "P6": P6_CROSS,
}

# Full input sizes (base + cross)
PILLAR_INPUT_SIZES = {
    "P1": 17, "P2": 19, "P3": 13, "P4": 16,
    "P5": 18, "P6": 14, "P7": 10, "P8": 7,
}

# ═══════════════════════════════════════════════════════════════════════════
# Q2: PILLAR WEIGHTS — Set A, used EVERYWHERE (one set only)
# ═══════════════════════════════════════════════════════════════════════════
PILLAR_WEIGHTS = {
    "P1": 0.22, "P2": 0.18, "P3": 0.12, "P4": 0.13,
    "P5": 0.10, "P6": 0.10, "P7": 0.08, "P8": 0.07,
}
assert abs(sum(PILLAR_WEIGHTS.values()) - 1.0) < 1e-9, "Pillar weights must sum to 1.0"

# ═══════════════════════════════════════════════════════════════════════════
# Q5: SCORECARD WEIGHTS — DEV_A Guide positional (verified sums)
# ═══════════════════════════════════════════════════════════════════════════
P5_WEIGHTS = [0.15, 0.15, 0.10, 0.08, 0.08, 0.06, 0.05, 0.04,
              0.03, 0.06, 0.04, 0.04, 0.02, 0.02, 0.02, 0.03, 0.02, 0.01]
assert abs(sum(P5_WEIGHTS) - 1.0) < 1e-9, "P5 weights must sum to 1.0"

P7_WEIGHTS = [0.15, 0.12, 0.10, 0.10, 0.08, 0.10, 0.08, 0.12, 0.10, 0.05]
assert abs(sum(P7_WEIGHTS) - 1.0) < 1e-9, "P7 weights must sum to 1.0"

P8_WEIGHTS = [0.25, 0.15, 0.20, 0.15, 0.10, 0.08, 0.07]
assert abs(sum(P8_WEIGHTS) - 1.0) < 1e-9, "P8 weights must sum to 1.0"

# ── Work-Type Normalisation (5 features rescaled) ───────────────────────
NORMALISED_INDICES = {
    1:  "income_cv",
    2:  "income_growth_norm",
    4:  "gig_share_norm",
    28: "payment_gap_freq",
    47: "balance_variability",
}

# ── State Income Anchors (₹/month) ──────────────────────────────────────
STATE_INCOME_ANCHORS = {
    "Tamil Nadu": 22000, "Maharashtra": 28000, "Karnataka": 26000,
    "Delhi": 35000, "Bihar": 13000, "Uttar Pradesh": 15000,
    "Kerala": 24000, "West Bengal": 18000, "Rajasthan": 16000,
    "Madhya Pradesh": 14000, "Gujarat": 24000, "Andhra Pradesh": 20000,
    "Telangana": 25000, "Haryana": 26000, "Punjab": 22000,
    "Odisha": 15000, "Chhattisgarh": 14000, "Jharkhand": 13000,
    "Assam": 14000, "Uttarakhand": 18000, "Himachal Pradesh": 20000,
    "Goa": 30000, "Tripura": 13000,
}
STATES = list(STATE_INCOME_ANCHORS.keys())

# ═══════════════════════════════════════════════════════════════════════════
# DISPLAY NAMES (115 human-readable labels)
# ═══════════════════════════════════════════════════════════════════════════
FEATURE_DISPLAY_NAMES = {
    "avg_monthly_income_norm":        "Average Monthly Income",
    "income_stability_cv":            "Income Stability",
    "income_growth_slope":            "Income Growth Trend",
    "income_months_active":           "Active Income Months",
    "income_platform_verified_ratio": "Platform-Verified Income",
    "income_seasonality_amplitude":   "Income Seasonality",
    "income_source_diversity":        "Income Source Diversity",
    "income_bank_deposit_match_ratio":"Bank Deposit Match",
    "income_lowest_to_avg_ratio":     "Lowest-to-Average Income",
    "income_last_3_vs_prev_3":        "Recent Income Trend",
    "income_zero_month_count":        "Zero-Income Months",
    "income_irregular_spike_count":   "Irregular Income Spikes",
    "income_state_percentile_rank":   "State Income Rank",
    "utility_ontime_ratio":           "Utility Bills On-Time",
    "emi_ontime_ratio":               "EMI Payments On-Time",
    "bounce_count_norm":              "ECS Bounces",
    "late_payment_frequency":         "Late Payment Frequency",
    "payment_regularity_streak":      "Payment Streak",
    "rent_ontime_ratio":              "Rent On-Time",
    "credit_card_min_payment_rate":   "Credit Card Min Payment",
    "p2p_repayment_ratio":           "P2P Repayment",
    "utility_advance_payment_ratio":  "Utility Advance Payment",
    "late_fee_incidence_norm":        "Late Fee Incidence",
    "payment_channel_digital_ratio":  "Digital Payment Ratio",
    "emi_prepayment_count_norm":      "EMI Prepayment",
    "missed_payment_recovery_speed":  "Missed Payment Recovery",
    "standing_instruction_success_rate": "Standing Instructions",
    "payment_amount_consistency":     "Payment Consistency",
    "emi_to_income_ratio":            "EMI-to-Income Ratio",
    "debt_count_norm":                "Number of Active Loans",
    "outstanding_debt_to_income_ratio":"Outstanding Debt Ratio",
    "debt_repayment_progress_ratio":  "Debt Repayment Progress",
    "mfi_loan_presence":              "MFI Loan Present",
    "informal_debt_ratio":            "Informal Debt Ratio",
    "debt_stacking_indicator":        "Debt Stacking",
    "debt_service_coverage_ratio":    "Debt Service Coverage",
    "debt_consolidation_behavior":    "Debt Consolidation",
    "avg_month_end_balance_norm":     "Average Bank Balance",
    "savings_rate":                   "Monthly Savings Rate",
    "balance_growth_slope":           "Balance Growth Trend",
    "savings_consistency_score":      "Savings Consistency",
    "emergency_fund_months":          "Emergency Fund Months",
    "recurring_savings_deposit_indicator": "Recurring Savings",
    "balance_volatility_norm":        "Balance Volatility",
    "withdrawal_pattern_regularity":  "Withdrawal Regularity",
    "savings_to_debt_ratio":          "Savings-to-Debt Ratio",
    "digital_wallet_balance_norm":    "Digital Wallet Balance",
    "surplus_after_obligations_ratio":"Surplus After Obligations",
    "savings_goal_consistency":       "Savings Goal Consistency",
    "aadhaar_verified":               "Aadhaar Verified",
    "pan_verified":                   "PAN Verified",
    "face_match_score":               "Face Match Score",
    "address_match_score":            "Address Match Score",
    "dob_consistent":                 "DOB Consistent",
    "name_consistency_score":         "Name Consistency",
    "work_proof_present":             "Work Proof Document",
    "work_proof_type_score":          "Work Proof Quality",
    "platform_onboarding_verified":   "Platform Onboarding",
    "employer_verification_score":    "Employer Verification",
    "work_type_income_consistency":   "Work-Income Consistency",
    "gig_experience_months_norm":     "Gig Work Experience",
    "multi_platform_count_norm":      "Multi-Platform Count",
    "professional_certification":     "Professional Certification",
    "work_continuity_score":          "Work Continuity",
    "customer_rating_norm":           "Customer Rating",
    "income_to_worktype_ratio":       "Income-to-WorkType Ratio",
    "alternate_id_present":           "Alternate ID Present",
    "health_insurance_active":        "Health Insurance",
    "life_insurance_active":          "Life Insurance",
    "vehicle_insurance_active":       "Vehicle Insurance",
    "crop_insurance_active":          "Crop Insurance",
    "accident_coverage_active":       "Accident Coverage",
    "pm_sym_enrollment":              "PM-SYM Enrollment",
    "total_insurance_count_norm":     "Insurance Count",
    "insurance_premium_regularity":   "Premium Regularity",
    "medical_expense_ratio":          "Medical Expense Ratio",
    "financial_shock_recovery":       "Shock Recovery",
    "liquid_asset_to_income":         "Liquid Assets",
    "eshram_enrolled":                "e-Shram Registered",
    "mudra_loan_history":             "Mudra Loan History",
    "pm_svanidhi_enrolled":           "PM SVANidhi",
    "pm_kisan_enrolled":              "PM-KISAN",
    "government_scheme_count_norm":   "Govt Scheme Count",
    "welfare_scheme_active":          "Welfare Scheme",
    "self_help_group_member":         "SHG Member",
    "community_lending_record":       "Community Lending",
    "social_reference_score":         "Social Reference",
    "civic_identity_score":           "Civic Identity",
    "itr_filed_this_year":            "ITR Filed",
    "itr_years_filed_norm":           "ITR History",
    "itr_income_match_ratio":         "ITR Income Match",
    "gst_registered":                 "GST Registered",
    "gst_return_regularity":          "GST Return Regularity",
    "pan_linked_to_bank":             "PAN Linked to Bank",
    "tax_liability_settled":          "Tax Liability Settled",
    # Cross-pillar
    "income_debt_stress_index":       "Income-Debt Stress",
    "debt_vulnerability_score":       "Debt Vulnerability",
    "income_emi_coverage":            "Income-EMI Coverage",
    "income_trend_vs_debt_trend":     "Income vs Debt Trend",
    "payment_savings_alignment":      "Payment-Savings Alignment",
    "buffer_payment_composite":       "Buffer-Payment Composite",
    "digital_savings_discipline":     "Digital Savings Discipline",
    "financial_shock_resistance":     "Financial Shock Resistance",
    "resilience_debt_mismatch":       "Resilience-Debt Mismatch",
    "insurance_income_anchor":        "Insurance-Income Anchor",
    "consistent_earning_payment_streak": "Earning-Payment Streak",
    "income_payment_trend_alignment": "Income-Payment Trend",
    "platform_payment_reliability":   "Platform Payment Reliability",
    "income_floor_payment_consistency":"Income Floor Consistency",
    "formal_recognition_income_alignment":"Formal Recognition",
    "tax_income_consistency_ratio":   "Tax-Income Consistency",
    "scheme_income_combined":         "Scheme-Income Combined",
    "seasonal_income_volatility":     "Seasonal Volatility",
    "payment_regularity_entropy":     "Payment Regularity Entropy",
    "balance_recovery_speed":         "Balance Recovery Speed",
}

# ═══════════════════════════════════════════════════════════════════════════
# TRAINING HYPERPARAMETERS
# ═══════════════════════════════════════════════════════════════════════════

# Pre-Training (skipped per user decision — proxy attention instead)
PRETRAIN = {
    "epochs": 100, "batch_size": 256, "lr": 1e-3,
    "weight_decay": 1e-4, "mask_ratio": 0.15,
    "early_stop_patience": 15, "grad_clip": 1.0,
    "hidden_dim": 256, "backbone_out": 128,
    "work_embed_dim": 32, "dropout": 0.15,
    "target_loss": 0.015,
}

# XGBoost (for P2, P3 — requires tree_method=exact for m2cgen)
XGB_PARAMS_P2 = {
    "max_depth": 4, "n_estimators": 300, "learning_rate": 0.05,
    "colsample_bytree": 0.7, "min_child_weight": 10,
    "reg_lambda": 2.0, "reg_alpha": 0.5, "subsample": 0.8,
    "tree_method": "exact", "random_state": SEED, "n_jobs": -1,
}
XGB_PARAMS_P3 = {
    "max_depth": 2, "n_estimators": 80, "learning_rate": 0.05,
    "colsample_bytree": 0.8, "reg_lambda": 5.0, "reg_alpha": 1.0,
    "tree_method": "exact", "random_state": SEED, "n_jobs": -1,
}

# Conformal
CONFORMAL_ALPHA   = 0.10
MIN_CALIBRATION_N = 100

# Meta-Learner
META_CV_FOLDS = 5
META_C        = 1.0
META_MAX_ITER = 1000

# ── Scoring Output ───────────────────────────────────────────────────────
SCORE_MIN   = 300
SCORE_MAX   = 900
SCORE_RANGE = SCORE_MAX - SCORE_MIN

GRADE_BANDS = [
    (800, 900, "A+", "Exceptional",   "Low Risk"),
    (750, 799, "A",  "Excellent",     "Low Risk"),
    (700, 749, "B+", "Very Good",     "Low Risk"),
    (650, 699, "B",  "Good",          "Low Risk"),
    (600, 649, "C+", "Above Average", "Medium Risk"),
    (550, 599, "C",  "Average",       "Medium Risk"),
    (300, 549, "D",  "Below Average", "High Risk"),
]

# ── Parity Gate ──────────────────────────────────────────────────────────
PARITY_MAX_ABS_DIFF  = 1e-5
PARITY_MEAN_ABS_DIFF = 1e-6

# ── Fairness Thresholds ─────────────────────────────────────────────────
FAIRNESS_FOUR_FIFTHS      = 0.80
EQUALIZED_ODDS_TPR_GAP    = 0.10
CALIBRATION_ECE_THRESHOLD = 0.05

# ── Loan Engine ─────────────────────────────────────────────────────────
PRODUCT_THRESHOLDS = {
    "emergency_micro": 450,
    "income_bridge":   550,
    "growth":          650,
}
PRODUCT_AMOUNTS = {
    "emergency_micro": (5_000,   25_000),
    "income_bridge":   (25_000, 100_000),
    "growth":          (100_000, 500_000),
}
APR_TABLE = [
    (800, 900, 12.0),
    (720, 799, 15.0),
    (640, 719, 18.0),
    (560, 639, 21.0),
    (480, 559, 24.0),
    (300, 479, None),
]
MIN_DSCR       = 1.25
MAX_EMI_RATIO  = 0.50
MAX_LTI_RATIO  = 10.0

# ── Gemini / LLM ────────────────────────────────────────────────────────
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODEL   = "gemini-2.0-flash"

# ── Loan LightGBM Features ──────────────────────────────────────────────
LOAN_FEATURES = [
    "final_score",
    "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8",
    "dscr", "post_loan_emi_ratio", "loan_to_income",
    "payment_streak", "insurance_coverage",
    "savings_buffer_months", "income_growth_slope",
    "w_platform", "w_vendor",
]
