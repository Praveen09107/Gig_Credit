"""
GigCredit — Synthetic Data Generator
=====================================
Generates 10,000 semantically meaningful gig worker profiles.
Each profile has exactly 95 features matching COMP_18_FEATURE_ENGINEERING_95_FEATURES.md,
normalized to [0.0, 1.0], with realistic inter-pillar correlations.

Feature layout:
  P1 Income Stability     : f_0  – f_12  (13 features)
  P2 Payment Discipline   : f_13 – f_27  (15 features)
  P3 Debt Management      : f_28 – f_36  ( 9 features)
  P4 Savings Behaviour    : f_37 – f_48  (12 features)
  P5 Work & Identity      : f_49 – f_66  (18 features)
  P6 Financial Resilience : f_67 – f_77  (11 features)
  P7 Social Accountability: f_78 – f_94  (17 features)
"""

import json
from pathlib import Path

import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# WORK-TYPE INCOME PARAMETERS
# ---------------------------------------------------------------------------
_INCOME_PARAMS = {
    "platform_worker": dict(mean=18_000, std=5_000, factor=0.65),
    "vendor":          dict(mean=15_000, std=4_000, factor=0.60),
    "tradesperson":    dict(mean=20_000, std=6_000, factor=0.70),
    "freelancer":      dict(mean=25_000, std=8_000, factor=0.75),
}
_WORK_TYPES = list(_INCOME_PARAMS.keys())
_STATE_MEDIAN_INCOME = 15_000.0


def _clip(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return float(np.clip(x, lo, hi))


def _beta(rng: np.random.Generator, a: float, b: float) -> float:
    """Sample from Beta(a,b) — always in [0,1]."""
    return float(rng.beta(a, b))


def _norm(rng: np.random.Generator, mu: float, sigma: float) -> float:
    return float(rng.normal(mu, sigma))


def generate_one_profile(rng: np.random.Generator, work_type: str) -> dict:
    """
    Generate a single semantically coherent gig worker profile.
    Returns a flat dict with keys f_0..f_94 and 'target'.
    """
    params = _INCOME_PARAMS[work_type]

    # ── Core latent variables (drive correlations across pillars) ──────────
    income_quality   = _beta(rng, 3, 2)   # high → good income features
    discipline       = _beta(rng, 3, 2)   # high → pays bills/EMI on time
    debt_load        = _beta(rng, 2, 3)   # high → more debt (bad)
    savings_habit    = _beta(rng, 2.5, 2) # high → saves well
    identity_quality = _beta(rng, 4, 1.5) # high → all docs verified
    resilience       = _beta(rng, 2.5, 2) # high → insurance, ITR etc.
    social_score     = _beta(rng, 2, 2)   # high → more gov scheme participation

    avg_monthly_income = max(5_000.0, rng.normal(params["mean"], params["std"]))
    work_factor = params["factor"]

    # ─────────────────────────────────────────────────────────────────────
    # P1 — Income Stability (f_0 … f_12)
    # ─────────────────────────────────────────────────────────────────────
    f0  = _clip(avg_monthly_income / _STATE_MEDIAN_INCOME * 0.6 * income_quality + _norm(rng, 0, 0.05))
    f1  = _clip(income_quality * 0.85 + _norm(rng, 0, 0.06))   # income_stability_cv
    f2  = _clip(income_quality * 0.7  + _norm(rng, 0, 0.08))   # income_growth_trend
    f3  = _clip(income_quality * 0.75 + _norm(rng, 0, 0.07))   # income_seasonality
    f4  = _clip(0.5 + income_quality * 0.45 + _norm(rng, 0, 0.04))  # months_with_income
    f5  = _clip(0.7 + income_quality * 0.25 + _norm(rng, 0, 0.05))  # self_declared_vs_actual
    f6  = _clip(float(rng.random() < (0.3 + income_quality * 0.4)))  # secondary_income_present
    f7  = _clip(income_quality * 0.8  + _norm(rng, 0, 0.08))   # platform_earnings_match
    f8  = _clip(work_factor * 0.6     + _norm(rng, 0, 0.07))   # years_in_profession_norm
    f9  = _clip(income_quality * 0.6  + _norm(rng, 0, 0.07))   # income_diversification
    f10 = _clip(0.4 + income_quality * 0.5 + _norm(rng, 0, 0.05))  # credit_to_debit_ratio
    f11 = _clip(savings_habit  * 0.7  + _norm(rng, 0, 0.07))   # avg_balance_to_income
    f12 = work_factor                                            # work_type_income_factor

    # ─────────────────────────────────────────────────────────────────────
    # P2 — Payment Discipline (f_13 … f_27)
    # ─────────────────────────────────────────────────────────────────────
    f13 = _clip(discipline * 0.9 + _norm(rng, 0, 0.06))   # electricity_on_time_ratio
    f14 = _clip(discipline * 0.85+ _norm(rng, 0, 0.07))   # lpg_on_time_ratio
    f15 = _clip(discipline * 0.9 + _norm(rng, 0, 0.05))   # mobile_on_time_ratio
    f16 = _clip((f13 + f14 + f15) / 3.0)                  # combined_bill_score
    f17 = _clip(discipline * 0.85+ _norm(rng, 0, 0.08))   # emi_on_time_ratio
    f18 = _clip(discipline * 0.8 + _norm(rng, 0, 0.07))   # emi_debit_regularity
    f19 = _clip(discipline * 0.75+ _norm(rng, 0, 0.08))   # utility_vs_bank_match
    f20 = _clip(1.0 - debt_load * 0.3 + _norm(rng, 0, 0.05))  # bounce_count_norm
    f21 = _clip((f13 + f17 + f20) / 3.0 + _norm(rng, 0, 0.03))  # payment_consistency_score
    f22 = _clip(discipline * 0.7 + 0.2 + _norm(rng, 0, 0.06))   # rent_payment_regularity
    f23 = _clip(discipline * 0.7 + _norm(rng, 0, 0.08))   # wifi_payment_regularity
    f24 = _clip(discipline * 0.65+ _norm(rng, 0, 0.08))   # ott_payment_regularity
    f25 = _clip(min(f13, f14, f15) + _norm(rng, 0, 0.03)) # lowest_bill_score
    f26 = _clip(discipline * 0.75+ _norm(rng, 0, 0.07))   # bill_amount_stability
    f27 = _clip(discipline * 0.5 + _norm(rng, 0, 0.08))   # early_payment_frequency

    # ─────────────────────────────────────────────────────────────────────
    # P3 — Debt Management (f_28 … f_36)
    # ─────────────────────────────────────────────────────────────────────
    f28 = _clip(debt_load * 0.6 + _norm(rng, 0, 0.07))    # emi_to_income_ratio (higher=worse, but normalized)
    f29 = _clip(debt_load * 0.5 + _norm(rng, 0, 0.07))    # active_loan_count_norm
    f30 = _clip(discipline * 0.6 + 0.3 + _norm(rng, 0, 0.06))  # loan_vs_declared_match
    f31 = _clip(debt_load * 0.4 + _norm(rng, 0, 0.07))    # remaining_tenure_norm
    f32 = _clip(discipline * 0.7 + _norm(rng, 0, 0.07))   # emi_deduction_consistency
    f33 = _clip(float(rng.random() < (0.4 + (1 - debt_load) * 0.4)))  # debt_free_flag
    f34 = _clip(1.0 - debt_load * 0.7 + income_quality * 0.2 + _norm(rng, 0, 0.05))  # emi_coverage_ratio
    f35 = _clip(float(rng.random() < debt_load * 0.5))     # multiple_lender_flag
    # loan_type_risk: 0.3 personal, 0.5 business, 0.7 two-wheeler
    _loan_type = rng.choice([0.3, 0.5, 0.7], p=[0.5, 0.2, 0.3])
    f36 = _clip(float(_loan_type) if debt_load > 0.3 else 0.5)

    # ─────────────────────────────────────────────────────────────────────
    # P4 — Savings Behaviour (f_37 … f_48)
    # ─────────────────────────────────────────────────────────────────────
    f37 = _clip(savings_habit * 0.8 + _norm(rng, 0, 0.07))  # avg_balance_normalized
    f38 = _clip(savings_habit * 0.75+ _norm(rng, 0, 0.08))  # min_balance_normalized
    f39 = _clip(savings_habit * 0.7 + income_quality * 0.2 + _norm(rng, 0, 0.06))  # balance_trend
    f40 = _clip(savings_habit * 0.6 + income_quality * 0.2 + _norm(rng, 0, 0.07))  # savings_rate
    f41 = _clip(savings_habit * 0.7 + _norm(rng, 0, 0.07))  # balance_volatility
    f42 = _clip(float(rng.random() < (0.2 + savings_habit * 0.5)))  # sip_rd_detected
    f43 = _clip(float(rng.random() < (0.1 + savings_habit * 0.35))) # fd_detected
    f44 = _clip(savings_habit * 0.6 + _norm(rng, 0, 0.07))  # emergency_buffer_months
    f45 = _clip(1.0 - savings_habit * 0.4 + _norm(rng, 0, 0.06))  # peak_spend_month_ratio (inverted)
    f46 = _clip(0.5 - savings_habit * 0.3 + _norm(rng, 0, 0.07))  # atm_withdrawal_ratio
    f47 = _clip(1.0 - savings_habit * 0.6 + _norm(rng, 0, 0.07))  # low_balance_day_count (inverted)
    f48 = _clip(savings_habit * 0.7 + _norm(rng, 0, 0.07))  # end_of_month_balance

    # ─────────────────────────────────────────────────────────────────────
    # P5 — Work & Identity (f_49 … f_66)
    # ─────────────────────────────────────────────────────────────────────
    f49 = _clip(float(rng.random() < (0.7 + identity_quality * 0.28)))  # aadhaar_verified
    f50 = _clip(float(rng.random() < (0.6 + identity_quality * 0.35)))  # pan_verified
    f51 = _clip(identity_quality * 0.85 + _norm(rng, 0, 0.07))  # face_match_score
    f52 = _clip(identity_quality * 0.9  + _norm(rng, 0, 0.05))  # name_consistency_score
    f53 = _clip(float(rng.random() < (0.65 + identity_quality * 0.3))) # dob_consistency
    f54 = _clip(identity_quality * 0.75 + _norm(rng, 0, 0.07))  # address_consistency
    # work_type_encoded
    _wt_enc = {"platform_worker": 0.7, "vendor": 0.6, "tradesperson": 0.7, "freelancer": 0.8}
    f55 = _wt_enc[work_type]
    f56 = _clip(work_factor * 0.6 + _norm(rng, 0, 0.07))  # years_experience_norm
    f57 = _clip(float(rng.random() < (0.4 + identity_quality * 0.4)))  # vehicle_ownership
    f58 = _clip(float(work_type == "platform_worker") * float(rng.random() < 0.85))  # rc_verified
    f59 = _clip(float(work_type == "platform_worker") * float(rng.random() < 0.80))  # dl_verified
    f60 = _clip(f58 * float(rng.random() < 0.9))  # dl_class_match_rc
    f61 = _clip(float(work_type == "platform_worker") * float(rng.random() < 0.88))  # platform_earnings_present
    f62 = _clip(float(work_type in ("vendor", "tradesperson")) * float(rng.random() < 0.65))  # trade_licence_active
    f63 = _clip(float(work_type == "vendor") * float(rng.random() < 0.55))           # svanidhi_registered
    f64 = _clip(float(work_type == "freelancer") * float(rng.random() < 0.75))       # freelance_profile_active
    f65 = _clip(float(work_type == "tradesperson") * float(rng.random() < 0.60))     # skill_certificate_present
    f66 = _clip(identity_quality * 0.7 + _norm(rng, 0, 0.06))  # work_proof_count_norm

    # ─────────────────────────────────────────────────────────────────────
    # P6 — Financial Resilience (f_67 … f_77)
    # ─────────────────────────────────────────────────────────────────────
    f67 = _clip(float(rng.random() < (0.2 + resilience * 0.65)))  # health_insurance_active
    f68 = _clip(resilience * 0.5 * f67 + _norm(rng, 0, 0.04))     # health_sum_insured_norm
    f69 = _clip(float(rng.random() < (0.1 + resilience * 0.5)))   # life_insurance_active
    f70 = _clip(float(rng.random() < (0.3 + resilience * 0.55)))  # vehicle_insurance_active
    f71 = _clip((f67 + f69 + f70) / 3.0)                          # insurance_count_norm
    f72 = _clip(float(rng.random() < (0.25 + resilience * 0.55))) # eshram_registered
    f73 = _clip(float(rng.random() < (0.15 + resilience * 0.45))) # pmsym_active
    f74 = _clip(resilience * 0.6 * f73 + _norm(rng, 0, 0.05))     # pmsym_months_norm
    f75 = _clip(float(rng.random() < (0.2 + resilience * 0.55)))  # itr_filed
    f76 = _clip(resilience * 0.7 * f75 + _norm(rng, 0, 0.04))     # itr_years_filed_norm
    f77 = _clip(float(work_type in ("vendor", "freelancer")) * float(rng.random() < (0.1 + resilience * 0.4)))  # gst_registered

    # ─────────────────────────────────────────────────────────────────────
    # P7 — Social Accountability (f_78 … f_94)
    # ─────────────────────────────────────────────────────────────────────
    f78 = _clip(social_score * 0.7 + _norm(rng, 0, 0.07))  # gov_scheme_count_norm
    f79 = _clip(float(rng.random() < (0.05 + social_score * 0.35)))  # mudra_registered
    f80 = _clip(float(rng.random() < (0.05 + social_score * 0.25)))  # shg_member
    f81 = _clip(float(rng.random() < (0.05 + social_score * 0.25)))  # ppf_holder
    f82 = _clip(float(rng.random() < (0.05 + social_score * 0.30)))  # nps_subscriber
    f83 = _clip(float(rng.random() < (0.1  + social_score * 0.35)))  # atal_pension_member
    f84 = _clip(social_score * 0.5 + _norm(rng, 0, 0.08))   # employer_reference_count
    f85 = _clip(0.3 + social_score * 0.3 + _norm(rng, 0, 0.07))  # dependents_norm
    f86 = _clip(float(rng.random() < (0.1 + social_score * 0.4)))    # community_participation
    f87 = _clip(social_score * 0.5 + 0.2 + _norm(rng, 0, 0.07))     # years_in_city_norm
    f88 = _clip(float(rng.random() < (0.3 + identity_quality * 0.5)))  # address_stability
    f89 = _clip(identity_quality * 0.8 + _norm(rng, 0, 0.06))  # multi_doc_identity_score
    f90 = _clip(f70 * float(rng.random() < 0.9))   # rc_insurance_match
    f91 = _clip(discipline * 0.7 + _norm(rng, 0, 0.07))  # bank_to_utility_match
    f92 = _clip(resilience * 0.6 * f75 + _norm(rng, 0, 0.05))  # tax_filing_consistency
    f93 = _clip(float(rng.random() < (0.05 + resilience * 0.45)))  # voluntary_contribution
    f94 = _clip(
        (income_quality + discipline + identity_quality + resilience) / 4.0
        + _norm(rng, 0, 0.04)
    )  # overall_data_completeness

    # ─────────────────────────────────────────────────────────────────────
    # COMPOSITE TARGET (weighted pillar quality — mirrors meta-learner)
    # ─────────────────────────────────────────────────────────────────────
    p1_q = income_quality
    p2_q = discipline
    p3_q = 1.0 - debt_load          # lower debt → better
    p4_q = savings_habit
    p5_q = identity_quality
    p6_q = resilience
    p7_q = social_score

    target = (
        0.22 * p1_q +
        0.20 * p2_q +
        0.16 * p3_q +
        0.14 * p4_q +
        0.10 * p5_q +
        0.10 * p6_q +
        0.08 * p7_q
    )
    target = _clip(target + _norm(rng, 0, 0.02))

    return {
        "f_0": f0,   "f_1": f1,   "f_2": f2,   "f_3": f3,   "f_4": f4,
        "f_5": f5,   "f_6": f6,   "f_7": f7,   "f_8": f8,   "f_9": f9,
        "f_10": f10, "f_11": f11, "f_12": f12,
        "f_13": f13, "f_14": f14, "f_15": f15, "f_16": f16, "f_17": f17,
        "f_18": f18, "f_19": f19, "f_20": f20, "f_21": f21, "f_22": f22,
        "f_23": f23, "f_24": f24, "f_25": f25, "f_26": f26, "f_27": f27,
        "f_28": f28, "f_29": f29, "f_30": f30, "f_31": f31, "f_32": f32,
        "f_33": f33, "f_34": f34, "f_35": f35, "f_36": f36,
        "f_37": f37, "f_38": f38, "f_39": f39, "f_40": f40, "f_41": f41,
        "f_42": f42, "f_43": f43, "f_44": f44, "f_45": f45, "f_46": f46,
        "f_47": f47, "f_48": f48,
        "f_49": f49, "f_50": f50, "f_51": f51, "f_52": f52, "f_53": f53,
        "f_54": f54, "f_55": f55, "f_56": f56, "f_57": f57, "f_58": f58,
        "f_59": f59, "f_60": f60, "f_61": f61, "f_62": f62, "f_63": f63,
        "f_64": f64, "f_65": f65, "f_66": f66,
        "f_67": f67, "f_68": f68, "f_69": f69, "f_70": f70, "f_71": f71,
        "f_72": f72, "f_73": f73, "f_74": f74, "f_75": f75, "f_76": f76,
        "f_77": f77,
        "f_78": f78, "f_79": f79, "f_80": f80, "f_81": f81, "f_82": f82,
        "f_83": f83, "f_84": f84, "f_85": f85, "f_86": f86, "f_87": f87,
        "f_88": f88, "f_89": f89, "f_90": f90, "f_91": f91, "f_92": f92,
        "f_93": f93, "f_94": f94,
        "work_type": work_type,
        "target": target,
    }


def generate_profiles(n: int = 10_000, seed: int = 42) -> pd.DataFrame:
    """Generate n synthetic gig worker profiles."""
    rng = np.random.default_rng(seed)
    work_types = rng.choice(_WORK_TYPES, size=n)
    rows = [generate_one_profile(rng, wt) for wt in work_types]
    df = pd.DataFrame(rows)
    # Ensure correct column order: f_0..f_94, work_type, target
    feat_cols = [f"f_{i}" for i in range(95)]
    return df[feat_cols + ["work_type", "target"]].astype(
        {c: "float32" for c in feat_cols + ["target"]}
    )


def main() -> None:
    out = Path("ml_pipeline/data/generated")
    out.mkdir(parents=True, exist_ok=True)

    print("Generating 10,000 synthetic profiles ...")
    df = generate_profiles(n=10_000, seed=42)

    csv_path = out / "synthetic_profiles.csv"
    df.to_csv(csv_path, index=False)

    meta = {
        "rows": int(df.shape[0]),
        "cols": int(df.shape[1]),
        "feature_count": 95,
        "work_type_distribution": df["work_type"].value_counts().to_dict(),
        "target_mean": round(float(df["target"].mean()), 4),
        "target_std":  round(float(df["target"].std()),  4),
        "target_min":  round(float(df["target"].min()),  4),
        "target_max":  round(float(df["target"].max()),  4),
    }
    (out / "metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"Dataset saved  -> {csv_path}")
    print(f"Metadata       -> {out / 'metadata.json'}")
    print(f"Target  mean={meta['target_mean']}  std={meta['target_std']}")


if __name__ == "__main__":
    main()
