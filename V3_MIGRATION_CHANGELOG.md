# V3.0 Migration Changelog — What Dev B (Praveen) Did Before You Start

> **Date**: April 29, 2026
> **Author**: Dev B (Praveen)
> **Purpose**: Explain EXACTLY what was changed so Dev A can start implementing confidently

---

## TL;DR

1. Tagged the entire v2.0 codebase as `v2.0-final` in git
2. Copied all old ML + scoring files to `_archive_v2/` (reference + fallback)
3. Deleted old files from active directories (clean slate for v3)
4. Created v3 directory structure with empty `.gitkeep` files
5. Added 32 planning documents in `planning_new/`
6. Added 2 complete dev guides (`DEV_A_COMPLETE_GUIDE.md`, `DEV_B_COMPLETE_GUIDE.md`)

---

## WHAT WAS MOVED TO `_archive_v2/`

### ML Pipeline Files (your domain)

| Old Location | Archived To | Why Removed |
|-------------|------------|-------------|
| `ml_pipeline/training/train_pillars.py` | `_archive_v2/ml_pipeline/training/` | v2 used ALL XGBoost. v3 uses LightGBM (P1,P4), XGBoost (P2,P3), ExtraTrees (P6) |
| `ml_pipeline/training/train_meta_learner.py` | `_archive_v2/ml_pipeline/training/` | v2 used XGBoost/RF/LR ensemble with 24 inputs. v3 uses LogReg with 20 inputs |
| `ml_pipeline/export/export_m2cgen.py` | `_archive_v2/ml_pipeline/export/` | v2 exported XGBoost only. v3 must handle LightGBM + ExtraTrees too |
| `ml_pipeline/export/generate_shap.py` | `_archive_v2/ml_pipeline/export/` | v2 did 10-bin single-work-type. v3 needs 20-bin × 4 work types × 115 features |
| `ml_pipeline/export/generate_golden.py` | `_archive_v2/ml_pipeline/export/` | v2 tested 7 pillars, 95 features. v3 needs 8 pillars, 115 features, 6 stages |
| `ml_pipeline/output/models/*.pkl` | `_archive_v2/ml_pipeline/output/models/` | All v2 XGBoost models — incompatible with v3 |
| `ml_pipeline/output/json_configs/*` | `_archive_v2/ml_pipeline/output/json_configs/` | v2 had 3 JSON files. v3 needs 11 JSON files with different schemas |
| `ml_pipeline/output/dart_exports/*` | `_archive_v2/ml_pipeline/output/dart_exports/` | v2 XGBoost m2cgen exports — will be replaced by v3 |
| `ml_pipeline/output/golden/*` | `_archive_v2/ml_pipeline/output/golden/` | v2 golden tests — different pipeline |

### App Scoring Files (Dev B domain, but archived for reference)

| Old Location | Archived To | Why Removed |
|-------------|------------|-------------|
| `app/lib/scoring/models/meta_scorer.dart` (1MB) | `_archive_v2/app_scoring/models/` | v2 XGBoost meta-scorer → replaced by 20-input LR |
| `app/lib/scoring/models/p1-p4,p6_scorer.dart` (~750KB each) | `_archive_v2/app_scoring/models/` | v2 XGBoost scorers → will be replaced by v3 multi-model scorers |
| `app/lib/scoring/models/scorecard_p5.dart` | `_archive_v2/app_scoring/models/` | v2 scorecard → v3 adds KYC gate |
| `app/lib/scoring/models/scorecard_p7.dart` | `_archive_v2/app_scoring/models/` | Archived — v3 has same concept but different weights |
| `app/lib/scoring/engine/scoring_engine.dart` | `_archive_v2/app_scoring/engine/` | v2 had 7 pillars, no cross-pillar routing |
| `app/lib/scoring/engine/meta_learner.dart` | `_archive_v2/app_scoring/engine/` | v2 used m2cgen XGBoost, v3 uses LR dot-product |
| `app/lib/scoring/engine/confidence_engine.dart` | `_archive_v2/app_scoring/engine/` | v2 used manual formula, v3 uses conformal prediction |
| `app/lib/scoring/explainability/shap_lookup.dart` | `_archive_v2/app_scoring/explainability/` | v2 had 1 XAI layer, v3 has 5 on-device layers |
| `app/lib/scoring/features/feature_engineer.dart` | `_archive_v2/app_scoring/features/` | v2 extracted 95 features, v3 needs 115 + normalisation |
| `app/lib/scoring/score_pipeline.dart` | `_archive_v2/app_scoring/` | v2 pipeline → v3 is complete rewrite (6 stages) |

---

## WHAT WAS NOT TOUCHED (FROZEN)

These files are EXACTLY as they were. Do NOT modify them:

### Backend (your domain — keep these, add new routes alongside)
- `backend/app/api/bank_verification.py` ✅ FROZEN
- `backend/app/api/gov_verification.py` ✅ FROZEN
- `backend/app/api/insurance_verification.py` ✅ FROZEN
- `backend/app/api/otp_routes.py` ✅ FROZEN
- `backend/app/api/report_routes.py` ✅ FROZEN
- `backend/app/auth/` ✅ FROZEN
- `backend/app/db/` ✅ FROZEN
- `backend/app/schemas/` ✅ FROZEN (extend with new schemas)
- `backend/app/config.py` ✅ FROZEN
- `backend/app/main.py` ✅ FROZEN (add new router imports)
- `backend/.env` ✅ FROZEN

### Flutter App (Dev B domain — you don't touch)
- `app/lib/features/` ✅ FROZEN (onboarding screens)
- `app/lib/models/` ✅ FROZEN (non-scoring models)
- `app/lib/services/` ✅ FROZEN (API services)
- `app/lib/core/` ✅ FROZEN
- `app/lib/state/` ✅ FROZEN
- `app/lib/shared/` ✅ FROZEN

### ML Pipeline (your domain — kept)
- `ml_pipeline/config.py` ✅ KEPT — this is the NEW v3 config (I created it)
- `ml_pipeline/data/` ✅ KEPT — data directory (you'll write generated data here)
- `ml_pipeline/validation/` ✅ KEPT — validation directory
- `ml_pipeline/requirements.txt` ✅ KEPT — update with new dependencies

---

## V3 DIRECTORY STRUCTURE (READY FOR YOU)

```
ml_pipeline/
├── config.py                    ← EXISTS (v3 constants — verify and update)
├── requirements.txt             ← EXISTS (add lightgbm, shap, m2cgen, dice-ml)
├── data/                        ← EXISTS (put synthetic_profiles.csv here)
│   └── generated/               ← CREATE THIS when you run data generator
├── generation/                  ← NEW EMPTY (create synthetic_data_generator.py here)
│   └── .gitkeep
├── training/                    ← EMPTY (create train_pillars_v3.py, calibration.py, meta_learner_v3.py)
│   └── .gitkeep
├── explainability/              ← NEW EMPTY (create shap_extractor.py, attention_proxy.py)
│   └── .gitkeep
├── export/                      ← EMPTY (create export_m2cgen_v3.py, constants_exporter.py, golden_test_v3.py)
│   └── .gitkeep
├── loan/                        ← NEW EMPTY (create loan_data_generator.py, loan_lgbm_trainer.py, threshold_calibrator.py)
│   └── .gitkeep
├── validation/                  ← EXISTS
│   └── .gitkeep
└── output/
    ├── models/                  ← EMPTY (your .pkl files go here)
    │   └── .gitkeep
    ├── assets/                  ← NEW EMPTY (your 11 JSON files go here)
    │   └── .gitkeep
    ├── dart_export/             ← NEW EMPTY (your 10 Dart files go here)
    │   └── .gitkeep
    ├── dart_exports/            ← EMPTY (old name, use dart_export instead)
    │   └── .gitkeep
    ├── json_configs/            ← EMPTY (old name, use assets instead)
    │   └── .gitkeep
    └── golden/                  ← EMPTY (golden_100.json goes here)
        └── .gitkeep

backend/
├── app/
│   ├── api/
│   │   ├── bank_verification.py     ← FROZEN
│   │   ├── gov_verification.py      ← FROZEN
│   │   ├── insurance_verification.py ← FROZEN
│   │   ├── otp_routes.py            ← FROZEN
│   │   ├── report_routes.py         ← FROZEN
│   │   ├── scoring_router.py        ← CREATE THIS (V3_15)
│   │   ├── explainability_router.py ← CREATE THIS (V3_15)
│   │   └── loan_router.py           ← CREATE THIS (V3_16)
│   ├── services/
│   │   ├── fairness_engine.py       ← CREATE THIS (V3_30)
│   │   └── audit_chain.py           ← CREATE THIS (V3_31)
│   └── ... (existing auth, db, schemas — FROZEN)
```

---

## YOUR FIRST STEPS (Dev A)

### Step 0: Pull and Verify
```bash
git pull origin main
git log --oneline -5    # Should see "v2.0 final state" and "v3.0 restructure" commits
ls _archive_v2/         # Should see your old code archived
ls ml_pipeline/training/ # Should only have .gitkeep
```

### Step 1: Read Your Guide
Open `planning_new/DEV_A_COMPLETE_GUIDE.md` — it has your full 15-task checklist.

### Step 2: Update requirements.txt
```
lightgbm>=4.0
xgboost>=2.0
scikit-learn>=1.3
shap>=0.42
m2cgen>=0.10
dice-ml>=0.10
numpy>=1.24
pandas>=2.0
joblib>=1.3
```

### Step 3: Start with Task A1 (config.py)
The file `ml_pipeline/config.py` already exists with v3 constants. Verify it matches `planning_new/V3_03_FEATURE_VECTOR_CONTRACT.md`.

### Step 4: Follow the Guide
A1 → A2 → A3 → A4 → A5 → A6 → A7 → A8 → A9 → A10 → A11 → A12 → A13 → A14 → A15

---

## PLANNING DOCUMENTS MAP

All 32 spec documents are in `planning_new/`. Here's your quick reference:

| Your Task | Reference Doc |
|-----------|--------------|
| Synthetic data | `V3_07_DEV_A_SYNTHETIC_DATA.md` |
| Training (5 models) | `V3_08_DEV_A_TRAINING_PIPELINE.md` |
| Calibration + conformal | `V3_09_DEV_A_CALIBRATION.md` |
| Meta-learner | `V3_10_DEV_A_META_LEARNER.md` |
| SHAP extraction | `V3_11_DEV_A_SHAP_EXTRACTION.md` |
| Attention proxy | `V3_12_DEV_A_ATTENTION_PROXY.md` |
| Export pipeline | `V3_13_DEV_A_EXPORT_PIPELINE.md` |
| Loan ML | `V3_14_DEV_A_LOAN_ML.md` |
| Backend scoring | `V3_15_DEV_A_BACKEND_SCORING.md` |
| Backend loan | `V3_16_DEV_A_BACKEND_LOAN.md` |
| Cross-pillar features | `V3_26_CROSS_PILLAR_FEATURES.md` |
| Work-type normalisation | `V3_27_WORK_TYPE_NORMALISATION.md` |
| 10-layer XAI | `V3_28_EXPLAINABILITY_10_LAYERS.md` |
| Loan products | `V3_29_LOAN_PRODUCTS_PRICING.md` |
| Fairness engine | `V3_30_FAIRNESS_ENGINE.md` |
| Audit trail | `V3_31_AUDIT_TRAIL.md` |

### Shared contracts (READ FIRST):
- `V3_03_FEATURE_VECTOR_CONTRACT.md` — all 115 features
- `V3_04_SCORER_FUNCTION_CONTRACTS.md` — exact Dart function signatures
- `V3_05_JSON_ASSET_SCHEMAS.md` — 11 JSON file schemas
- `V3_06_BACKEND_API_CONTRACTS.md` — all API request/response schemas

---

## GIT RECOVERY

If anything goes wrong:
```bash
# Restore v2.0 completely:
git checkout v2.0-final

# Restore a specific v2 file:
cp _archive_v2/ml_pipeline/training/train_pillars.py ml_pipeline/training/

# See what changed:
git diff v2.0-final..main --stat
```
