# V3.0 Dev A — Export Pipeline Spec (CORRECTED)

## Files
- `ml_pipeline/export/export_m2cgen_v3.py` — Generate Dart scorers (3 model types)
- `ml_pipeline/export/constants_exporter.py` — Generate ALL JSON constants
- `ml_pipeline/export/golden_test_v3.py` — Generate golden test profiles

---

## Part 1: m2cgen Export (3 Model Types)

### m2cgen Model Support
| Model | m2cgen Support | Export Function |
|-------|---------------|-----------------|
| LightGBM | ✅ `m2c.export_to_dart()` | Native support |
| XGBoost | ✅ `m2c.export_to_dart()` | Requires `tree_method='exact'` |
| ExtraTrees | ✅ `m2c.export_to_dart()` | sklearn estimator support |

```python
import m2cgen as m2c
import sys
sys.setrecursionlimit(50_000)

MODEL_FILES = {
    'p1': ('p1_lgbm.pkl', 'scoreP1', 17),   # LightGBM, 13 base + 4 cross-pillar
    'p2': ('p2_xgb.pkl', 'scoreP2', 19),     # XGBoost, 15 base + 4 cross-pillar
    'p3': ('p3_xgb_shallow.pkl', 'scoreP3', 13),  # XGBoost shallow, 9 base + 4 cross
    'p4': ('p4_lgbm.pkl', 'scoreP4', 16),    # LightGBM, 12 base + 4 cross-pillar
    'p6': ('p6_et.pkl', 'scoreP6', 14),      # ExtraTrees, 11 base + 3 cross-pillar
}

for pillar, (model_file, func_name, n_features) in MODEL_FILES.items():
    model = joblib.load(f"output/models/{model_file}")
    dart_code = m2c.export_to_dart(model, function_name=func_name)
    
    with open(f"output/dart_export/{pillar}_scorer.dart", "w") as f:
        f.write(f"// AUTO-GENERATED — DO NOT EDIT\n")
        f.write(f"// Model: {model.__class__.__name__} for {pillar.upper()}\n")
        f.write(f"// Input: List<double> of length {n_features}\n")
        f.write(f"// Includes cross-pillar features routed to this pillar\n\n")
        f.write(dart_code)
```

### Scorecard Files (Hand-Written by Dev A)

**scorecard_p7.dart** (10 features):
```dart
// HAND-WRITTEN — Social Accountability scorecard
double scoreP7(List<double> input) {
  const w = [0.15, 0.12, 0.10, 0.10, 0.08, 0.10, 0.08, 0.12, 0.10, 0.05];
  double s = 0.0;
  for (int i = 0; i < 10; i++) s += input[i] * w[i];
  return s.clamp(0.0, 1.0);
}
```

**scorecard_p8.dart** (7 features):
```dart
// HAND-WRITTEN — Tax & Compliance scorecard
double scoreP8(List<double> input) {
  const w = [0.25, 0.15, 0.20, 0.15, 0.10, 0.08, 0.07];
  double s = 0.0;
  for (int i = 0; i < 7; i++) s += input[i] * w[i];
  return s.clamp(0.0, 1.0);
}
```

**scorecard_p5.dart** (18 features, KYC gate):
```dart
double scoreP5(List<double> input) {
  if (input[0] < 0.5 || input[1] < 0.5) return 0.0; // KYC GATE
  const w = [0.15,0.15,0.10,0.08,0.08,0.06,0.05,0.04,0.03,0.06,0.04,0.04,0.02,0.02,0.02,0.03,0.02,0.01];
  double s = 0.0;
  for (int i = 0; i < 18; i++) s += input[i] * w[i];
  return s.clamp(0.0, 1.0);
}
```

**meta_learner_lr.dart** (20 inputs):
```dart
import 'dart:math' as math;

double predictMeta(List<double> input, List<double> coefficients, double intercept) {
  assert(input.length == 20);
  assert(coefficients.length == 20);
  double z = intercept;
  for (int i = 0; i < 20; i++) z += input[i] * coefficients[i];
  return 1.0 / (1.0 + math.exp(-z));
}
```

### Post-Export Validation
```bash
cd ml_pipeline/output/dart_export
dart analyze .  # MUST pass with zero errors/warnings
```

---

## Part 2: Constants Exporter — ALL JSON Files

Dev A generates **12 JSON files** total:

| # | File | Source | Content |
|---|------|--------|---------|
| 1 | `shap_lookup_v3.json` | SHAP extractor | 115 features × 20 bins × 4 work types |
| 2 | `tabnet_attention.json` | Attention proxy | Per-pillar feature attention weights |
| 3 | `calibration_knots.json` | Calibration | Isotonic knots for 5 ML pillars |
| 4 | `conformal_intervals.json` | Calibration | half_width per pillar × work_type |
| 5 | `meta_lr_coefficients.json` | Meta-learner | 20 coefficients + intercept |
| 6 | `pillar_weights.json` | config.py | 8 pillar weights |
| 7 | `actionability_tags.json` | config.py | 🟢🟡🔴 per feature (115 entries) |
| 8 | `feature_display_names.json` | config.py | Human labels (115 entries) |
| 9 | `work_type_medians.json` | Synthetic data | 4 work types × 5 normalisation constants |
| 10 | `causal_chains.json` | Hand-written | 15 causal rule triggers |
| 11 | `loan_thresholds.json` | Loan trainer | Per work_type × product thresholds |
| 12 | `feature_defaults.json` | constants_exporter.py | Training set medians/modes for 95 base features |

### JSON Export Validations (CRITICAL)

Before writing the JSON files, Dev A MUST run these assertions:

**1. Calibration Knot Monotonicity**
```python
# x_knots MUST be strictly increasing for Dart interpolation
assert all(x[i] < x[i+1] for i in range(len(x)-1)), f"Non-monotone knots in {pillar}"
# Keep high precision! Use round(float(val), 6)
```

**2. Causal Rule Schema Validator**
```python
ALLOWED_OPS = {">", "<", ">=", "<="}
for rule in causal_rules:
    assert rule["trigger_logic"] in {"AND", "OR"}
    for trigger in rule["triggers"]:
        assert trigger["operator"] in ALLOWED_OPS, f"Invalid operator: {trigger['operator']}"
```

### actionability_tags.json (3-tier, not just boolean)
```json
{
  "health_insurance_active": {
    "actionable": "immediate",
    "difficulty": "easy",
    "horizon": "1-7 days",
    "expected_gain_pts": 18,
    "action_text": "Upload health insurance document",
    "pillar": "P6",
    "fix_category": "documentation"
  },
  "utility_ontime_ratio": {
    "actionable": "behavioural",
    "difficulty": "medium",
    "horizon": "1-3 months",
    "expected_gain_pts": 12,
    "action_text": "Pay utility bills before due date",
    "pillar": "P2",
    "fix_category": "habit_change"
  },
  "avg_monthly_income_norm": {
    "actionable": "non_actionable",
    "difficulty": "none",
    "horizon": "N/A",
    "expected_gain_pts": 0,
    "action_text": "",
    "pillar": "P1",
    "fix_category": "immutable"
  }
}
```

### causal_chains.json (15 rules)
```json
[
  {
    "id": "high_emi_low_income",
    "trigger_conditions": [
      {"feature": "emi_to_income_ratio", "index": 28, "op": "<", "value": 0.40},
      {"feature": "income_stability_cv", "index": 1, "op": "<", "value": 0.50}
    ],
    "root_cause": "income_seasonality",
    "chain": "Seasonal income drop → difficulty meeting EMI → low debt score",
    "user_message": "Your debt burden is high relative to your volatile income. Stabilising income across months is the root fix.",
    "fix": "Consider multi-platform registration to smooth seasonal dips",
    "applicable_work_types": ["platform_worker", "street_vendor"]
  },
  {
    "id": "low_savings_high_income",
    "trigger_conditions": [
      {"feature": "savings_rate", "index": 37, "op": "<", "value": 0.35},
      {"feature": "avg_monthly_income_norm", "index": 0, "op": ">", "value": 0.60}
    ],
    "root_cause": "spending_pattern",
    "chain": "High income → high discretionary spending → low savings rate",
    "user_message": "You earn well but your savings rate is low. Even ₹500/month auto-debit would significantly improve P4.",
    "fix": "Set up auto-debit SIP or RD of ₹500-₹1000/month",
    "applicable_work_types": ["all"]
  }
]
```

---

## Part 3: Golden Test Generator

### 100 profiles, Python-computed, includes ALL 6 stages

```python
for profile in golden_100:
    features_95 = profile[FEATURE_NAMES_95]
    # STAGE 1: Work-type normalise
    features_95_norm = normalise_by_work_type(features_95, profile.work_type, medians)
    # STAGE 2: Cross-pillar
    features_115 = add_cross_pillar(features_95_norm)
    # STAGE 3: Score pillars (with cross-pillar features routed)
    pillars_raw = score_all_pillars(features_115, models)
    # P5 KYC gate
    if features_115[49] < 0.5 or features_115[50] < 0.5:
        pillars_raw['P5'] = 0.0
    # STAGE 4: Calibrate + conformal
    pillars_cal = calibrate(pillars_raw, cal_knots)
    confidence = compute_conformal_confidence(pillars_cal, profile.work_type, conformal)
    # STAGE 5: Meta-learner
    meta_input = build_meta_input_20(pillars_cal, confidence, features_115, top4_indices)
    probability = predict_meta(meta_input, lr_coeffs, lr_intercept)
    # STAGE 6: Score mapping
    final_score = int(probability * 600 + 300)
```

### golden_100.json Schema
```json
[{
    "id": 0,
    "features_95": [0.45, 0.62, ...],
    "features_115": [0.45, 0.62, ..., 0.33, 0.28, ...],
    "work_type": "platform_worker",
    "expected_pillars_raw": {"P1": 0.72, ...},
    "expected_pillars_calibrated": {"P1": 0.74, ...},
    "expected_confidence": {"P1": 0.92, ...},
    "expected_probability": 0.68,
    "expected_score": 708,
    "expected_grade": "B+"
}]
```

## Execution
```bash
python -m export.export_m2cgen_v3     # Dart scorers
python -m export.constants_exporter    # 11 JSON files
python -m export.golden_test_v3        # golden_100.json
```
