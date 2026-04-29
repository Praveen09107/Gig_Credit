# V3.0 Dev A — SHAP Extraction Spec (CORRECTED)

## File: `ml_pipeline/explainability/shap_extractor.py`

## Key Changes from Old Spec
- **20 bins** (not 10)
- **Work-type-aware** bins (4 separate tables per feature)
- **115 features** (not 95)
- **Different SHAP methods per model type**
- **Pillar-level SHAP aggregation**

---

## SHAP Method Per Model Type

| Pillar | Model | SHAP Method | Reason |
|--------|-------|-------------|--------|
| P1 | LightGBM | `model.predict(X, pred_contrib=True)` | Built-in, fastest |
| P2 | XGBoost | `shap.TreeExplainer(model).shap_values(X)` | Exact |
| P3 | XGBoost | `shap.TreeExplainer(model).shap_values(X)` | Exact |
| P4 | LightGBM | `model.predict(X, pred_contrib=True)` | Built-in, fastest |
| P6 | ExtraTrees | `shap.TreeExplainer(model).shap_values(X)` | sklearn supported |
| P5, P7, P8 | Scorecard | Synthetic from weights | No model to explain |

```python
def compute_shap(pillar, model, X_val):
    if pillar in ['P1', 'P4']:  # LightGBM
        # pred_contrib returns (n_samples, n_features+1), last col = bias
        contribs = model.predict(X_val, pred_contrib=True)
        return contribs[:, :-1]  # exclude bias column
    elif pillar in ['P2', 'P3']:  # XGBoost
        explainer = shap.TreeExplainer(model)
        return explainer.shap_values(X_val)
    elif pillar == 'P6':  # ExtraTrees
        explainer = shap.TreeExplainer(model)
        return explainer.shap_values(X_val)
```

---

## 20-Bin Work-Type-Aware Binning

```python
bins = np.linspace(0.0, 1.0, 21)  # 21 edges → 20 bins

for feature_idx, fname in enumerate(ALL_115_FEATURES):
    entry = {"pillar": FEATURE_TO_PILLAR[fname], "display_name": DISPLAY_NAMES[fname]}
    entry["bins"] = bins.tolist()
    entry["shap_by_work_type"] = {}
    
    for wt in WORK_TYPES:
        wt_mask = val_df['work_type'] == wt
        values = X_val[wt_mask, feature_idx]
        shap_col = shap_values[wt_mask, feature_idx]
        
        binned = []
        for b in range(20):
            mask = (values >= bins[b]) & (values < bins[b+1])
            if mask.sum() > 5:
                binned.append(float(np.mean(shap_col[mask])))
            else:
                binned.append(0.0)  # insufficient samples
        
        entry["shap_by_work_type"][wt] = binned
    
    entry["mean_abs_shap"] = float(np.mean(np.abs(shap_values[:, feature_idx])))
    lookup[fname] = entry
```

---

## Scorecard Pillars (P5, P7, P8) — Synthetic SHAP

```python
for fname, weight in P5_WEIGHTS.items():
    bin_centers = [(bins[i] + bins[i+1]) / 2 for i in range(20)]
    shap_values = [(v - 0.5) * weight * 2 for v in bin_centers]
    # Same values for all work types (scorecard is deterministic)
    lookup[fname] = {
        "pillar": "P5",
        "display_name": DISPLAY_NAMES[fname],
        "bins": bins.tolist(),
        "shap_by_work_type": {wt: shap_values for wt in WORK_TYPES},
        "mean_abs_shap": abs(weight)
    }
```

---

## Cross-Pillar Features (f95-f114) — SHAP Entries

These go through the SAME binning process but SHAP comes from whichever pillar model includes them:
- f95-f98 → P1 model's SHAP (Group A routed to P1)
- f99-f101 → P4 model's SHAP (Group B routed to P4)
- f102-f104 → P6 model's SHAP (Group C routed to P6)
- f105-f108 → P2 model's SHAP (Group D routed to P2)
- f109-f111 → Synthetic (Group E, formal recognition)
- f112-f114 → Synthetic (Group F, temporal)

---

## Pillar-Level SHAP Aggregation

After computing all 115 feature-level SHAPs:
```python
pillar_shap = {}
for pillar in PILLARS:
    pillar_features = get_features_for_pillar(pillar, include_cross=True)
    pillar_shap[pillar] = sum(shap_values[f] for f in pillar_features)
```

This gives ONE number per pillar → used by L1 Pillar Contribution Decomposition.

---

## Output: `shap_lookup_v3.json`

```json
{
  "avg_monthly_income_norm": {
    "pillar": "P1",
    "pillar_label": "Income Stability",
    "display_name": "Average Monthly Income",
    "bins": [0.0, 0.05, 0.10, ..., 0.95, 1.0],
    "shap_by_work_type": {
      "platform_worker": [-0.024, -0.021, ..., 0.025],
      "street_vendor": [-0.028, -0.024, ..., 0.021],
      "skilled_tradesperson": [-0.022, -0.019, ..., 0.023],
      "freelancer": [-0.020, -0.017, ..., 0.027]
    },
    "mean_abs_shap": 0.0098
  },
  "income_debt_stress_index": {
    "pillar": "cross:P1×P3",
    "display_name": "Income-Debt Stress Index",
    "bins": [...],
    "shap_by_work_type": {...},
    "mean_abs_shap": 0.0072
  }
}
```

- **115 entries** (95 base + 20 cross-pillar)
- **20 bins** per entry
- **4 work-type SHAP arrays** per entry

## Quality Checks
- All 115 features present
- No NaN in any shap array
- Each shap array has exactly 20 values
- All 4 work types present per feature
- `mean_abs_shap > 0` for all ML features
- Top-5 by `mean_abs_shap` per pillar should be semantically reasonable

## Execution
```bash
python -m explainability.shap_extractor
# Output: output/assets/shap_lookup_v3.json (~800KB)
```
