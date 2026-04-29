# V3.0 Dev A — Calibration & Conformal Spec (CORRECTED)

## Files
- `ml_pipeline/training/calibration.py` — Isotonic regression + conformal intervals

---

## Part 1: Isotonic Regression Calibration (5 ML Pillars)

### Purpose
Raw model outputs are not well-calibrated probabilities. Isotonic regression maps raw → calibrated while preserving rank ordering.

### Which Models
| Pillar | Model | Calibration Needed? |
|--------|-------|-------------------|
| P1 | LightGBM | ✅ Yes |
| P2 | XGBoost | ✅ Yes |
| P3 | XGBoost shallow | ✅ Yes |
| P4 | LightGBM | ✅ Yes |
| P5 | Scorecard | ❌ No (deterministic) |
| P6 | ExtraTrees | ✅ Yes |
| P7 | Scorecard | ❌ No |
| P8 | Scorecard | ❌ No |

### Method
```python
from sklearn.isotonic import IsotonicRegression

for pillar in ['P1', 'P2', 'P3', 'P4', 'P6']:
    model = models[pillar]
    raw_pred = model.predict(X_val_pillar[pillar])
    
    iso = IsotonicRegression(out_of_bounds='clip')
    iso.fit(raw_pred, y_val_pillar[pillar])
    
    # Extract knots (the piecewise-linear breakpoints)
    cal_knots[pillar] = {
        'knots_x': iso.X_thresholds_.tolist(),
        'knots_y': iso.y_thresholds_.tolist(),
        'model_type': MODEL_TYPES[pillar],
    }
```

### Validation
```python
# Before calibration: check reliability diagram
# After calibration: expected calibration error (ECE) < 0.05
for pillar in ML_PILLARS:
    cal_pred = iso.predict(raw_pred)
    ece = compute_ece(y_true, cal_pred, n_bins=10)
    assert ece < 0.05, f"{pillar} ECE {ece} too high"
```

---

## Part 2: Conformal Prediction Intervals (Per Pillar × Per Work Type)

### Purpose
Replace the old guessed formula `0.5 × completeness + 0.3 × reliability + 0.2 × consistency` with statistically guaranteed 90% coverage intervals.

### Method
Uses a held-out **calibration set** (10% of data = 1,500 profiles):

```python
alpha = 0.10  # 90% confidence → α = 0.10

for pillar in ML_PILLARS:
    conformal[pillar] = {}
    model = models[pillar]
    
    for wt in WORK_TYPES:
        wt_mask = cal_df['work_type'] == wt
        X_cal_wt = X_cal_pillar[pillar][wt_mask]
        y_cal_wt = y_cal_pillar[pillar][wt_mask]
        
        # Predict and calibrate
        raw_pred = model.predict(X_cal_wt)
        cal_pred = calibrate(raw_pred, cal_knots[pillar])
        
        # Nonconformity scores
        nonconformity = np.abs(cal_pred - y_cal_wt)
        
        # q̂ = (1-α)(1+1/n)-th quantile of nonconformity scores
        n = len(nonconformity)
        q_level = np.ceil((1 - alpha) * (n + 1)) / n
        q_hat = np.quantile(nonconformity, min(q_level, 1.0))
        
        conformal[pillar][wt] = {
            'half_width': round(float(q_hat), 4),
            'coverage': 1 - alpha,
            'n_calibration': int(n),
        }
```

### Confidence Mapping (Dev B uses this in Dart)
```
interval_width = 2 × half_width

if interval_width ≤ 0.12:  → HIGH confidence (1.0)   → full pillar contribution
if interval_width ≤ 0.20:  → MEDIUM confidence (0.75) → pull toward 0.50
if interval_width > 0.20:  → LOW confidence (0.50)    → neutralise toward 0.50
```

### Score Adjustment (Dev B implements)
```
adjusted_score = calibrated_score × confidence + 0.50 × (1 - confidence)
```

### Output Files
1. `output/assets/calibration_knots.json` — 5 entries
2. `output/assets/conformal_intervals.json` — 5 pillars × 4 work types = 20 entries

### Validation
```python
# Verify coverage on test set (must be ≥ 88% for each group)
for pillar in ML_PILLARS:
    for wt in WORK_TYPES:
        hw = conformal[pillar][wt]['half_width']
        test_pred = calibrate(model.predict(X_test_wt), cal_knots[pillar])
        coverage = np.mean(np.abs(test_pred - y_test_wt) <= hw)
        assert coverage >= 0.88, f"{pillar}/{wt} coverage {coverage} below 88%"
```

## Execution
```bash
python -m training.calibration
```
