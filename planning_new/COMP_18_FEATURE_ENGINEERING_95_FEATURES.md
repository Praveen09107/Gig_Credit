# ================================================================================
# GIGCREDIT — COMPONENT: FEATURE ENGINEERING (95 FEATURES)
# Document 18 | planning_new
# Owner: Dev B | Reference: Feature engineering (1).txt
# ================================================================================

## 1. OVERVIEW

The feature engineering engine converts a VerifiedProfile into a 95-element
Float32 vector, normalized to [0.0, 1.0]. This vector is the INPUT to the
7 pillar scoring models.

---

## 2. COMPLETE FEATURE MAP

### P1 — Income Stability (Features 0–12)

| # | Feature Name               | Formula                                    | Source     |
|---|---------------------------|--------------------------------------------|------------|
| 0 | income_to_anchor_ratio    | avg_monthly_credit / state_median_income   | Step 3     |
| 1 | income_stability_cv       | 1 - (stddev(credits) / mean(credits))      | Step 3     |
| 2 | income_growth_trend       | linear_regression_slope(credits) norm      | Step 3     |
| 3 | income_seasonality        | 1 - (max_credit - min_credit) / max_credit | Step 3     |
| 4 | months_with_income        | count(months with credit > 0) / 6          | Step 3     |
| 5 | self_declared_vs_actual   | declared_income / actual_avg_credit        | Step 1,3   |
| 6 | secondary_income_present  | 1.0 if secondary bank or UPI income else 0 | Step 3     |
| 7 | platform_earnings_match   | earnings_screenshot_total / bank_credits   | Step 5,3   |
| 8 | years_in_profession_norm  | min(years, 20) / 20                        | Step 1     |
| 9 | income_diversification    | unique_credit_sources / 5                  | Step 3     |
| 10| credit_to_debit_ratio     | total_credits / total_debits               | Step 3     |
| 11| avg_balance_to_income     | avg_balance / avg_credit                   | Step 3     |
| 12| work_type_income_factor   | type_specific_adjustment (0.4-0.8)         | Step 1     |

### P2 — Payment Discipline (Features 13–27)

| # | Feature Name               | Formula                                    | Source     |
|---|---------------------------|--------------------------------------------|------------|
| 13| electricity_on_time_ratio | on_time_count / total_bills                | Step 4     |
| 14| lpg_on_time_ratio         | on_time_count / total_bills                | Step 4     |
| 15| mobile_on_time_ratio      | on_time_count / total_bills                | Step 4     |
| 16| combined_bill_score       | weighted avg of above three                | Step 4     |
| 17| emi_on_time_ratio         | on_time_emi / total_emi_months             | Step 3,9   |
| 18| emi_debit_regularity      | stddev(emi_date_of_month) / 30 inverted    | Step 3     |
| 19| utility_vs_bank_match     | matched_utility_debits / total_bills       | Step 3,4   |
| 20| bounce_count_norm         | 1 - (bounce_count / total_months)          | Step 3     |
| 21| payment_consistency_score | combined metric across all bill types       | Step 4     |
| 22| rent_payment_regularity   | 1.0 if regular rent debit else 0.5         | Step 4     |
| 23| wifi_payment_regularity   | on_time_count / total or 0.5 if N/A        | Step 4     |
| 24| ott_payment_regularity    | on_time_count / total or 0.5 if N/A        | Step 4     |
| 25| lowest_bill_score         | min(elec, lpg, mobile on-time ratios)      | Step 4     |
| 26| bill_amount_stability     | 1 - cv(bill amounts)                       | Step 4     |
| 27| early_payment_frequency   | early_pays / total_pays                    | Step 3,4   |

### P3 — Debt Management (Features 28–36)

| # | Feature Name               | Formula                                    | Source     |
|---|---------------------------|--------------------------------------------|------------|
| 28| emi_to_income_ratio       | total_emi / avg_monthly_income             | Step 3,9   |
| 29| active_loan_count_norm    | min(loan_count, 5) / 5                     | Step 3,9   |
| 30| loan_vs_declared_match    | auto_detected_match / declared_count       | Step 3,9   |
| 31| remaining_tenure_norm     | avg_remaining_months / 60                  | Step 9     |
| 32| emi_deduction_consistency | 1 - stddev(emi_amounts) / mean             | Step 3     |
| 33| debt_free_flag            | 1.0 if no active loans else 0.0            | Step 9     |
| 34| emi_coverage_ratio        | (income - total_emi) / income              | Step 3,9   |
| 35| multiple_lender_flag      | 1.0 if >2 unique lenders else 0.5          | Step 9     |
| 36| loan_type_risk            | personal=0.3, business=0.5, two-wheeler=0.7| Step 9     |

### P4 — Savings Behaviour (Features 37–48)

| # | Feature Name               | Formula                                    | Source     |
|---|---------------------------|--------------------------------------------|------------|
| 37| avg_balance_normalized    | avg_balance / (state_median_income * 3)    | Step 3     |
| 38| min_balance_normalized    | min_balance / avg_balance                  | Step 3     |
| 39| balance_trend             | linear_regression(monthly_closing_balance) | Step 3     |
| 40| savings_rate              | (credits - debits) / credits               | Step 3     |
| 41| balance_volatility        | 1 - stddev(balances) / mean(balances)      | Step 3     |
| 42| sip_rd_detected           | 1.0 if recurring debit like SIP/RD else 0  | Step 3     |
| 43| fd_detected               | 1.0 if FD credit/debit pattern else 0      | Step 3     |
| 44| emergency_buffer_months   | min_balance / avg_monthly_debit            | Step 3     |
| 45| peak_spend_month_ratio    | max_monthly_debit / avg_monthly_debit      | Step 3     |
| 46| atm_withdrawal_ratio      | atm_debits / total_debits                  | Step 3     |
| 47| low_balance_day_count     | days_below_2000 / total_days               | Step 3     |
| 48| end_of_month_balance      | avg(last_5_day_balance per month)           | Step 3     |

### P5 — Work and Identity (Features 49–66)

| # | Feature Name               | Formula                                    | Source     |
|---|---------------------------|--------------------------------------------|------------|
| 49| aadhaar_verified          | 1.0 or 0.0                                | Step 2     |
| 50| pan_verified              | 1.0 or 0.0                                | Step 2     |
| 51| face_match_score          | similarity score 0.0-1.0                  | Step 2     |
| 52| name_consistency_score    | avg fuzzy(aadhaar,pan,bank names)          | Step 2,3   |
| 53| dob_consistency           | 1.0 if all DOBs match else 0.0            | Step 2     |
| 54| address_consistency       | fuzzy(aadhaar,utility addresses)           | Step 2,4   |
| 55| work_type_encoded         | platform=0.7, vendor=0.6, trade=0.7, free=0.8 | Step 1  |
| 56| years_experience_norm     | min(years, 20) / 20                        | Step 1     |
| 57| vehicle_ownership         | 1.0 or 0.0                                | Step 1     |
| 58| rc_verified               | 1.0 or 0.0 (platform only)                | Step 5     |
| 59| dl_verified               | 1.0 or 0.0 (platform only)                | Step 5     |
| 60| dl_class_match_rc         | 1.0 if DL class covers RC class           | Step 5     |
| 61| platform_earnings_present | 1.0 if >= 1 screenshot uploaded            | Step 5     |
| 62| trade_licence_active      | 1.0 or 0.0                                | Step 5     |
| 63| svanidhi_registered       | 1.0 or 0.0 (vendor only)                  | Step 5     |
| 64| freelance_profile_active  | 1.0 or 0.0 (freelancer only)              | Step 5     |
| 65| skill_certificate_present | 1.0 or 0.0 (tradesperson only)             | Step 5     |
| 66| work_proof_count_norm     | documents_uploaded / max_expected          | Step 5     |

### P6 — Financial Resilience (Features 67–77)

| # | Feature Name               | Formula                                    | Source     |
|---|---------------------------|--------------------------------------------|------------|
| 67| health_insurance_active   | 1.0 or 0.0                                | Step 7     |
| 68| health_sum_insured_norm   | sum / 1000000 clamped                      | Step 7     |
| 69| life_insurance_active     | 1.0 or 0.0                                | Step 7     |
| 70| vehicle_insurance_active  | 1.0 or 0.0                                | Step 7     |
| 71| insurance_count_norm      | active_policies / 3                        | Step 7     |
| 72| eshram_registered         | 1.0 or 0.0                                | Step 6     |
| 73| pmsym_active              | 1.0 or 0.0                                | Step 6     |
| 74| pmsym_months_norm         | months / 24                                | Step 6     |
| 75| itr_filed                 | 1.0 or 0.0                                | Step 8     |
| 76| itr_years_filed_norm      | years_count / 3                            | Step 8     |
| 77| gst_registered            | 1.0 or 0.0                                | Step 8     |

### P7 — Social Accountability (Features 78–94)

| # | Feature Name               | Formula                                    | Source     |
|---|---------------------------|--------------------------------------------|------------|
| 78| gov_scheme_count_norm     | schemes_registered / 5                     | Step 6     |
| 79| mudra_registered          | 1.0 or 0.0                                | Step 6     |
| 80| shg_member                | 1.0 or 0.0                                | Step 6     |
| 81| ppf_holder                | 1.0 or 0.0                                | Step 6     |
| 82| nps_subscriber            | 1.0 or 0.0                                | Step 6     |
| 83| atal_pension_member       | 1.0 or 0.0                                | Step 6     |
| 84| employer_reference_count  | count / 3                                  | Step 5     |
| 85| dependents_norm           | min(dependents, 5) / 5                     | Step 1     |
| 86| community_participation   | member of cooperative/association          | Step 6     |
| 87| years_in_city_norm        | min(years, 10) / 10                        | Step 1     |
| 88| address_stability         | 1.0 if same address >= 2 years             | Step 2     |
| 89| multi_doc_identity_score  | avg(all cross-doc match scores)            | Step 2-9   |
| 90| rc_insurance_match        | 1.0 if vehicle insured matches RC          | Step 5,7   |
| 91| bank_to_utility_match     | utility payments found in bank debits      | Step 3,4   |
| 92| tax_filing_consistency    | filed_years / max_expected_years           | Step 8     |
| 93| voluntary_contribution    | 1.0 if PPF/NPS/PMSYM voluntary            | Step 6     |
| 94| overall_data_completeness | filled_fields / total_possible_fields      | All steps  |

---

## 3. NORMALIZATION RULES

All features must be in [0.0, 1.0]:
- Ratio features: already 0-1 by definition
- Count features: divide by reasonable maximum, then clamp
- Boolean features: 0.0 or 1.0
- Encoded features: pre-defined mapping values
- Missing/NaN: replace with pillar-specific fallback (0.40 default)

---

## 4. DEMO FEATURE VECTOR

For the demo user (Ravi Kumar, Platform Worker), the expected feature vector
should produce a score around 650-720 (Grade B). Dev A should generate this
and store in `demo_data/expected_outputs/demo_feature_vector.json`.
