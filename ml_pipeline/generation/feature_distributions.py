"""
GigCredit — Parameterized Feature Distributions
================================================
Tier-based Beta/Bernoulli/Poisson params for every pillar.
Tier 0=Excellent, 1=Good, 2=Average, 3=Poor, 4=VeryPoor
"""

import numpy as np

# ── Helpers ──────────────────────────────────────────────────────────────
def sample_beta(rng, a, b):
    return float(np.clip(rng.beta(a, b), 0.0, 1.0))

def sample_bernoulli(rng, p):
    return float(rng.random() < p)

def sample_poisson_norm(rng, lam, max_val):
    return float(np.clip(rng.poisson(lam) / max_val, 0.0, 1.0))

# ── P1 Income Stability ─────────────────────────────────────────────────
P1_PARAMS = {
    "income_stability_cv": {
        "beta_a": [8.0, 6.0, 4.0, 3.0, 2.0],
        "beta_b": [2.0, 3.0, 4.0, 5.0, 6.0],
    },
    "income_months_active_p": [0.95, 0.88, 0.75, 0.62, 0.50],
    "income_platform_verified": {
        "beta_a": [9.0, 7.0, 5.0, 3.0, 2.0],
        "beta_b": [1.0, 2.0, 4.0, 6.0, 8.0],
    },
    "income_lowest_to_avg": {
        "beta_a": [7.0, 5.5, 4.0, 3.0, 2.0],
        "beta_b": [2.0, 3.0, 4.0, 6.0, 7.0],
    },
    "income_source_diversity_lambda": [3.5, 2.8, 2.0, 1.5, 1.2],
    "income_zero_month_lambda":       [0.2, 0.5, 1.0, 2.0, 2.5],
    "income_spike_lambda":            [0.3, 0.6, 1.2, 2.0, 2.8],
}

# ── P2 Payment Discipline ───────────────────────────────────────────────
P2_PARAMS = {
    "utility_ontime": {
        "beta_a": [9.0, 7.0, 5.0, 3.0, 2.0],
        "beta_b": [2.0, 3.0, 4.0, 6.0, 7.0],
    },
    "emi_ontime": {
        "beta_a": [8.0, 6.5, 5.0, 3.0, 2.0],
        "beta_b": [2.0, 3.0, 4.0, 6.0, 7.0],
    },
    "bounce_count_lambda": [0.1, 0.4, 1.0, 2.2, 3.5],
    "late_payment": {
        "beta_a": [9.0, 7.0, 5.0, 3.0, 2.0],
        "beta_b": [2.0, 3.0, 4.0, 5.0, 6.0],
    },
    "standing_instruction": {
        "beta_a": [9.0, 7.5, 5.5, 3.5, 3.0],
        "beta_b": [1.0, 2.0, 4.0, 6.0, 7.0],
    },
}

# ── P3 Debt Management ──────────────────────────────────────────────────
P3_PARAMS = {
    "emi_to_income_mu":   [0.18, 0.28, 0.40, 0.55, 0.65],
    "emi_to_income_sig":  [0.05, 0.07, 0.09, 0.10, 0.10],
    "debt_count_lambda":  [0.8, 1.5, 2.2, 3.0, 3.5],
    "dscr_mu":            [2.5, 1.9, 1.4, 1.0, 0.9],
    "dscr_sig":           [0.4, 0.4, 0.4, 0.3, 0.3],
    "repayment_progress": {
        "beta_a": [7.0, 5.5, 4.0, 3.0, 2.0],
        "beta_b": [3.0, 4.0, 5.0, 6.0, 7.0],
    },
    "informal_debt": {
        "beta_a": [8.0, 6.5, 5.0, 3.5, 3.0],
        "beta_b": [3.0, 4.0, 5.0, 5.5, 5.0],
    },
    "mfi_p":           [0.10, 0.18, 0.28, 0.38, 0.45],
    "debt_stacking_p": [0.05, 0.12, 0.25, 0.42, 0.55],
    "consolidation_p": [0.30, 0.22, 0.12, 0.07, 0.05],
}

# ── P4 Savings Behaviour ────────────────────────────────────────────────
P4_PARAMS = {
    "savings_rate": {
        "beta_a": [6.0, 5.0, 3.5, 2.5, 2.0],
        "beta_b": [3.0, 4.0, 5.0, 6.5, 8.0],
    },
    "balance_lognorm_mu":  [0.80, 0.40, 0.00, -0.30, -0.60],
    "balance_lognorm_sig": [0.30, 0.35, 0.40,  0.40,  0.40],
    "emergency_fund_mu":   [1.0, 0.6, 0.2, -0.3, -1.0],
    "emergency_fund_sig":  [0.4, 0.4, 0.4,  0.4,  0.5],
    "savings_consistency": {
        "beta_a": [8.0, 6.0, 4.0, 2.5, 2.0],
        "beta_b": [2.0, 3.0, 5.0, 6.5, 7.0],
    },
    "rd_sip_p":            [0.65, 0.45, 0.22, 0.10, 0.08],
    "balance_volatility": {
        "beta_a": [7.0, 5.5, 4.0, 3.0, 2.0],
        "beta_b": [2.0, 3.0, 5.0, 6.0, 6.0],
    },
}

# ── P5 Work & Identity ──────────────────────────────────────────────────
P5_PARAMS = {
    "face_match":       {"beta_a": [9.0,8.0,6.5,5.0,4.0], "beta_b": [1.5,2.0,3.0,4.0,4.5]},
    "address_match":    {"beta_a": [8.0,6.5,5.0,3.5,3.0], "beta_b": [2.0,3.0,4.5,5.5,6.0]},
    "name_consistency": {"beta_a": [9.0,8.0,6.0,4.5,3.5], "beta_b": [1.0,1.5,2.5,3.5,4.0]},
    "work_proof_type":  {"beta_a": [8.0,7.0,5.5,4.0,3.0], "beta_b": [2.0,2.5,3.5,4.5,5.0]},
    "employer_score":   {"beta_a": [7.5,6.0,4.5,3.0,2.0], "beta_b": [2.5,3.0,4.5,5.5,6.0]},
    "work_income_consistency": {"beta_a": [8.5,7.0,5.5,3.5,2.5], "beta_b": [1.5,2.5,3.5,5.0,6.0]},
    "customer_rating":  {"beta_a": [8.5,7.0,5.5,3.5,2.5], "beta_b": [1.5,2.5,4.0,5.5,6.0]},
    "work_continuity":  {"beta_a": [8.0,6.5,4.5,3.0,2.0], "beta_b": [2.0,3.0,4.5,5.5,6.5]},
    "income_to_wt":     {"beta_a": [8.0,6.5,5.0,3.0,2.0], "beta_b": [2.0,3.0,4.5,6.0,7.0]},
    "gig_months_lambda":     [48.0, 36.0, 24.0, 14.0, 8.0],
    "multi_platform_lambda": [3.5, 2.8, 2.0, 1.2, 0.8],
    "aadhaar_p":    [0.99, 0.97, 0.93, 0.85, 0.72],
    "pan_p":        [0.98, 0.95, 0.88, 0.78, 0.60],
    "dob_p":        [0.99, 0.98, 0.95, 0.88, 0.75],
    "work_proof_p": [0.95, 0.88, 0.76, 0.60, 0.42],
    "platform_onboard_p": [0.95, 0.88, 0.78, 0.62, 0.45],
    "certification_p":    [0.45, 0.32, 0.20, 0.10, 0.05],
    "alt_id_p":           [0.80, 0.70, 0.55, 0.38, 0.22],
}

# ── P6 Financial Resilience ─────────────────────────────────────────────
P6_PARAMS = {
    "health_insurance_p":  [0.85, 0.65, 0.38, 0.18, 0.06],
    "life_insurance_p":    [0.70, 0.50, 0.28, 0.12, 0.04],
    "vehicle_insurance_p": [0.60, 0.45, 0.25, 0.10, 0.04],
    "pm_sym_p":            [0.45, 0.35, 0.22, 0.10, 0.05],
    "accident_coverage_p": [0.55, 0.40, 0.22, 0.10, 0.04],
    "premium_regularity":  {"beta_a": [8.0,6.5,5.0,3.0,2.0], "beta_b": [2.0,3.0,4.0,6.0,7.0]},
    "financial_shock":     {"beta_a": [8.0,6.0,4.0,2.5,2.0], "beta_b": [2.0,3.0,5.0,6.0,7.0]},
    "liquid_asset_lognorm_mu":  [0.5, 0.2, -0.1, -0.5, -1.0],
    "liquid_asset_lognorm_sig": [0.4, 0.4,  0.4,  0.4,  0.4],
}

# ── P7 Social Accountability ────────────────────────────────────────────
P7_PARAMS = {
    "eshram_p":   [0.80, 0.62, 0.45, 0.28, 0.15],
    "mudra_p":    [0.40, 0.30, 0.20, 0.12, 0.06],
    "svanidhi_p": [0.35, 0.25, 0.15, 0.08, 0.04],
    "kisan_p":    [0.20, 0.15, 0.10, 0.05, 0.02],
    "welfare_p":  [0.60, 0.45, 0.30, 0.18, 0.10],
    "shg_p":      [0.45, 0.32, 0.20, 0.10, 0.05],
    "community_lending": {"beta_a": [6.0,4.5,3.0,2.0,1.5], "beta_b": [3.0,4.0,5.0,6.0,7.0]},
    "social_reference":  {"beta_a": [5.0,4.0,3.0,2.0,1.5], "beta_b": [3.0,4.0,5.0,6.0,7.0]},
    "scheme_count_lambda": [3.5, 2.5, 1.8, 1.0, 0.6],
}

# ── P8 Tax & Compliance ─────────────────────────────────────────────────
P8_PARAMS = {
    "itr_this_year_p":  [0.75, 0.58, 0.38, 0.20, 0.10],
    "itr_years_lambda": [4.5, 3.2, 2.2, 1.2, 0.5],
    "itr_match":        {"beta_a": [8.0,6.5,5.0,3.0,2.0], "beta_b": [2.0,3.0,4.5,6.0,7.0]},
    "gst_p":            [0.35, 0.25, 0.15, 0.07, 0.03],
    "pan_linked_p":     [0.90, 0.80, 0.65, 0.45, 0.28],
    "tax_settled_p":    [0.80, 0.65, 0.45, 0.25, 0.12],
    "gst_regularity":   {"beta_a": [8.0,6.0,4.5,3.0,2.0], "beta_b": [2.0,3.0,4.0,6.0,7.0]},
}

# ── Tier distribution for target generation ──────────────────────────────
TIER_DIST = {0: 0.15, 1: 0.25, 2: 0.30, 3: 0.20, 4: 0.10}
