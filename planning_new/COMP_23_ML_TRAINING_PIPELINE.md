# ================================================================================
# GIGCREDIT — COMPONENT: ML TRAINING PIPELINE
# Document 23 | planning_new
# Owner: Dev A
# ================================================================================

## 1. PIPELINE OVERVIEW (OFFLINE — PYTHON)

The ML pipeline runs ONCE on Dev A's laptop. Output = Dart code + JSON configs.

```
Step 1:  Generate synthetic data (15,000 profiles)
Step 2:  Train/validate split (80/20, stratified)
Step 3:  Train P1-P4 (XGBoost) + P6 (RandomForest)
Step 4:  Write P5, P7 scorecards (Dart, deterministic)
Step 5:  Train meta-learner (Logistic Regression)
Step 6:  Generate SHAP lookup table
Step 7:  Export models to Dart via m2cgen
Step 8:  Generate golden inference test data
Step 9:  Copy artifacts to app
```

---

## 2. SYNTHETIC DATA GENERATION

```python
# ml_pipeline/data/synthetic_generator.py

def generate_profile(work_type):
    """Generate one synthetic gig worker profile with 95 features."""
    
    # Base income by work type
    income_base = {
        'platform_worker': random.gauss(18000, 5000),
        'vendor': random.gauss(15000, 4000),
        'tradesperson': random.gauss(20000, 6000),
        'freelancer': random.gauss(25000, 8000),
    }[work_type]
    
    income = max(5000, income_base)
    
    # P1: Income features (correlated)
    p1 = {
        'income_to_anchor_ratio': min(income / 15000, 1.0),
        'income_stability_cv': random.uniform(0.3, 0.95),
        'income_growth_trend': random.uniform(0.2, 0.8),
        # ... 13 features total
    }
    
    # P2-P7: Similar correlated generation
    # Key: features within a pillar should be correlated
    # Bad income → likely bad savings → lower score
    
    # Target: composite credit quality (0-1)
    target = compute_target(p1, p2, p3, p4, p5, p6, p7, work_type)
    
    return {**p1, **p2, **p3, **p4, **p5, **p6, **p7, 
            'work_type': work_type, 'target': target}
```

### Key Requirements:
- 15,000 profiles total (3,750 per work type)
- Features are inter-correlated (realistic)
- Target variable is a composite of all pillars
- Include edge cases: 0 insurance, max debt, etc.

---

## 3. MODEL TRAINING

```python
# ml_pipeline/training/train_pillars.py
import xgboost as xgb
from sklearn.ensemble import RandomForestRegressor

PILLAR_CONFIG = [
    ('p1', range(0, 13), 'xgboost'),
    ('p2', range(13, 28), 'xgboost'),
    ('p3', range(28, 37), 'xgboost'),
    ('p4', range(37, 49), 'xgboost'),
    # P5 (49-66) = scorecard, not trained
    ('p6', range(67, 78), 'random_forest'),
    # P7 (78-94) = scorecard, not trained
]

for name, features, model_type in PILLAR_CONFIG:
    X = df.iloc[:, features]
    y = df[f'{name}_target']
    
    if model_type == 'xgboost':
        model = xgb.XGBRegressor(
            n_estimators=100,
            max_depth=5,
            learning_rate=0.1,
            subsample=0.8,
            colsample_bytree=0.8,
            random_state=42,
        )
    else:
        model = RandomForestRegressor(
            n_estimators=100,
            max_depth=5,
            random_state=42,
        )
    
    model.fit(X_train, y_train)
    
    # Validate
    y_pred = model.predict(X_val)
    rmse = np.sqrt(mean_squared_error(y_val, y_pred))
    print(f'{name} RMSE: {rmse:.4f}')
    
    models[name] = model
```

---

## 4. m2cgen EXPORT

```python
import m2cgen as m2c

for name, model in models.items():
    dart_code = m2c.export_to_dart(model, function_name=f'score{name.title().replace("_", "")}')
    
    # The generated code is a single function:
    # double scoreP1(List<double> input) {
    #   double var0;
    #   if (input[0] >= 0.5) {
    #     if (input[1] >= 0.3) { var0 = 0.72; }
    #     ...
    #   }
    #   return var0;
    # }
    
    with open(f'ml_pipeline/output/dart_exports/{name}_scorer.dart', 'w') as f:
        f.write(dart_code)
```

---

## 5. DEPENDENCIES

```
# ml_pipeline/requirements.txt
numpy>=1.24
pandas>=2.0
scikit-learn>=1.3
xgboost>=2.0
shap>=0.42
m2cgen>=0.10
matplotlib>=3.7  # for validation plots
```

---

## 6. DEMO SIMPLIFICATION

If the full ML pipeline takes too long (>2 hours):

**Shortcut A**: Reduce to 5,000 profiles and 50 trees per model.
**Shortcut B**: Use simpler models (DecisionTree instead of XGBoost).
**Shortcut C**: Hardcode reasonable scorer functions in Dart (no ML training).

```dart
// Emergency fallback: Hardcoded scorer
double scoreP1(List<double> input) {
  double score = 0.0;
  score += input[0] * 0.15; // income_to_anchor_ratio
  score += input[1] * 0.20; // income_stability_cv
  score += input[2] * 0.10; // income_growth_trend
  // ... weighted sum approach
  return score.clamp(0.0, 1.0);
}
```

This produces less accurate but still reasonable scores for demo.
