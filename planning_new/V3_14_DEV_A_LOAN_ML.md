# V3.0 Dev A — Loan ML Pipeline Spec (CORRECTED)

## Files
- `ml_pipeline/loan/loan_data_generator.py`
- `ml_pipeline/loan/loan_lgbm_trainer.py`
- `ml_pipeline/loan/threshold_calibrator.py`

---

## Part 1: Loan Data Generator

### Purpose
Generate 50K synthetic loan scenarios mapped to 3 real gig worker products.

### Output
- `data/generated/loan_scenarios.csv` (50K × 22 columns)

### 3 Products
| Product ID | Amount Range | Min Score |
|-----------|-------------|-----------|
| `emergency_micro` | ₹5K–₹25K | 450 |
| `income_bridge` | ₹25K–₹1L | 550 |
| `growth` | ₹1L–₹5L | 650 |

### Columns (22)
```
final_score, P1-P8 (8), work_type,
requested_amount, product_id,
income, existing_emi,
dscr, post_loan_emi_ratio, loan_to_income,
payment_streak, insurance_coverage,
savings_buffer_months, income_growth_slope,
w_platform, w_vendor,
outcome (0=default, 1=repaid)
```

### Outcome Logic
```python
prob_repay = sigmoid(
    0.004 * final_score +
    0.3 * dscr +
    -0.5 * post_loan_emi_ratio +
    -0.2 * loan_to_income +
    0.1 * payment_streak +
    0.05 * insurance_coverage +
    0.08 * savings_buffer_months +
    noise(0.1)
)
outcome = (np.random.random() < prob_repay).astype(int)
```

---

## Part 2: LightGBM Trainer

### Input Features (18) — matches backend loan router
```python
LOAN_FEATURES = [
    "final_score",
    "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8",
    "dscr", "post_loan_emi_ratio", "loan_to_income",
    "payment_streak", "insurance_coverage",
    "savings_buffer_months", "income_growth_slope",
    "w_platform", "w_vendor",
]
```

### LightGBM Config
```python
lgb_params = {
    "objective": "binary",
    "metric": "auc",
    "n_estimators": 200,
    "max_depth": 5,
    "learning_rate": 0.05,
    "num_leaves": 31,
    "subsample": 0.8,
    "colsample_bytree": 0.8,
    "random_state": 42,
}
```

### Output
- `output/models/loan_lgbm.pkl`

---

## Part 3: Threshold Calibrator

### Per (work_type × product) approval thresholds

```python
for product in ['emergency_micro', 'income_bridge', 'growth']:
    for wt in WORK_TYPES:
        mask = (val_df['product_id'] == product) & (val_df['work_type'] == wt)
        subset = val_df[mask]
        probs = loan_model.predict_proba(subset[LOAN_FEATURES])[:, 1]
        
        # Find threshold where FPR ≤ 0.10
        from sklearn.metrics import roc_curve
        fpr, tpr, thresholds = roc_curve(subset['outcome'], probs)
        idx = np.argmax(fpr > 0.10) - 1
        threshold = float(thresholds[max(idx, 0)])
        
        loan_thresholds[product][wt] = round(threshold, 3)
```

### Output: `output/assets/loan_thresholds.json`
```json
{
  "emergency_micro": {
    "platform_worker": 0.42,
    "street_vendor": 0.48,
    "skilled_tradesperson": 0.45,
    "freelancer": 0.40
  },
  "income_bridge": {
    "platform_worker": 0.55,
    "street_vendor": 0.60,
    "skilled_tradesperson": 0.52,
    "freelancer": 0.50
  },
  "growth": {
    "platform_worker": 0.65,
    "street_vendor": 0.70,
    "skilled_tradesperson": 0.62,
    "freelancer": 0.60
  }
}
```

## Execution
```bash
python -m loan.loan_data_generator       # 50K scenarios
python -m loan.loan_lgbm_trainer         # Train LightGBM classifier
python -m loan.threshold_calibrator      # Per-group thresholds
```
