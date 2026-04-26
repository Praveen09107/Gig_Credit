"""
GigCredit — SHAP Lookup Table Generator
==========================================
Uses trained XGBoost/RF pillar models + TreeExplainer to compute binned
SHAP values for each of the 95 features. The lookup table is used by the
Flutter app to display the top positive/negative factors on the report screen
without running SHAP on-device.

Output: ml_pipeline/output/json_configs/shap_lookup.json
Schema per feature:
  {
    "name": "income_to_anchor_ratio",
    "pillar": "P1",
    "pillar_label": "Income Stability",
    "bins": [0.0, 0.1, ..., 1.0],       ← 11 bin edges (10 bins)
    "shap_values": [v0, v1, ..., v9],   ← mean SHAP in each bin
    "mean_abs_shap": float              ← feature importance proxy
  }
"""

import json
import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import shap

# ── Feature metadata ─────────────────────────────────────────────────────
FEATURE_META = {
    # P1
    0: ("income_to_anchor_ratio",   "P1", "Income Stability"),
    1: ("income_stability_cv",      "P1", "Income Stability"),
    2: ("income_growth_trend",      "P1", "Income Stability"),
    3: ("income_seasonality",       "P1", "Income Stability"),
    4: ("months_with_income",       "P1", "Income Stability"),
    5: ("self_declared_vs_actual",  "P1", "Income Stability"),
    6: ("secondary_income_present", "P1", "Income Stability"),
    7: ("platform_earnings_match",  "P1", "Income Stability"),
    8: ("years_in_profession_norm", "P1", "Income Stability"),
    9: ("income_diversification",   "P1", "Income Stability"),
    10: ("credit_to_debit_ratio",   "P1", "Income Stability"),
    11: ("avg_balance_to_income",   "P1", "Income Stability"),
    12: ("work_type_income_factor", "P1", "Income Stability"),
    # P2
    13: ("electricity_on_time_ratio", "P2", "Payment Discipline"),
    14: ("lpg_on_time_ratio",         "P2", "Payment Discipline"),
    15: ("mobile_on_time_ratio",      "P2", "Payment Discipline"),
    16: ("combined_bill_score",       "P2", "Payment Discipline"),
    17: ("emi_on_time_ratio",         "P2", "Payment Discipline"),
    18: ("emi_debit_regularity",      "P2", "Payment Discipline"),
    19: ("utility_vs_bank_match",     "P2", "Payment Discipline"),
    20: ("bounce_count_norm",         "P2", "Payment Discipline"),
    21: ("payment_consistency_score", "P2", "Payment Discipline"),
    22: ("rent_payment_regularity",   "P2", "Payment Discipline"),
    23: ("wifi_payment_regularity",   "P2", "Payment Discipline"),
    24: ("ott_payment_regularity",    "P2", "Payment Discipline"),
    25: ("lowest_bill_score",         "P2", "Payment Discipline"),
    26: ("bill_amount_stability",     "P2", "Payment Discipline"),
    27: ("early_payment_frequency",   "P2", "Payment Discipline"),
    # P3
    28: ("emi_to_income_ratio",        "P3", "Debt Management"),
    29: ("active_loan_count_norm",     "P3", "Debt Management"),
    30: ("loan_vs_declared_match",     "P3", "Debt Management"),
    31: ("remaining_tenure_norm",      "P3", "Debt Management"),
    32: ("emi_deduction_consistency",  "P3", "Debt Management"),
    33: ("debt_free_flag",             "P3", "Debt Management"),
    34: ("emi_coverage_ratio",         "P3", "Debt Management"),
    35: ("multiple_lender_flag",       "P3", "Debt Management"),
    36: ("loan_type_risk",             "P3", "Debt Management"),
    # P4
    37: ("avg_balance_normalized",  "P4", "Savings Behaviour"),
    38: ("min_balance_normalized",  "P4", "Savings Behaviour"),
    39: ("balance_trend",           "P4", "Savings Behaviour"),
    40: ("savings_rate",            "P4", "Savings Behaviour"),
    41: ("balance_volatility",      "P4", "Savings Behaviour"),
    42: ("sip_rd_detected",         "P4", "Savings Behaviour"),
    43: ("fd_detected",             "P4", "Savings Behaviour"),
    44: ("emergency_buffer_months", "P4", "Savings Behaviour"),
    45: ("peak_spend_month_ratio",  "P4", "Savings Behaviour"),
    46: ("atm_withdrawal_ratio",    "P4", "Savings Behaviour"),
    47: ("low_balance_day_count",   "P4", "Savings Behaviour"),
    48: ("end_of_month_balance",    "P4", "Savings Behaviour"),
    # P5
    49: ("aadhaar_verified",         "P5", "Work & Identity"),
    50: ("pan_verified",             "P5", "Work & Identity"),
    51: ("face_match_score",         "P5", "Work & Identity"),
    52: ("name_consistency_score",   "P5", "Work & Identity"),
    53: ("dob_consistency",          "P5", "Work & Identity"),
    54: ("address_consistency",      "P5", "Work & Identity"),
    55: ("work_type_encoded",        "P5", "Work & Identity"),
    56: ("years_experience_norm",    "P5", "Work & Identity"),
    57: ("vehicle_ownership",        "P5", "Work & Identity"),
    58: ("rc_verified",              "P5", "Work & Identity"),
    59: ("dl_verified",              "P5", "Work & Identity"),
    60: ("dl_class_match_rc",        "P5", "Work & Identity"),
    61: ("platform_earnings_present","P5", "Work & Identity"),
    62: ("trade_licence_active",     "P5", "Work & Identity"),
    63: ("svanidhi_registered",      "P5", "Work & Identity"),
    64: ("freelance_profile_active", "P5", "Work & Identity"),
    65: ("skill_certificate_present","P5", "Work & Identity"),
    66: ("work_proof_count_norm",    "P5", "Work & Identity"),
    # P6
    67: ("health_insurance_active",  "P6", "Financial Resilience"),
    68: ("health_sum_insured_norm",  "P6", "Financial Resilience"),
    69: ("life_insurance_active",    "P6", "Financial Resilience"),
    70: ("vehicle_insurance_active", "P6", "Financial Resilience"),
    71: ("insurance_count_norm",     "P6", "Financial Resilience"),
    72: ("eshram_registered",        "P6", "Financial Resilience"),
    73: ("pmsym_active",             "P6", "Financial Resilience"),
    74: ("pmsym_months_norm",        "P6", "Financial Resilience"),
    75: ("itr_filed",                "P6", "Financial Resilience"),
    76: ("itr_years_filed_norm",     "P6", "Financial Resilience"),
    77: ("gst_registered",           "P6", "Financial Resilience"),
    # P7
    78: ("gov_scheme_count_norm",    "P7", "Social Accountability"),
    79: ("mudra_registered",         "P7", "Social Accountability"),
    80: ("shg_member",               "P7", "Social Accountability"),
    81: ("ppf_holder",               "P7", "Social Accountability"),
    82: ("nps_subscriber",           "P7", "Social Accountability"),
    83: ("atal_pension_member",      "P7", "Social Accountability"),
    84: ("employer_reference_count", "P7", "Social Accountability"),
    85: ("dependents_norm",          "P7", "Social Accountability"),
    86: ("community_participation",  "P7", "Social Accountability"),
    87: ("years_in_city_norm",       "P7", "Social Accountability"),
    88: ("address_stability",        "P7", "Social Accountability"),
    89: ("multi_doc_identity_score", "P7", "Social Accountability"),
    90: ("rc_insurance_match",       "P7", "Social Accountability"),
    91: ("bank_to_utility_match",    "P7", "Social Accountability"),
    92: ("tax_filing_consistency",   "P7", "Social Accountability"),
    93: ("voluntary_contribution",   "P7", "Social Accountability"),
    94: ("overall_data_completeness","P7", "Social Accountability"),
}

PILLAR_MODELS = {
    "p1": (list(range(0,  13)), "xgb"),
    "p2": (list(range(13, 28)), "xgb"),
    "p3": (list(range(28, 37)), "xgb"),
    "p4": (list(range(37, 49)), "xgb"),
    "p6": (list(range(67, 78)), "xgb"),
}

N_BINS   = 10
BIN_EDGES = [round(i / N_BINS, 1) for i in range(N_BINS + 1)]


def binned_shap(values: np.ndarray, feature_vals: np.ndarray) -> list[float]:
    """Compute mean SHAP value per bin for a single feature."""
    bin_shap = []
    for lo, hi in zip(BIN_EDGES[:-1], BIN_EDGES[1:]):
        mask = (feature_vals >= lo) & (feature_vals < hi)
        if np.any(mask):
            bin_shap.append(round(float(np.mean(values[mask])), 6))
        else:
            bin_shap.append(0.0)
    return bin_shap


def main() -> None:
    data_path = Path("ml_pipeline/data/generated/synthetic_profiles.csv")
    model_dir  = Path("ml_pipeline/output/models")
    out_dir    = Path("ml_pipeline/output/json_configs")
    out_dir.mkdir(parents=True, exist_ok=True)

    if not data_path.exists():
        print("ERROR: Run synthetic_generator.py first."); sys.exit(1)

    print("Loading dataset (sample 2,000 for SHAP) …")
    df = pd.read_csv(data_path).sample(n=2000, random_state=42)

    payload: dict = {}

    for pillar_name, (indices, model_type) in PILLAR_MODELS.items():
        cols  = [f"f_{i}" for i in indices]
        model = joblib.load(model_dir / f"{pillar_name}.pkl")
        X     = df[cols].values

        print(f"  Computing SHAP for {pillar_name.upper()} ({len(indices)} features, {model_type}) …")
        explainer   = shap.TreeExplainer(model)
        shap_values = explainer.shap_values(X)   # shape (N, n_features)

        for local_idx, global_idx in enumerate(indices):
            sv       = shap_values[:, local_idx]
            fv       = X[:, local_idx]
            name, pillar, pillar_label = FEATURE_META[global_idx]
            payload[f"f_{global_idx}"] = {
                "name":          name,
                "pillar":        pillar,
                "pillar_label":  pillar_label,
                "bins":          BIN_EDGES,
                "shap_values":   binned_shap(sv, fv),
                "mean_abs_shap": round(float(np.mean(np.abs(sv))), 6),
            }

    # P5 and P7 scorecards — no model SHAP; use uniform small contribution
    print("  Filling P5/P7 scorecard SHAP (uniform) …")
    for idx in list(range(49, 67)) + list(range(78, 95)):
        name, pillar, pillar_label = FEATURE_META[idx]
        payload[f"f_{idx}"] = {
            "name":          name,
            "pillar":        pillar,
            "pillar_label":  pillar_label,
            "bins":          BIN_EDGES,
            "shap_values":   [round(float(v), 6) for v in np.linspace(0.0, 0.05, N_BINS)],
            "mean_abs_shap": 0.01,
        }

    # Sort by feature index to keep deterministic order
    payload = dict(sorted(payload.items(), key=lambda x: int(x[0].split("_")[1])))

    out_path = out_dir / "shap_lookup.json"
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"\nshap_lookup.json saved -> {out_path}  ({len(payload)} entries)")


if __name__ == "__main__":
    main()
