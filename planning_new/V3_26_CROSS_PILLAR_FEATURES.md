# V3.0 Cross-Pillar Feature Engineering (95 → 115 features)

## Purpose
20 deterministic interaction features computed in Dart BEFORE any model sees the data. These capture cross-pillar relationships the old system completely missed.

## Feature Indices: 95–114

---

## Group A — Income × Debt (P1 × P3): 4 features

| Index | Name | Formula | Interpretation |
|-------|------|---------|---------------|
| 95 | `income_debt_stress_index` | F[28] × (1 - F[1]) | High EMI + unstable income = max stress |
| 96 | `debt_vulnerability_score` | (1 - F[1]) × F[29] | Loan count × income volatility |
| 97 | `income_emi_coverage` | F[0] - F[28] | Income headroom after EMI. Negative = danger |
| 98 | `income_trend_vs_debt_trend` | F[2] × (1 - F[31]) | Income growing while debt also growing? |

---

## Group B — Payment × Savings (P2 × P4): 3 features

| Index | Name | Formula | Interpretation |
|-------|------|---------|---------------|
| 99 | `payment_savings_alignment` | F[13] - F[37] | Pays others on time but doesn't save? |
| 100 | `buffer_payment_composite` | F[39] × F[13] | Emergency buffer AND consistent payment |
| 101 | `digital_savings_discipline` | F[23] × F[43] | Digital payments + formal savings (SIP/RD) |

---

## Group C — Resilience Composite (P6 × P3 × P4): 3 features

| Index | Name | Formula | Interpretation |
|-------|------|---------|---------------|
| 102 | `financial_shock_resistance` | F[67]×0.35 + F[39]×0.40 + (1-F[28])×0.25 | Insurance + buffer + low debt |
| 103 | `resilience_debt_mismatch` | f[102] - F[28] | Does resilience justify debt load? |
| 104 | `insurance_income_anchor` | (F[67] + F[68]) × F[1] | Insurance weighted by income stability |

---

## Group D — Gig Stability Streaks (P1 × P2): 4 features

| Index | Name | Formula | Interpretation |
|-------|------|---------|---------------|
| 105 | `consistent_earning_payment_streak` | min(F[3], F[13]) | Earning AND paying simultaneously |
| 106 | `income_payment_trend_alignment` | F[2] × F[15] | Income up AND no bounces |
| 107 | `platform_payment_reliability` | F[5] × F[23] | Platform income in bank AND digital payments |
| 108 | `income_floor_payment_consistency` | F[10] × F[13] | Even worst month → still paid bills |

---

## Group E — Formal Recognition (P7 × P1, P8 × P1): 3 features

| Index | Name | Formula | Interpretation |
|-------|------|---------|---------------|
| 109 | `formal_recognition_income_alignment` | (F[79] + F[69]) × F[1] | e-Shram + PM-SYM weighted by stability |
| 110 | `tax_income_consistency_ratio` | F[88] × F[5] | ITR filed AND income matches bank |
| 111 | `scheme_income_combined` | mean(F[78:88]) × F[0] | Scheme participation × income level |

---

## Group F — Temporal Patterns: 3 features

| Index | Name | Formula | Interpretation |
|-------|------|---------|---------------|
| 112 | `seasonal_income_volatility` | Computed from bank OCR data | Festival vs off-season income ratio |
| 113 | `payment_regularity_entropy` | Shannon entropy of payment days | Low = regular, high = erratic |
| 114 | `balance_recovery_speed` | Rate of balance return after lowest month | Fast recovery = strong buffering |

> Group F features require time-series data. Default to 0.50 if not available.

---

## Which Pillar Gets Which Cross-Pillar Features

| Pillar | Base Features | Cross-Pillar Indices | Total |
|--------|--------------|---------------------|-------|
| P1 (LightGBM) | 0–12 (13) | 95,96,97,98 (Group A) | 17 |
| P2 (XGBoost) | 13–27 (15) | 105,106,107,108 (Group D) | 19 |
| P3 (XGBoost shallow) | 28–36 (9) | 95,96,97,98 (Group A) | 13 |
| P4 (LightGBM) | 37–48 (12) | 99,100,101,102 (Group B+C) | 16 |
| P6 (ExtraTrees) | 67–77 (11) | 102,103,104 (Group C) | 14 |

---

## Dev B Implementation in `feature_engineer.dart`

```dart
// After computing 95 base features...
// ── Cross-Pillar Features (f95..f114) ──────────────

// Group A: Income × Debt
features[95] = features[28] * (1.0 - features[1]);       // income_debt_stress
features[96] = (1.0 - features[1]) * features[29];       // debt_vulnerability
features[97] = (features[0] - features[28]).clamp(0.0, 1.0); // income_emi_coverage
features[98] = features[2] * (1.0 - features[31]);       // income_trend_vs_debt

// Group B: Payment × Savings
features[99] = (features[13] - features[37]).clamp(0.0, 1.0);  // payment_savings_alignment
features[100] = features[39] * features[13];              // buffer_payment_composite
features[101] = features[23] * features[43];              // digital_savings_discipline

// Group C: Resilience Composite
features[102] = features[67]*0.35 + features[39]*0.40 + (1-features[28])*0.25;
features[103] = (features[102] - features[28]).clamp(0.0, 1.0);
features[104] = (features[67] + features[68]) * features[1];

// Group D: Gig Stability Streaks
features[105] = min(features[3], features[13]);
features[106] = features[2] * features[15];
features[107] = features[5] * features[23];
features[108] = features[10] * features[13];

// Group E: Formal Recognition
features[109] = (features[79] + features[69]) * features[1];
features[110] = features[88] * features[5];
features[111] = _pillarMean(features, 78, 88) * features[0];

// Group F: Temporal (default 0.5 if no time-series data)
features[112] = 0.50;  // seasonal_income_volatility
features[113] = 0.50;  // payment_regularity_entropy
features[114] = 0.50;  // balance_recovery_speed
```
