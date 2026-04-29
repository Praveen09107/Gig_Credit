# V3.0 Dev A — Synthetic Data Generator Spec (CORRECTED)

## File: `ml_pipeline/generation/synthetic_data_generator.py`

## Output
- `data/generated/synthetic_profiles.csv` — **15K × 117 columns** (115 features + `target` + `work_type`)

## Work Type Distribution
| Work Type | Count | % | Income CV Median | Key Traits |
|-----------|-------|---|-----------------|------------|
| platform_worker | 4,500 | 30% | 0.28 | Daily deposits, stable, multi-platform |
| street_vendor | 4,500 | 30% | 0.44 | Cash-heavy, seasonal, location-bound |
| skilled_tradesperson | 3,000 | 20% | 0.39 | Project-based, moderate variance |
| freelancer | 3,000 | 20% | 0.61 | High variance, project spikes, digital |

---

## STAGE 0: Generate 95 Base Features Per Work Type

### P1 Income (f0-f12) — Work-Type-Aware Distributions

**Platform Worker**:
```python
f[0] = np.random.beta(3.0, 2.5)        # avg_income — higher for platform
f[1] = np.random.beta(4.0, 2.0)        # income_cv — TIGHT (stable daily deposits)
f[2] = np.random.normal(0.50, 0.12)    # income_growth — moderate
f[3] = np.random.beta(5.0, 1.5)        # active_months — high (daily work)
f[4] = np.random.beta(4.0, 1.5)        # platform_verified — high
f[5] = np.random.beta(3.5, 2.0)        # bank_deposit_match — good match
```

**Street Vendor**:
```python
f[0] = np.random.beta(2.0, 3.0)        # avg_income — lower
f[1] = np.random.beta(2.5, 3.0)        # income_cv — WIDE (seasonal, cash)
f[2] = np.random.normal(0.40, 0.15)    # income_growth — slower
f[3] = np.random.beta(3.0, 2.5)        # active_months — moderate
f[4] = np.random.beta(1.5, 4.0)        # platform_verified — low (mostly offline)
```

**Freelancer**:
```python
f[0] = np.random.beta(2.5, 2.0)        # avg_income — variable but higher peaks
f[1] = np.random.beta(1.8, 2.5)        # income_cv — VERY WIDE (project-based)
f[2] = np.random.normal(0.55, 0.18)    # income_growth — can be high
f[4] = np.random.beta(2.0, 3.0)        # platform_verified — moderate
```

**Skilled Tradesperson**:
```python
f[0] = np.random.beta(2.8, 2.5)        # avg_income — moderate-high
f[1] = np.random.beta(3.0, 2.5)        # income_cv — moderate
f[2] = np.random.normal(0.45, 0.14)    # income_growth — steady
```

### P2 Payment (f13-f27) — Correlated Cluster
```python
# Base payment quality (latent variable drives all P2 features)
payment_quality = np.random.beta(3.0, 1.5)
f[13] = payment_quality * np.random.beta(4, 1.5)  # utility_ontime — correlated
f[14] = payment_quality * np.random.beta(3, 2)     # emi_ontime — correlated
f[15] = 1 - np.random.exponential(0.15).clip(0, 1) # bounce — rare events
# F-P2-03, F-P2-04 (UPI features): bimodal
# Platform workers → UPI active (0.7-1.0), vendors → UPI inactive (fallback 0.40)
f[16] = 0.40 if work_type == 'street_vendor' else np.random.beta(3, 1.5)
f[22] = 1.0 if np.random.random() < 0.15 else 0.0  # loan_prepayment — binary rare
```

### P3 Debt (f28-f36) — Dominated by EMI Ratio
```python
f[28] = 1 - np.random.beta(1.5, 4)     # emi_to_income — inverted, most have low EMI
f[29] = 1 - np.random.poisson(1.2) / 5  # debt_count — few loans
f[30] = np.random.beta(3, 2)            # dscr — correlated with f[28]
# Critical: f[28] drives 60-70% of P3 score, must have realistic thresholds at 0.30/0.45/0.60
```

### P4 Savings (f37-f48) — Correlated with Income
```python
# Savings CONDITIONAL on income (savings rate matters more at low income)
income_level = f[0]  # from P1
f[37] = np.random.beta(2, 4) * (0.5 + income_level * 0.5)  # savings_rate × income
f[38] = np.random.beta(2, 3)            # month_end_balance
f[39] = np.random.beta(1.5, 4)          # emergency_fund — rare for gig workers
# PPF/SIP features: work-type conditional
f[43] = 1.0 if (work_type == 'freelancer' and np.random.random() < 0.25) else 0.0
```

### P5 Work & Identity (f49-f66) — Binary-Heavy
```python
f[49] = 1.0 if np.random.random() < 0.90 else 0.0  # aadhaar — 90%
f[50] = 1.0 if np.random.random() < 0.85 else 0.0  # pan — 85%
f[51] = 1.0 if np.random.random() < 0.70 else 0.0  # work_proof
f[53] = 1.0 if np.random.random() < 0.35 else 0.0  # eshram — 35%
# Platform-specific: customer_rating only meaningful for platform workers
f[54] = np.random.beta(4, 1.5) if work_type == 'platform_worker' else 0.50
```

### P6 Resilience (f67-f77) — Binary Flags, Clustered
```python
# Insurance cluster: having one → more likely to have others
has_any_insurance = np.random.random() < 0.45
f[67] = 1.0 if (has_any_insurance and np.random.random() < 0.70) else 0.0  # health
f[68] = 1.0 if (has_any_insurance and np.random.random() < 0.40) else 0.0  # life
f[70] = 1.0 if (work_type in ['platform_worker','street_vendor'] and np.random.random() < 0.30) else 0.0  # vehicle — work-type conditional
# F-P6-10 (premium_to_income): NON-MONOTONIC — sweet spot at 1-8%
f[76] = np.random.beta(2, 5) if has_any_insurance else 0.0
```

### P7 Social (f78-f87)
```python
f[78] = np.random.beta(1.5, 3)          # community_standing
f[79] = 1.0 if np.random.random() < 0.20 else 0.0  # group_lending
f[86] = np.random.beta(2, 2)            # years_at_address
```

### P8 Tax (f88-f94)
```python
# Tax filing cluster: ITR → more likely GST
has_itr = np.random.random() < 0.30
f[88] = 1.0 if has_itr else 0.0          # itr_filed
f[89] = np.random.beta(1.5, 4) if has_itr else 0.0  # itr_years
f[90] = 1.0 if (has_itr and np.random.random() < 0.40) else 0.0  # gst
f[91] = 1.0 if (f[50] > 0.5 and np.random.random() < 0.60) else 0.0  # pan_linked_bank
```

---

## STAGE 1: Work-Type Normalisation (5 features)

```python
medians = compute_work_type_medians(df)  # from generated data
for idx, row in df.iterrows():
    wt = row['work_type']
    df.at[idx, 'f1'] = row['f1'] / medians[wt]['income_cv']
    df.at[idx, 'f2'] = row['f2'] / medians[wt]['income_growth_norm']
    df.at[idx, 'f4'] = row['f4'] / medians[wt]['gig_share_norm']
    df.at[idx, 'f28'] = row['f28'] / medians[wt]['payment_gap_freq']
    df.at[idx, 'f47'] = row['f47'] / medians[wt]['balance_variability']
# Re-clip to [0, 1] after normalisation
```

Also save: `output/assets/work_type_medians.json`

---

## STAGE 2: Cross-Pillar Features (f95-f114)

```python
# Group A: Income × Debt (4 features)
df['f95'] = df['f28'] * (1 - df['f1'])            # income_debt_stress
df['f96'] = (1 - df['f1']) * df['f29']             # debt_vulnerability
df['f97'] = (df['f0'] - df['f28']).clip(0, 1)      # income_emi_coverage
df['f98'] = df['f2'] * (1 - df['f31'])             # income_trend_vs_debt

# Group B: Payment × Savings (3 features)
df['f99'] = (df['f13'] - df['f37']).clip(0, 1)     # payment_savings_alignment
df['f100'] = df['f39'] * df['f13']                  # buffer_payment_composite
df['f101'] = df['f23'] * df['f43']                  # digital_savings_discipline

# Group C: Resilience Composite (3 features)
df['f102'] = df['f67']*0.35 + df['f39']*0.40 + (1-df['f28'])*0.25
df['f103'] = (df['f102'] - df['f28']).clip(0, 1)
df['f104'] = (df['f67'] + df['f68']) * df['f1']

# Group D: Gig Stability Streaks (4 features)
df['f105'] = np.minimum(df['f3'], df['f13'])
df['f106'] = df['f2'] * df['f15']
df['f107'] = df['f5'] * df['f23']
df['f108'] = df['f10'] * df['f13']

# Group E: Formal Recognition (3 features)
df['f109'] = (df['f79'] + df['f69']) * df['f1']
df['f110'] = df['f88'] * df['f5']
df['f111'] = df[['f78','f79','f80','f81','f82','f83','f84','f85','f86','f87']].mean(axis=1) * df['f0']

# Group F: Temporal (3 features — defaults for synthetic)
df['f112'] = np.random.beta(2, 2, size=len(df))   # seasonal_income_volatility
df['f113'] = np.random.beta(3, 2, size=len(df))   # payment_regularity_entropy
df['f114'] = np.random.beta(2, 3, size=len(df))   # balance_recovery_speed
```

---

## Target Score Generation

```python
# Compute pillar scores using the ACTUAL models we will train
# (bootstrap: use weighted averages as initial target)
p1_proxy = 0.22 * df[P1_COLS].mean(axis=1)
p2_proxy = 0.18 * df[P2_COLS].mean(axis=1)
p3_proxy = 0.12 * df[P3_COLS].mean(axis=1)
p4_proxy = 0.13 * df[P4_COLS].mean(axis=1)
p5_proxy = 0.10 * scorecard_P5(df)
p6_proxy = 0.10 * df[P6_COLS].mean(axis=1)
p7_proxy = 0.08 * scorecard_P7(df)
p8_proxy = 0.07 * scorecard_P8(df)

target = (p1_proxy + p2_proxy + p3_proxy + p4_proxy +
          p5_proxy + p6_proxy + p7_proxy + p8_proxy +
          np.random.normal(0, 0.03, size=len(df))).clip(0, 1)
```

---

## Quality Checks

| Check | Assertion |
|-------|-----------|
| All 115 features in [0, 1] | `assert (df[feature_cols] >= 0).all().all()` |
| No NaN | `assert df.isna().sum().sum() == 0` |
| Target distribution | `mean ≈ 0.45, std ≈ 0.12` |
| Work type counts | `4500, 4500, 3000, 3000` |
| P1 intra-pillar correlation | `r > 0.3 for income features` |
| Insurance clustering | `P(life_ins \| health_ins) > P(life_ins)` |
| Tax clustering | `P(gst \| itr) > P(gst)` |
| Cross-pillar features computed | `f95-f114 all present and valid` |
| Work-type medians exported | `work_type_medians.json exists` |

## Execution
```bash
cd ml_pipeline
python -m generation.synthetic_data_generator
# Output: data/generated/synthetic_profiles.csv (15K × 117)
# Output: output/assets/work_type_medians.json
```
