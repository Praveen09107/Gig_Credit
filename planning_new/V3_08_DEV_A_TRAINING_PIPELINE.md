# V3.0 Dev A — Training Pipeline Spec (CORRECTED)

## File: `ml_pipeline/training/train_pillars_v3.py`

## Purpose
Train 5 pillar models using **DIFFERENT algorithms per pillar** based on feature characteristics.

## Input
- `data/generated/synthetic_profiles.csv` (15K × 116 cols: 115 features + target)

## Output
- `output/models/p1_lgbm.pkl` (LightGBM)
- `output/models/p2_xgb.pkl` (XGBoost)
- `output/models/p3_xgb_shallow.pkl` (XGBoost shallow)
- `output/models/p4_lgbm.pkl` (LightGBM)
- `output/models/p6_et.pkl` (ExtraTrees)
- `output/models/training_metrics_v3.json`

---

## P1 — Income Stability → LightGBM GBDT

**Why LightGBM**: Gig income follows fat-tailed lognormal distribution. Leaf-wise growth finds asymmetric seasonal patterns faster than level-wise. Selective monotonic constraints needed (F-P1-08 is V-shaped → excluded).

**Features**: 13 base + cross-pillar features routed to P1
**Feature slice**: indices 0–12 + [95,96,97,98] (Group A + Group D cross-pillar)

```python
lgbm_p1 = lgb.LGBMRegressor(
    boosting_type='gbdt',
    num_leaves=31,
    n_estimators=300,
    learning_rate=0.05,
    min_child_samples=20,
    feature_fraction=0.8,
    bagging_fraction=0.8,
    bagging_freq=5,
    monotone_constraints=[1,1,1,1,1,1,1,0,1,0,1,1,1, 0,0,0,0],
    #                                     ^ F-P1-08    ^ cross-pillar (no constraint)
    random_state=42,
    n_jobs=-1,
)
```

> ⚠️ `tree_method` N/A for LightGBM. m2cgen supports LightGBM export natively.

---

## P2 — Payment Discipline → XGBoost GBDT

**Why XGBoost**: Exact split finding for binary payment thresholds (0 bounces vs 1+). `colsample_bytree=0.7` handles 15 correlated payment features. Native missing value routing for absent EMI data.

**Features**: 15 base + cross-pillar features routed to P2
**Feature slice**: indices 13–27 + [102,103,104,105] (Group B + Group D cross-pillar)

```python
xgb_p2 = xgb.XGBRegressor(
    max_depth=4,
    n_estimators=300,
    learning_rate=0.05,
    colsample_bytree=0.7,
    min_child_weight=10,
    reg_lambda=2.0,
    reg_alpha=0.5,
    subsample=0.8,
    tree_method='exact',   # REQUIRED for m2cgen
    monotone_constraints='(1,1,1,-1,1,1,1,1,1,1,1,1,-1,1,1, 0,0,0,0)',
    random_state=42,
    n_jobs=-1,
)
```

---

## P3 — Debt Management → XGBoost GBDT (SHALLOW)

**Why shallow**: F-P3-01 (EMI ratio) carries weight 0.28 — dominates the pillar. All scoring curves pre-stepped. Model's job is optimal weighting, not threshold discovery. Depth-2 is the correct inductive bias.

**Features**: 9 base + cross-pillar features routed to P3
**Feature slice**: indices 28–36 + [95,96,97,98] (Group A cross-pillar)

```python
xgb_p3 = xgb.XGBRegressor(
    max_depth=2,            # ← DELIBERATELY SHALLOW
    n_estimators=80,        # ← fewer trees (simple relationship)
    learning_rate=0.05,
    colsample_bytree=0.8,
    reg_lambda=5.0,         # ← HEAVY regularisation
    reg_alpha=1.0,
    tree_method='exact',
    random_state=42,
    n_jobs=-1,
)
```

---

## P4 — Savings Behaviour → LightGBM GBDT with Interaction Constraints

**Why LightGBM + interactions**: Savings × income interaction is curvilinear (savings rate matters MORE at low income). Leaf-wise growth finds this faster. Interaction constraints enforce domain knowledge.

**Features**: 12 base + cross-pillar features routed to P4
**Feature slice**: indices 37–48 + [99,100,101,106] (Group B + Group C cross-pillar)

```python
lgbm_p4 = lgb.LGBMRegressor(
    boosting_type='gbdt',
    num_leaves=25,
    n_estimators=300,
    learning_rate=0.05,
    feature_fraction=0.7,
    min_child_samples=20,
    interaction_constraints=[[0,1], [4,5], [2,3]],
    # [avg_balance × savings_rate], [slope × zero_penalty], [ppf_active × ppf_tenure]
    random_state=42,
    n_jobs=-1,
)
```

---

## P6 — Financial Resilience → ExtraTreesRegressor

**Why ExtraTrees**: 43% of P6 weight = binary flags. Random threshold selection on binary features (split at 0.5 regardless) creates maximally diverse trees. No bootstrap = full dataset per tree. F-P6-10 is non-monotonic → no constraints needed.

**Features**: 11 base + cross-pillar features routed to P6
**Feature slice**: indices 67–77 + [106,107,108] (Group C cross-pillar)

```python
et_p6 = ExtraTreesRegressor(
    n_estimators=150,
    max_features='sqrt',
    min_samples_leaf=10,    # ← prevents overfitting to rare binary combos
    max_depth=6,
    bootstrap=False,        # ← ExtraTrees uses full dataset (unlike RF)
    random_state=42,
    n_jobs=-1,
)
```

> ⚠️ m2cgen supports sklearn ExtraTreesRegressor export to Dart.

---

## Data Split
```
Total 15K profiles
├── 70% Training (10,500)
├── 20% Validation (3,000) — isotonic calibration
└── 10% Calibration (1,500) — conformal intervals
```

## Metrics to Record
```json
{
  "P1": {"model": "lgbm", "rmse": 0.042, "r2": 0.91, "n_features": 17},
  "P2": {"model": "xgb", "rmse": 0.038, "r2": 0.93, "n_features": 19},
  "P3": {"model": "xgb_shallow", "rmse": 0.055, "r2": 0.85, "n_features": 13},
  "P4": {"model": "lgbm", "rmse": 0.045, "r2": 0.89, "n_features": 16},
  "P6": {"model": "extratrees", "rmse": 0.050, "r2": 0.87, "n_features": 14}
}
```

## Execution
```bash
cd ml_pipeline
python -m training.train_pillars_v3
```
