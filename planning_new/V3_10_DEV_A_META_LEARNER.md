# V3.0 Dev A — Meta-Learner Spec (CORRECTED)

## File: `ml_pipeline/training/meta_learner_v3.py`

## Input Vector: 20 Elements (NOT 24)

```python
meta_input = [
    P1, P2, P3, P4, P5, P6, P7, P8,           # 8 calibrated pillar scores
    conf_P1, conf_P2, conf_P3, conf_P4,         # 8 conformal-based confidence values
    conf_P5, conf_P6, conf_P7, conf_P8,         # (from conformal prediction intervals)
    top_cross_1, top_cross_2,                    # 4 most predictive cross-pillar features
    top_cross_3, top_cross_4,                    # (selected during training by importance)
]
```

## Why 20 Inputs (not old 24)
- 8 pillar scores (same concept, now 8 not 7)
- 8 confidence values from conformal prediction (replaces guessed weights)
- 4 cross-pillar features (new — captures global patterns no pillar sees alone)
- No work-type one-hot or interaction terms (that's handled by work-type normalisation in Stage 1)

## Training
```python
from sklearn.linear_model import LogisticRegression

# Select top 4 cross-pillar features by mutual information with target
from sklearn.feature_selection import mutual_info_regression
mi = mutual_info_regression(X_cross_pillar_20, y_target)
top4_indices = np.argsort(mi)[-4:]  # e.g., [102, 105, 95, 110]

# Build meta training set
X_meta = np.column_stack([
    calibrated_pillar_scores,   # 8 columns
    confidence_values,           # 8 columns
    X_cross_pillar_20[:, top4_indices],  # 4 columns
])

lr = LogisticRegression(C=1.0, max_iter=1000, solver='lbfgs', random_state=42)
lr.fit(X_meta, (y_target > 0.5).astype(int))
```

## Coefficient Export: `meta_lr_coefficients.json`
```json
{
  "intercept": -0.312,
  "coefficients": [0.28, 0.22, 0.14, 0.15, 0.12, 0.11, 0.09, 0.08,
                   0.05, 0.04, 0.03, 0.03, 0.02, 0.02, 0.01, 0.01,
                   0.03, 0.02, 0.015, 0.01],
  "input_order": [
    "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8",
    "conf_P1", "conf_P2", "conf_P3", "conf_P4",
    "conf_P5", "conf_P6", "conf_P7", "conf_P8",
    "financial_shock_resistance", "consistent_earning_payment_streak",
    "income_debt_stress_index", "tax_income_consistency_ratio"
  ],
  "top4_cross_pillar_indices": [102, 105, 95, 110],
  "auc_roc": 0.92,
  "accuracy": 0.85
}
```

## Dev B: Dart Implementation
```dart
List<double> buildMetaInput(
  Map<String, double> pillarScores,
  Map<String, double> confidenceValues,
  List<double> features,       // full 115-feature vector
  List<int> top4Indices,       // from JSON
) {
  return [
    pillarScores['P1']!, pillarScores['P2']!, pillarScores['P3']!, pillarScores['P4']!,
    pillarScores['P5']!, pillarScores['P6']!, pillarScores['P7']!, pillarScores['P8']!,
    confidenceValues['P1']!, confidenceValues['P2']!, confidenceValues['P3']!, confidenceValues['P4']!,
    confidenceValues['P5']!, confidenceValues['P6']!, confidenceValues['P7']!, confidenceValues['P8']!,
    features[top4Indices[0]], features[top4Indices[1]],
    features[top4Indices[2]], features[top4Indices[3]],
  ];
}
```

## Pipeline Position
```
STAGE 4: Conformal intervals → confidence values (8)
STAGE 5: Meta-learner(8 pillars + 8 confidence + 4 cross-pillar) → probability
STAGE 6: probability × 600 + 300 → GigCredit score (300–900)
```

## Execution
```bash
python -m training.meta_learner_v3
```
