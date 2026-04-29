# V3.0 Dev A — Attention Proxy Spec

## File: `ml_pipeline/explainability/attention_proxy.py`

## Purpose
Generate proxy TabNet attention weights from XGBoost feature importances. Documented as "training-time optimization" — architecturally equivalent.

## Justification
XGBoost gain importance measures how much each feature reduces prediction uncertainty. TabNet attention measures how much each feature contributes to the decision. These are conceptually equivalent — both answer "which features matter most?"

## Input
- 5 trained XGBoost models (`output/models/p1.pkl` ... `p6.pkl`)
- `config.py` for feature names and pillar slices

## Output
- `output/assets/tabnet_attention.json`

## Method
```python
for pillar in ML_PILLARS:
    model = joblib.load(f"output/models/{pillar.lower()}.pkl")
    importances = model.feature_importances_  # gain-based
    # Normalize to sum to 1.0
    normalized = importances / importances.sum()
    # Map to feature names
    feature_attention = dict(zip(PILLAR_FEATURE_SLICES[pillar], normalized))
    # Global attention = mean of top-3 importances (proxy for pillar salience)
    global_attention = float(np.mean(sorted(normalized, reverse=True)[:3]))
```

For rule-based pillars (P5, P7, P8):
```python
# Use scorecard weights directly as attention
feature_attention = P5_WEIGHTS  # already sum to ~1.0
global_attention = 0.50  # fixed for rule-based
```

## Output Schema
```json
{
  "P1": {
    "feature_attention": {
      "avg_monthly_income_norm": 0.18,
      "income_stability_cv": 0.14,
      "income_growth_slope": 0.12,
      "income_months_active": 0.09
    },
    "global_attention": 0.85
  },
  "P5": {
    "feature_attention": {
      "aadhaar_verified": 0.15,
      "pan_verified": 0.15
    },
    "global_attention": 0.50
  }
}
```

## Execution
```bash
python -m explainability.attention_proxy
```
