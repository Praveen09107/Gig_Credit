# V3.0 Feature Vector Contract (CORRECTED — 115 Features)

## Total: 115 features (95 base + 20 cross-pillar)

---

## P1 — Income Stability (f0–f12, 13 features) → LightGBM

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 0 | avg_monthly_income_norm | continuous | [0,1] | Bank OCR |
| 1 | income_stability_cv | continuous | [0,1] | Bank OCR → **work-type normalised** |
| 2 | income_growth_slope | continuous | [0,1] | Bank OCR → **work-type normalised** |
| 3 | active_earning_months | continuous | [0,1] | Bank OCR |
| 4 | income_platform_verified_ratio | continuous | [0,1] | Bank+Platform → **work-type normalised** |
| 5 | bank_deposit_match_ratio | continuous | [0,1] | Bank+Platform |
| 6 | balance_consistency | continuous | [0,1] | Bank OCR |
| 7 | recency_weight | continuous | [0,1] | Bank OCR |
| 8 | growth_strength | continuous | [0,1] | Bank OCR |
| 9 | income_anchor_ratio | continuous | [0,1] | Bank OCR |
| 10 | earning_month_ratio | continuous | [0,1] | Bank OCR |
| 11 | gig_income_share | continuous | [0,1] | Self-declared |
| 12 | income_persistence | continuous | [0,1] | Bank OCR |

## P2 — Payment Discipline (f13–f27, 15 features) → XGBoost

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 13 | utility_ontime_ratio | continuous | [0,1] | Bill OCR |
| 14 | emi_ontime_ratio | continuous | [0,1] | Credit bureau |
| 15 | bounce_rate_inverse | continuous | [0,1] | Bank statement |
| 16 | upi_transaction_consistency | continuous | [0,1] | UPI data |
| 17 | upi_active_months | continuous | [0,1] | UPI data |
| 18 | rent_ontime_ratio | continuous | [0,1] | Landlord proof |
| 19 | autopay_count_norm | continuous | [0,1] | Bank statement |
| 20 | payment_recency_score | continuous | [0,1] | All sources |
| 21 | payment_streak | continuous | [0,1] | All sources |
| 22 | loan_prepayment_flag | binary | {0,1} | Credit bureau |
| 23 | digital_payment_ratio | continuous | [0,1] | UPI+bank |
| 24 | payment_diversity | continuous | [0,1] | All sources |
| 25 | bill_coverage_ratio | continuous | [0,1] | Bill OCR |
| 26 | payment_variance | continuous | [0,1] | All sources |
| 27 | payment_trend_slope | continuous | [0,1] | All sources |

## P3 — Debt Management (f28–f36, 9 features) → XGBoost Shallow (depth=2)

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 28 | emi_to_income_ratio_inv | continuous | [0,1] | Bank+credit → **work-type normalised** |
| 29 | debt_count_norm_inv | continuous | [0,1] | Credit bureau |
| 30 | dscr_normalised | continuous | [0,1] | Computed |
| 31 | debt_growth_inv | continuous | [0,1] | Credit bureau |
| 32 | secured_debt_ratio | continuous | [0,1] | Credit bureau |
| 33 | utilisation_ratio_inv | continuous | [0,1] | Credit bureau |
| 34 | debt_age_score | continuous | [0,1] | Credit bureau |
| 35 | repayment_velocity | continuous | [0,1] | Credit bureau |
| 36 | debt_diversification | continuous | [0,1] | Credit bureau |

## P4 — Savings Behaviour (f37–f48, 12 features) → LightGBM

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 37 | savings_rate | continuous | [0,1] | Bank OCR |
| 38 | month_end_balance_norm | continuous | [0,1] | Bank OCR |
| 39 | emergency_fund_ratio | continuous | [0,1] | Bank OCR |
| 40 | savings_growth_slope | continuous | [0,1] | Bank OCR |
| 41 | fixed_deposit_flag | binary | {0,1} | Bank OCR |
| 42 | ppf_balance_norm | continuous | [0,1] | PPF passbook |
| 43 | sip_rd_active | binary | {0,1} | Bank statement |
| 44 | auto_savings_ratio | continuous | [0,1] | Bank statement |
| 45 | savings_consistency | continuous | [0,1] | Bank OCR |
| 46 | net_savings_trend | continuous | [0,1] | Bank OCR |
| 47 | balance_variability_inv | continuous | [0,1] | Bank OCR → **work-type normalised** |
| 48 | min_balance_maintained | continuous | [0,1] | Bank OCR |

## P5 — Work & Identity (f49–f66, 18 features) → Scorecard

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 49 | aadhaar_verified | binary | {0,1} | DigiLocker | **KYC GATE** |
| 50 | pan_verified | binary | {0,1} | DigiLocker | **KYC GATE** |
| 51 | work_proof_verified | binary | {0,1} | Work documents |
| 52 | voter_id_verified | binary | {0,1} | DigiLocker |
| 53 | eshram_enrolled | binary | {0,1} | e-Shram portal |
| 54 | customer_rating_norm | continuous | [0,1] | Platform API |
| 55 | experience_years_norm | continuous | [0,1] | Self-declared |
| 56 | platform_count_norm | continuous | [0,1] | Platform APIs |
| 57 | work_address_match | binary | {0,1} | Address proof |
| 58 | license_verified | binary | {0,1} | License OCR |
| 59 | skill_certification | binary | {0,1} | Certificate |
| 60 | work_type_stability | continuous | [0,1] | Work history |
| 61 | employer_reference | binary | {0,1} | Reference |
| 62 | multi_skill_flag | binary | {0,1} | Self-declared |
| 63 | digital_presence_score | continuous | [0,1] | Online profiles |
| 64 | bank_linked_to_work | binary | {0,1} | Bank+platform |
| 65 | mobile_linked_aadhaar | binary | {0,1} | e-KYC |
| 66 | work_location_stability | continuous | [0,1] | GPS/address |

## P6 — Financial Resilience (f67–f77, 11 features) → ExtraTrees

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 67 | health_insurance_active | binary | {0,1} | Insurance doc |
| 68 | life_insurance_active | binary | {0,1} | Insurance doc |
| 69 | pm_sym_enrolled | binary | {0,1} | PM-SYM portal |
| 70 | vehicle_insurance_active | binary | {0,1} | Insurance doc |
| 71 | accident_coverage | binary | {0,1} | Insurance doc |
| 72 | pm_jjby_enrolled | binary | {0,1} | PM-JJBY portal |
| 73 | pm_sby_enrolled | binary | {0,1} | PM-SBY portal |
| 74 | ayushman_bharat | binary | {0,1} | AB card |
| 75 | emergency_contact_count | continuous | [0,1] | Self-declared |
| 76 | premium_to_income_ratio | continuous | [0,1] | Insurance+bank |
| 77 | dependents_covered_ratio | continuous | [0,1] | Insurance doc |

## P7 — Social Accountability (f78–f87, 10 features) → Scorecard

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 78 | community_standing_score | continuous | [0,1] | References |
| 79 | group_lending_member | binary | {0,1} | SHG records |
| 80 | guarantor_available | binary | {0,1} | Self-declared |
| 81 | neighbourhood_stability | continuous | [0,1] | Address proof |
| 82 | market_association_member | binary | {0,1} | Association |
| 83 | cooperative_member | binary | {0,1} | Cooperative |
| 84 | reference_count_norm | continuous | [0,1] | References |
| 85 | social_media_presence | continuous | [0,1] | Online check |
| 86 | years_at_current_address | continuous | [0,1] | Address proof |
| 87 | family_earning_members | continuous | [0,1] | Self-declared |

## P8 — Tax & Compliance (f88–f94, 7 features) → Scorecard ← **NEW PILLAR**

| Index | Name | Type | Range | Source |
|-------|------|------|-------|--------|
| 88 | itr_filed_this_year | binary | {0,1} | ITR portal |
| 89 | itr_filing_years_norm | continuous | [0,1] | ITR portal |
| 90 | gst_registered | binary | {0,1} | GST portal |
| 91 | pan_linked_bank | binary | {0,1} | Bank+PAN |
| 92 | scheme_registration_count | continuous | [0,1] | Gov portals |
| 93 | udyam_registered | binary | {0,1} | Udyam portal |
| 94 | professional_tax_paid | binary | {0,1} | State portal |

---

## Cross-Pillar Features (f95–f114, 20 features) — Computed in Stage 2

| Index | Name | Group | Formula |
|-------|------|-------|---------|
| 95 | income_debt_stress_index | A | f[28] × (1-f[1]) |
| 96 | debt_vulnerability_score | A | (1-f[1]) × f[29] |
| 97 | income_emi_coverage | A | (f[0]-f[28]).clamp(0,1) |
| 98 | income_trend_vs_debt_trend | A | f[2] × (1-f[31]) |
| 99 | payment_savings_alignment | B | (f[13]-f[37]).clamp(0,1) |
| 100 | buffer_payment_composite | B | f[39] × f[13] |
| 101 | digital_savings_discipline | B | f[23] × f[43] |
| 102 | financial_shock_resistance | C | f[67]×0.35+f[39]×0.40+(1-f[28])×0.25 |
| 103 | resilience_debt_mismatch | C | (f[102]-f[28]).clamp(0,1) |
| 104 | insurance_income_anchor | C | (f[67]+f[68])×f[1] |
| 105 | consistent_earning_payment_streak | D | min(f[3],f[13]) |
| 106 | income_payment_trend_alignment | D | f[2] × f[15] |
| 107 | platform_payment_reliability | D | f[5] × f[23] |
| 108 | income_floor_payment_consistency | D | f[10] × f[13] |
| 109 | formal_recognition_income_alignment | E | (f[79]+f[69])×f[1] |
| 110 | tax_income_consistency_ratio | E | f[88] × f[5] |
| 111 | scheme_income_combined | E | mean(f[78:88])×f[0] |
| 112 | seasonal_income_volatility | F | from bank OCR (default 0.5) |
| 113 | payment_regularity_entropy | F | Shannon entropy (default 0.5) |
| 114 | balance_recovery_speed | F | from bank OCR (default 0.5) |

---

## Feature Routing to Pillars (with cross-pillar features)

| Pillar | Base Indices | Cross-Pillar Indices | Total Input |
|--------|-------------|---------------------|-------------|
| P1 (LightGBM) | 0–12 | 95, 96, 97, 98 | 17 |
| P2 (XGBoost) | 13–27 | 105, 106, 107, 108 | 19 |
| P3 (XGBoost shallow) | 28–36 | 95, 96, 97, 98 | 13 |
| P4 (LightGBM) | 37–48 | 99, 100, 101, 102 | 16 |
| P5 (Scorecard) | 49–66 | — | 18 |
| P6 (ExtraTrees) | 67–77 | 102, 103, 104 | 14 |
| P7 (Scorecard) | 78–87 | — | 10 |
| P8 (Scorecard) | 88–94 | — | 7 |

---

## 5 Work-Type Normalised Features

| Index | Feature | Normalised By |
|-------|---------|--------------|
| 1 | income_stability_cv | `work_type_medians[wt].income_cv` |
| 2 | income_growth_slope | `work_type_medians[wt].income_growth_norm` |
| 4 | income_platform_verified_ratio | `work_type_medians[wt].gig_share_norm` |
| 28 | emi_to_income_ratio_inv | `work_type_medians[wt].payment_gap_freq` |
| 47 | balance_variability_inv | `work_type_medians[wt].balance_variability` |
