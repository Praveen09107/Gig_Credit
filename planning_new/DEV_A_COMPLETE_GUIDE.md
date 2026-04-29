# DEV A — COMPLETE IMPLEMENTATION GUIDE (v3.0)

> **Role**: ML Pipeline + Backend API + All Python Code
> **Zero overlap with Dev B** — you never touch Flutter/Dart app code.
> **Reference docs**: V3_07 through V3_16, V3_26-V3_31

---

# TABLE OF CONTENTS

1. [Your Responsibilities](#1-your-responsibilities)
2. [What You Do NOT Touch](#2-what-you-do-not-touch)
3. [Execution Order](#3-execution-order)
4. [Task A1: Config & Constants](#task-a1)
5. [Task A2: Synthetic Data Generator](#task-a2)
6. [Task A3: Train 5 ML Pillar Models](#task-a3)
7. [Task A4: Write 3 Scorecard Files](#task-a4)
8. [Task A5: Calibration & Conformal](#task-a5)
9. [Task A6: Meta-Learner Training](#task-a6)
10. [Task A7: SHAP Extraction](#task-a7)
11. [Task A8: Attention Proxy](#task-a8)
12. [Task A9: Export Pipeline (Dart + JSON)](#task-a9)
13. [Task A10: Golden Test Generator](#task-a10)
14. [Task A11: Loan ML Pipeline](#task-a11)
15. [Task A12: Backend Scoring API](#task-a12)
16. [Task A13: Backend Loan API](#task-a13)
17. [Task A14: Fairness Engine](#task-a14)
18. [Task A15: Audit Trail](#task-a15)
19. [Deliverables Checklist](#deliverables-checklist)
20. [Quality Gates](#quality-gates)

---

# 1. YOUR RESPONSIBILITIES

You own **all Python code** and **all backend code**. Specifically:

| Area | What You Build | Output |
|------|---------------|--------|
| Synthetic Data | 15K profiles × 117 columns | `synthetic_profiles.csv` |
| ML Training | 5 models (LightGBM×2, XGBoost×2, ExtraTrees×1) | `.pkl` files |
| Scorecards | 3 hand-written Dart files (P5, P7, P8) | `.dart` files |
| Calibration | Isotonic + conformal intervals | 2 JSON files |
| Meta-Learner | Logistic Regression (20 inputs) | 1 JSON file |
| SHAP | 115-feature × 20-bin × 4-work-type lookup | 1 JSON file |
| Attention Proxy | Feature importance → proxy weights | 1 JSON file |
| Export | m2cgen → Dart scorers + 11 JSON constants | 10 Dart + 11 JSON |
| Golden Tests | 100 profiles with 6-stage expected results | 1 JSON file |
| Loan ML | LightGBM classifier + thresholds | 1 `.pkl` + 1 JSON |
| Backend | FastAPI + MongoDB (10 endpoints) | Running server |
| Fairness | 5 metrics + temporal + linguistic audit | Service class |
| Audit Trail | SHA-256 hash chain + decision replay | Service class |

# 2. WHAT YOU DO NOT TOUCH

- `app/` directory (Flutter app) — **Dev B only**
- `app/lib/scoring/` — Dev B only
- `app/lib/features/` — Dev B only
- Any `.dart` files inside the app (except the ones YOU generate via m2cgen)
- UI screens, widgets, navigation — Dev B only
- `pubspec.yaml` — Dev B only

# 3. EXECUTION ORDER (Dependencies)

```
A1: config.py ─────────────────────────────┐
A2: synthetic_data_generator.py ───────────┤ (needs A1)
A3: train_pillars_v3.py ──────────────────┤ (needs A2)
A4: scorecard_p5/p7/p8.dart ──────────────┤ (parallel with A3)
A5: calibration.py ────────────────────────┤ (needs A3)
A6: meta_learner_v3.py ───────────────────┤ (needs A5)
A7: shap_extractor.py ────────────────────┤ (needs A3)
A8: attention_proxy.py ────────────────────┤ (needs A3)
A9: export pipeline ──────────────────────┤ (needs A3-A8)
A10: golden_test_v3.py ───────────────────┤ (needs A9)
A11: loan ML pipeline ────────────────────┤ (needs A6)
A12: backend scoring API ─────────────────┤ (needs A3, parallel)
A13: backend loan API ────────────────────┤ (needs A11, A12)
A14: fairness engine ─────────────────────┤ (needs A12)
A15: audit trail ─────────────────────────┘ (needs A12)
```

**Critical path**: A1 → A2 → A3 → A5 → A6 → A9 → A10 (must be serial)
**Parallelizable**: A4, A7, A8, A12 can run alongside A3-A6

---

# TASK A1: Config & Constants
**File**: `ml_pipeline/config.py`
**Ref**: V3_03, V3_26

Create the single source of truth for all constants.

```python
# Feature indices per pillar (base features only)
P1_INDICES = list(range(0, 13))    # f0-f12, 13 features
P2_INDICES = list(range(13, 28))   # f13-f27, 15 features
P3_INDICES = list(range(28, 37))   # f28-f36, 9 features
P4_INDICES = list(range(37, 49))   # f37-f48, 12 features
P5_INDICES = list(range(49, 67))   # f49-f66, 18 features
P6_INDICES = list(range(67, 78))   # f67-f77, 11 features
P7_INDICES = list(range(78, 88))   # f78-f87, 10 features
P8_INDICES = list(range(88, 95))   # f88-f94, 7 features

# Cross-pillar feature routing (which cross features go to which pillar)
P1_CROSS = [95, 96, 97, 98]       # Group A
P2_CROSS = [105, 106, 107, 108]   # Group D
P3_CROSS = [95, 96, 97, 98]       # Group A (same as P1)
P4_CROSS = [99, 100, 101, 102]    # Group B + C[0]
P6_CROSS = [102, 103, 104]        # Group C

# Full input sizes per scorer (base + cross)
P1_INPUT_SIZE = 17  # 13 + 4
P2_INPUT_SIZE = 19  # 15 + 4
P3_INPUT_SIZE = 13  # 9 + 4
P4_INPUT_SIZE = 16  # 12 + 4
P6_INPUT_SIZE = 14  # 11 + 3

PILLAR_WEIGHTS = {"P1": 0.22, "P2": 0.18, "P3": 0.12, "P4": 0.13,
                  "P5": 0.10, "P6": 0.10, "P7": 0.08, "P8": 0.07}

WORK_TYPES = ["platform_worker", "street_vendor", "skilled_tradesperson", "freelancer"]

MODEL_TYPES = {"P1": "lgbm", "P2": "xgb", "P3": "xgb_shallow", "P4": "lgbm", "P6": "extratrees"}

# 115 feature names (all in order)
FEATURE_NAMES_95 = [...]  # 95 base feature names
FEATURE_NAMES_CROSS = [...]  # 20 cross-pillar names
FEATURE_NAMES_115 = FEATURE_NAMES_95 + FEATURE_NAMES_CROSS

# Work-type normalised feature indices
NORMALISED_INDICES = {1: 'income_cv', 2: 'income_growth_norm', 4: 'gig_share_norm',
                      28: 'payment_gap_freq', 47: 'balance_variability'}

# Scorecard weights
P5_WEIGHTS = [0.15,0.15,0.10,0.08,0.08,0.06,0.05,0.04,0.03,0.06,0.04,0.04,0.02,0.02,0.02,0.03,0.02,0.01]
P7_WEIGHTS = [0.15, 0.12, 0.10, 0.10, 0.08, 0.10, 0.08, 0.12, 0.10, 0.05]
P8_WEIGHTS = [0.25, 0.15, 0.20, 0.15, 0.10, 0.08, 0.07]
```

**Checklist**:
- [ ] All 115 feature names defined
- [ ] All pillar index ranges correct
- [ ] Cross-pillar routing indices match V3_26
- [ ] Pillar weights sum to 1.0
- [ ] Scorecard weights sum to 1.0 each

---

# TASK A2: Synthetic Data Generator
**File**: `ml_pipeline/generation/synthetic_data_generator.py`
**Ref**: V3_07

**What you build**: Generate 15K synthetic gig worker profiles with realistic, work-type-aware feature distributions. This is the foundation — garbage here means garbage models.

**Key requirements from your spec**:
- 4 work types: platform_worker (30%), street_vendor (30%), skilled_tradesperson (20%), freelancer (20%)
- Work-type-specific distributions (platform workers have tighter income CV than freelancers)
- Correlated feature clusters (insurance cluster, payment quality cluster, tax cluster)
- Stage 1: Work-type normalisation of 5 features
- Stage 2: Compute 20 cross-pillar features (f95-f114)
- Export `work_type_medians.json`

**Output**: `data/generated/synthetic_profiles.csv` (15K × 117) + `output/assets/work_type_medians.json`

**Quality gates**:
- [ ] All 115 features in [0, 1] range
- [ ] No NaN values
- [ ] Target distribution: mean ≈ 0.45, std ≈ 0.12
- [ ] Work type counts: 4500, 4500, 3000, 3000
- [ ] Insurance clustering: P(life|health) > P(life)
- [ ] Tax clustering: P(gst|itr) > P(gst)
- [ ] Cross-pillar features f95-f114 all valid
- [ ] work_type_medians.json has 4 entries × 5 constants

**Run**: `python -m generation.synthetic_data_generator`

---

# TASK A3: Train 5 ML Pillar Models
**File**: `ml_pipeline/training/train_pillars_v3.py`
**Ref**: V3_08

**CRITICAL**: Different model per pillar. This is NOT "train XGBoost 5 times".

| Pillar | Model | Why | Hyperparameters |
|--------|-------|-----|-----------------|
| P1 | LightGBM GBDT | Fat-tailed gig income | n_est=300, depth=5, lr=0.05, leaves=31 |
| P2 | XGBoost GBDT | Correlated payment features | n_est=250, depth=4, lr=0.05, colsample=0.7 |
| P3 | XGBoost shallow | 1 dominant feature (EMI ratio) | n_est=80, depth=2, lr=0.10 |
| P4 | LightGBM GBDT | Interaction constraints needed | n_est=250, depth=5, lr=0.05, leaves=31 |
| P6 | ExtraTreesRegressor | Binary flag features | n_est=200, depth=8, min_samples_leaf=10 |

**Each model trains on base features + routed cross-pillar features**:
```python
# P1 trains on: f[0:13] + f[95,96,97,98] = 17 features
X_p1 = np.column_stack([X[:, P1_INDICES], X[:, P1_CROSS]])
```

**Output**: 5 `.pkl` files in `output/models/`

**Quality gates**:
- [ ] P1 LightGBM: R² > 0.80, RMSE < 0.10
- [ ] P2 XGBoost: R² > 0.80, RMSE < 0.10
- [ ] P3 XGBoost shallow: R² > 0.70 (shallow is less expressive, acceptable)
- [ ] P4 LightGBM: R² > 0.80, RMSE < 0.10
- [ ] P6 ExtraTrees: R² > 0.75, RMSE < 0.12

---

# TASK A4: Write 3 Scorecard Dart Files
**Files**: `output/dart_export/scorecard_p5.dart`, `scorecard_p7.dart`, `scorecard_p8.dart`
**Ref**: V3_04, V3_13

Hand-written (NOT m2cgen). P5 has a KYC gate — if Aadhaar or PAN not verified, return 0.0.

**Checklist**:
- [ ] P5: 18 inputs, KYC gate on input[0] and input[1], weights sum to 1.0
- [ ] P7: 10 inputs, weights sum to 1.0
- [ ] P8: 7 inputs, weights sum to 1.0
- [ ] All return `.clamp(0.0, 1.0)`
- [ ] `dart analyze` passes on all 3 files

---

# TASK A5: Calibration & Conformal Intervals
**File**: `ml_pipeline/training/calibration.py`
**Ref**: V3_09

**Two outputs**:
1. **Isotonic knots** for 5 ML pillars → `calibration_knots.json`
2. **Conformal intervals** per pillar × work_type (20 entries) → `conformal_intervals.json`

Conformal uses α=0.10 for 90% coverage. Confidence mapping:
- interval ≤ 0.12 → HIGH (1.0)
- interval ≤ 0.20 → MEDIUM (0.75)
- interval > 0.20 → LOW (0.50)

**Quality gates**:
- [ ] ECE < 0.05 for all 5 ML pillars
- [ ] Conformal coverage ≥ 88% for all 20 pillar×work_type combos

---

# TASK A6: Meta-Learner Training
**File**: `ml_pipeline/training/meta_learner_v3.py`
**Ref**: V3_10

LogisticRegression with **20 inputs**: 8 calibrated pillar scores + 8 conformal confidence values + 4 auto-selected cross-pillar features (by mutual information).

**Output**: `meta_lr_coefficients.json` with 20 coefficients, intercept, `top4_cross_pillar_indices`, and AUC.

**CRITICAL**: The `top4_cross_pillar_indices` field tells Dev B which 4 cross-pillar features to pick from the 115-element vector. Without this field, Dev B cannot build the meta-learner input.

**Quality gates**:
- [ ] AUC-ROC > 0.88
- [ ] Accuracy > 0.82
- [ ] `top4_cross_pillar_indices` is a list of 4 integers in range [95, 114]

---

# TASK A7: SHAP Extraction
**File**: `ml_pipeline/explainability/shap_extractor.py`
**Ref**: V3_11

**Different SHAP method per model type**:
- P1, P4 (LightGBM): `model.predict(X, pred_contrib=True)` — built-in, fastest
- P2, P3 (XGBoost): `shap.TreeExplainer(model).shap_values(X)` — exact
- P6 (ExtraTrees): `shap.TreeExplainer(model).shap_values(X)` — sklearn supported
- P5, P7, P8 (Scorecard): synthetic SHAP from weights

**20-bin, work-type-aware**: For each of 115 features, compute SHAP in 20 bins, separately for each of 4 work types.

**Output**: `shap_lookup_v3.json` (~800KB, 115 entries × 20 bins × 4 work types)

**Quality gates**:
- [ ] 115 entries present
- [ ] Each entry has 20 SHAP values per work type
- [ ] All 4 work types present
- [ ] No NaN values
- [ ] `mean_abs_shap > 0` for all ML features

---

# TASK A8: Attention Proxy
**File**: `ml_pipeline/explainability/attention_proxy.py`
**Ref**: V3_12

Extract feature importances from each model as proxy attention weights. LightGBM uses `model.feature_importances_`, XGBoost uses `model.get_score()`, ExtraTrees uses `model.feature_importances_`.

**Output**: `tabnet_attention.json`

---

# TASK A9: Export Pipeline
**Files**: `ml_pipeline/export/export_m2cgen_v3.py`, `constants_exporter.py`
**Ref**: V3_13

**m2cgen export for 3 model types**: LightGBM, XGBoost, ExtraTrees — all supported.

**You generate 10 Dart files**: 5 ML scorers + 3 scorecards + 1 meta_learner_lr + 1 scoring_constants

**You generate 11 JSON files**: shap_lookup, tabnet_attention, calibration_knots, conformal_intervals, meta_lr_coefficients, pillar_weights, actionability_tags, feature_display_names, work_type_medians, causal_chains, loan_thresholds

**CRITICAL — actionability_tags.json**: Must have 115 entries, each with `"actionable": "immediate"|"behavioural"|"non_actionable"`. Dev B uses this to decide what to show users.

**CRITICAL — causal_chains.json**: 15 hand-written rules. You must write these — they encode domain knowledge about gig worker patterns.

**Quality gates**:
- [ ] `dart analyze output/dart_export/` → zero errors
- [ ] All 11 JSON files present and valid
- [ ] actionability_tags has 115 entries
- [ ] causal_chains has 15 rules

---

# TASK A10: Golden Test Generator
**File**: `ml_pipeline/export/golden_test_v3.py`
**Ref**: V3_13

100 profiles run through ALL 6 stages in Python. Dev B uses these to verify Dart produces identical results.

**Output**: `golden_100.json` with expected raw pillars, calibrated pillars, confidence, probability, score, and grade per profile.

---

# TASK A11: Loan ML Pipeline
**Files**: `ml_pipeline/loan/loan_data_generator.py`, `loan_lgbm_trainer.py`, `threshold_calibrator.py`
**Ref**: V3_14

3 products: Emergency Micro (₹5K-25K, min 450), Income Bridge (₹25K-1L, min 550), Growth (₹1L-5L, min 650).

LightGBM binary classifier with 18 features. Per (product × work_type) threshold calibration.

**Output**: `loan_lgbm.pkl` + `loan_thresholds.json` (12 entries)

---

# TASK A12: Backend Scoring API
**Files**: `backend/app/api/scoring_router.py`, `explainability_router.py`
**Ref**: V3_15, V3_06

**Endpoints**: POST /score/store, GET /score/history/{user_id}, POST /explain/full

The `/explain/full` endpoint implements server-side L5-L10:
- L5: Live SHAP (per-model-type method)
- L6: EFS (50-run perturbation test)
- L7: Peer cohort (25 nearest neighbours)
- L9: Delta-SHAP (returning users)
- L10: LLM translation (Gemini API, with template fallback)

---

# TASK A13: Backend Loan API
**File**: `backend/app/api/loan_router.py`
**Ref**: V3_16, V3_06

**4 endpoints**: POST /loan/products, POST /loan/kfs, POST /loan/apply, GET /loan/decision/{id}

`/loan/products` must pre-compute max_eligible_amount (prevents users from over-requesting).

`/loan/apply` runs 3-stage gate: Hard Rules → Affordability → LightGBM classifier.

Every rejection generates: AAN (RBI mandatory) + 3 DiCE counterfactual paths + alternative product offer. The "amount adjustment" path must ALWAYS be present.

Risk-based pricing: 12% (800+), 15% (720+), 18% (640+), 21% (560+), 24% (480+).

---

# TASK A14: Fairness Engine
**File**: `backend/app/services/fairness_engine.py`
**Ref**: V3_30

5 standard metrics (demographic parity, equalized odds, calibration, individual fairness, disparate impact) + temporal fairness + linguistic bias audit.

Runs async — never blocks decisions. Auto-mitigates violations.

---

# TASK A15: Audit Trail
**File**: `backend/app/services/audit_chain.py`
**Ref**: V3_31

SHA-256 hash-chained records. Every score and loan decision gets an immutable audit record with full feature vector, model hashes, and SHAP values.

Decision replay endpoint: re-run stored features through stored model → prove same result.

---

# DELIVERABLES CHECKLIST

## Dart Files (10 total — Dev B imports these)
- [ ] `output/dart_export/p1_scorer.dart` — LightGBM m2cgen (17 inputs)
- [ ] `output/dart_export/p2_scorer.dart` — XGBoost m2cgen (19 inputs)
- [ ] `output/dart_export/p3_scorer.dart` — XGBoost shallow m2cgen (13 inputs)
- [ ] `output/dart_export/p4_scorer.dart` — LightGBM m2cgen (16 inputs)
- [ ] `output/dart_export/p6_scorer.dart` — ExtraTrees m2cgen (14 inputs)
- [ ] `output/dart_export/scorecard_p5.dart` — hand-written (18 inputs, KYC gate)
- [ ] `output/dart_export/scorecard_p7.dart` — hand-written (10 inputs)
- [ ] `output/dart_export/scorecard_p8.dart` — hand-written (7 inputs)
- [ ] `output/dart_export/meta_learner_lr.dart` — LR dot-product (20 inputs)
- [ ] `output/dart_export/scoring_constants.dart` — score mapping utils

## JSON Files (11 total — Dev B bundles 10 in app)
- [ ] `output/assets/shap_lookup_v3.json` — 115 features × 20 bins × 4 work types
- [ ] `output/assets/tabnet_attention.json` — per-pillar attention
- [ ] `output/assets/calibration_knots.json` — 5 ML pillar knots
- [ ] `output/assets/conformal_intervals.json` — 5 pillars × 4 work types
- [ ] `output/assets/meta_lr_coefficients.json` — 20 coefficients + top4 indices
- [ ] `output/assets/pillar_weights.json` — 8 weights
- [ ] `output/assets/actionability_tags.json` — 115 entries, 3-tier
- [ ] `output/assets/feature_display_names.json` — 115 human labels
- [ ] `output/assets/work_type_medians.json` — 4 types × 5 constants
- [ ] `output/assets/causal_chains.json` — 15 rules
- [ ] `output/assets/loan_thresholds.json` — 12 entries (server-only)

## Model Files (6 total)
- [ ] `output/models/p1_lgbm.pkl`
- [ ] `output/models/p2_xgb.pkl`
- [ ] `output/models/p3_xgb_shallow.pkl`
- [ ] `output/models/p4_lgbm.pkl`
- [ ] `output/models/p6_et.pkl`
- [ ] `output/models/loan_lgbm.pkl`

## Golden Tests
- [ ] `output/golden/golden_100.json` — 100 profiles with full 6-stage expectations

## Backend Running
- [ ] FastAPI on port 8000
- [ ] POST /api/v1/score/store — works
- [ ] GET /api/v1/score/history/{user_id} — works
- [ ] POST /api/v1/explain/full — works (L5-L10)
- [ ] POST /api/v1/loan/products — works (3 products + max eligible)
- [ ] POST /api/v1/loan/kfs — works (RBI fields)
- [ ] POST /api/v1/loan/apply — works (3-stage + AAN + DiCE)
- [ ] GET /api/v1/loan/decision/{id} — works
- [ ] GET /api/v1/audit/verify — works
- [ ] GET /api/v1/audit/replay/{id} — works
- [ ] GET /api/v1/fairness/report — works

## Quality Gates (ALL must pass before handing to Dev B)
- [ ] `dart analyze output/dart_export/` → zero errors
- [ ] All 11 JSON files valid JSON, no NaN
- [ ] Golden test: 100 profiles, scores in 300-900
- [ ] Backend: all 10 endpoints return 200
- [ ] Audit chain: verify returns chain_valid=true
