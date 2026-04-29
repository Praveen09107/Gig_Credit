# v2.0 Archive

**DO NOT USE THESE FILES IN v3.0** — they are here for reference only.

## What's Here

### `ml_pipeline/training/`
- `train_pillars.py` — v2 XGBoost trainer (all pillars used XGBoost)
- `train_meta_learner.py` — v2 meta-learner (XGBoost/RF/LR ensemble)

### `ml_pipeline/export/`
- `export_m2cgen.py` — v2 m2cgen export (XGBoost only)
- `generate_golden.py` — v2 golden test generator
- `generate_shap.py` — v2 SHAP (10-bin, not work-type-aware)

### `ml_pipeline/output/models/`
- `p1.pkl` through `p6.pkl` — v2 XGBoost pillar models
- `meta_xgb.pkl`, `meta_rf.pkl`, `meta_lr.pkl` — v2 meta-learner models

### `ml_pipeline/output/json_configs/`
- `shap_lookup.json` — v2 SHAP (46KB, 10-bin, single work type)
- `meta_coefficients.json` — v2 meta coefficients (24 inputs)
- `feature_means.json` — v2 feature means

### `ml_pipeline/output/dart_exports/`
- All v2 Dart scorer files (XGBoost m2cgen output)

### `app_scoring/`
- All v2 Dart scoring engine files (from `app/lib/scoring/`)

## Why Archived (Not Deleted)

1. **Reference**: Dev A can see how v2 training worked to understand patterns
2. **Fallback**: If v3 training fails, v2 models can be restored temporarily
3. **Git tag**: Also tagged as `v2.0-final` in git history

## v2 → v3 Key Differences

| Aspect | v2 | v3 |
|--------|----|----|
| Pillars | 7 (P1-P7) | 8 (P1-P8 Tax) |
| Models | All XGBoost | LightGBM/XGBoost/ExtraTrees |
| Features | 95 | 115 (+ 20 cross-pillar) |
| SHAP | 10-bin, single | 20-bin, 4 work types |
| Meta-learner | XGBoost (24 in) | LogReg (20 in) |
| Calibration | None | Isotonic + Conformal |
| XAI layers | 1 (SHAP) | 10 (4 on-device + 6 server) |
