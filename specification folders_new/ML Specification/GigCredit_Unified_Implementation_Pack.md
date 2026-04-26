# GigCredit Scoring System — Unified Implementation Pack

This document consolidates the full end-to-end scoring system into one implementation-first artifact. It contains the architecture, the data contract, the offline Python pipeline, the on-device Dart runtime, the confidence engine, the calibration layer, the meta-learner, the SHAP explanation strategy, the validation plan, and the production file map.

The goal is simple: a senior engineer should be able to use this single file as the blueprint for implementation without needing to jump between separate documents.

---

## 1. System Objective

Build a **100% on-device** credit scoring engine for Flutter that:

- Runs entirely on the user’s phone.
- Uses offline Python only for training and export.
- Uses pure Dart for runtime scoring.
- Avoids TensorFlow, TFLite, ONNX, and native ML plugins.
- Produces a final score from 300 to 900.
- Gives explainable pillar-level reasons.
- Supports confidence-aware scoring.
- Updates dynamically as the user completes more onboarding steps.
- Remains deterministic and parity-tested.

This architecture is intentionally optimized for deployability and reliability, not just offline benchmark accuracy [file:645][web:650].

---

## 2. Final Architecture

### 2.1 Offline vs On-device split

**Offline Python responsibilities:**

- Synthetic data generation.
- Feature schema validation.
- Model training for ML pillars.
- Hyperparameter tuning.
- Calibration fitting.
- Meta-learner training.
- SHAP extraction and binning.
- Dart code export.
- Python vs Dart parity validation.

**On-device Flutter/Dart responsibilities:**

- User profile collection.
- Feature engineering.
- Feature sanitization.
- ML pillar inference.
- Scorecard pillar inference.
- Confidence adjustment.
- Meta-learner inference.
- SHAP explanation lookup.
- ScoreReport generation.

### 2.2 End-to-end flow

```text
User input + OCR + verification
        |
        v
95-feature engineering
        |
        v
Feature sanitization
        |
        +------------------------------+
        |                              |
        v                              v
ML pillars P1,P2,P3,P4,P6        Rule pillars P5,P7,P8
(m2cgen Dart scorers)            (native Dart scorecards)
        |                              |
        +--------------+---------------+
                       v
              Pillar validation
                       |
                       v
             Confidence engine
                       |
                       v
          Calibration + adjustment
                       |
                       v
              Logistic meta-learner
                       |
                       v
           Final score 300–900
                       |
                       v
        SHAP-derived explanations
                       |
                       v
                 ScoreReport
```

### 2.3 Why this architecture

This architecture is the best fit because it removes fragile runtime conversion layers and keeps the scoring logic deterministic. The earlier TensorFlow/TFLite approach failed because deployment fragility was too high and parity was too hard to maintain [file:642][file:645].

---

## 3. Feature Schema

### 3.1 Total feature count

The system uses **95 engineered features**.

### 3.2 Pillar allocation

| Pillar | Name | Feature range | Count | Type |
|---|---|---:|---:|---|
| P1 | Income Stability | 0–12 | 13 | ML |
| P2 | Payment Discipline | 13–27 | 15 | ML |
| P3 | Debt Management | 28–36 | 9 | ML |
| P4 | Savings Behaviour | 37–48 | 12 | ML |
| P5 | Work Identity | 49–66 | 18 | Scorecard |
| P6 | Financial Resilience | 67–77 | 11 | ML |
| P7 | Social Accountability | 78–87 | 10 | Scorecard |
| P8 | Tax Compliance | 88–94 | 7 | Scorecard |

### 3.3 Normalization rules

- Ratios: clamp to `[0, 1]`.
- Income: normalize by state or city income anchor.
- Counts: clamp to a safe range, usually `[0, 10]` or similar.
- Missing values: replace with domain-specific fallback.
- NaN or infinity: replace with `0.50` at runtime.

### 3.4 Feature contract rules

The feature engineering code in Python and Dart must be **identical in logic**. If the training features and runtime features differ, the scoring system will fail even if the models are good [file:642][file:645].

---

## 4. Offline Training Pipeline

### 4.1 Dataset generation

Generate **15,000 synthetic profiles** with stratification across:

- Work type.
- Credit tier.
- Income stability.
- Debt burden.
- Savings behavior.
- Verification completeness.

Suggested work-type distribution:

- Platform workers: 35%
- Vendors: 25%
- Tradespeople: 25%
- Freelancers: 15%

Suggested tier distribution:

- Excellent: 15%
- Good: 25%
- Average: 30%
- Poor: 20%
- Very Poor: 10%

### 4.2 Synthetic feature distributions

Use realistic distributions:

- Income-like variables: LogNormal.
- Ratios: Beta.
- Binary flags: Bernoulli.
- Temporal variability: AR(1)-style process.
- Count-like values: Poisson or clipped discrete draws.

### 4.3 Train/validation split

- 80% training.
- 20% validation.
- Stratify by work type and credit tier.

### 4.4 Model training sequence

1. Generate data.
2. Validate schema.
3. Split train/validation.
4. Tune hyperparameters with Optuna.
5. Train final pillar models.
6. Validate metrics.
7. Extract SHAP.
8. Build meta-learner.
9. Export to Dart.
10. Run parity validation.

---

## 5. ML Pillar Models

### 5.1 Recommended final model choices

| Pillar | Model | Why it fits |
|---|---|---|
| P1 | XGBoost Regressor | Nonlinear income stability patterns |
| P2 | XGBoost Regressor | Payment punctuality and behavior thresholds |
| P3 | XGBoost Regressor | Debt burden and EMI ratio nonlinearities |
| P4 | XGBoost Regressor | Savings trend and balance shifts |
| P6 | RandomForest Regressor | Sparse binary resilience flags |

### 5.2 Why not use separate “optimal” libraries

Do not mix CatBoost, LightGBM, TensorFlow, ONNX, and multiple deployment runtimes just to chase a small accuracy increase. That creates integration risk, code bloat, and output mismatch. A slightly less “optimal” model that exports perfectly is better than a more accurate model that fails on-device [file:645][web:650].

### 5.3 Hyperparameter search space

#### XGBoost

- `n_estimators`: 80–150
- `max_depth`: 3–4
- `learning_rate`: 0.01–0.3
- `subsample`: 0.6–1.0
- `colsample_bytree`: 0.5–1.0
- `gamma`: 0.0–1.0
- `min_child_weight`: 5–30
- `reg_alpha`: 0.0–0.5
- `reg_lambda`: 0.0–0.5
- `tree_method`: `exact`

#### RandomForest

- `n_estimators`: 80–150
- `max_depth`: 3–4
- `min_samples_split`: 5–30
- `min_samples_leaf`: 5–20
- `max_features`: `sqrt`, `log2`, `0.7`, `0.8`

### 5.4 Validation targets

- P1 RMSE ≤ 0.08
- P2 RMSE ≤ 0.08
- P3 RMSE ≤ 0.10
- P4 RMSE ≤ 0.08
- P6 RMSE ≤ 0.10

If a target is missed, first inspect data quality and calibration before increasing model complexity.

---

## 6. Rule-Based Pillars

### 6.1 P5 Work Identity

This pillar should remain a deterministic scorecard. It can include:

- Aadhaar verification.
- PAN verification.
- Face match.
- Work proof.
- Address consistency.
- Screenshot or platform evidence.
- Identity trust features.

### 6.2 P7 Social Accountability

This pillar should score:

- e-Shram registration.
- Scheme participation.
- Government welfare evidence.
- Formal worker registration.

### 6.3 P8 Tax Compliance

This pillar should score:

- ITR filing.
- Number of years filed.
- Declared income consistency.
- GST registration when relevant.

These three pillars are better as rules because they are governance-sensitive and easier to explain when deterministic.

---

## 7. Calibration Layer

### 7.1 Why calibration is needed

Raw tree model outputs are often good for ranking but not perfectly aligned as probabilities. Calibration improves consistency before the meta-learner sees the pillars.

### 7.2 Recommended approach

- Use **isotonic regression** for well-supported pillars.
- Use **sigmoid / Platt-like calibration** if the pillar is noisy or has less support.

### 7.3 Calibration flow

1. Train raw pillar model.
2. Generate out-of-fold predictions.
3. Fit calibration mapping.
4. Export calibration lookup or function.
5. Apply calibration at runtime.

---

## 8. Confidence Engine

### 8.1 Confidence components

Each pillar confidence should combine:

- **Completeness**: how much required evidence exists.
- **Reliability**: how trustworthy the input source is.
- **Consistency**: how well the sources agree.

### 8.2 Confidence formula

```text
confidence = 0.5 * completeness + 0.3 * reliability + 0.2 * consistency
```

### 8.3 Confidence adjustment

```text
if confidence < 0.30:
    pillar_score = 0.50
    pillar_status = neutral_excluded
else:
    adjusted_score = calibrated_score * confidence + 0.50 * (1 - confidence)
```

This makes the score resilient to partial or weak evidence without pretending uncertainty is certainty.

### 8.4 Minimum data gate

Do not produce a meaningful score unless minimum data requirements are met. At minimum, the system should require:

- Step 1 identity collection.
- Step 2 identity verification.
- Step 3 bank statement with a minimum transaction threshold.

If this is not met, return an insufficient-data state instead of a misleading numeric score.

---

## 9. Meta-Learner

### 9.1 Input vector

The meta-learner takes **20 inputs**:

- 8 pillar scores.
- 4 work-type one-hot flags.
- 8 interaction terms for P1 and P2 with work type.

### 9.2 Why logistic regression

Logistic regression is the most suitable final combiner because it is:

- interpretable,
- easy to export to Dart,
- deterministic,
- small,
- stable on mobile,
- easier to audit than a second tree ensemble.

### 9.3 Final score mapping

```text
probability = sigmoid(dot(meta_features, coefficients) + intercept)
final_score = round(probability * 600 + 300)
```

### 9.4 Grade mapping

| Score | Grade | Risk Band |
|---|---|---|
| 800–900 | S | Exceptional |
| 720–799 | A | Excellent |
| 640–719 | B | Good |
| 560–639 | C | Average |
| 480–559 | D | Below Average |
| 300–479 | E | Poor |

---

## 10. SHAP Explainability

### 10.1 Purpose

SHAP must be used only for explanation. It must not affect the score.

### 10.2 Offline extraction

For each ML pillar:

1. Compute SHAP values.
2. Bin feature values into percentiles.
3. Store average SHAP impact per bin.
4. Export the lookup table.

### 10.3 On-device explanation

At runtime:

- Map each feature to a bin.
- Look up the impact value.
- Rank all impacts.
- Select top positive and negative reasons.

### 10.4 Explanation output

For each report, emit:

- Top 3 strengths.
- Top 3 weaknesses.
- Pillar-wise explanation snippets.
- Plain-language improvement suggestions.

This approach is fast enough for mobile and still useful for user-facing reports [file:645][web:654][web:657].

---

## 11. Runtime Workflow in Dart

### 11.1 Inference order

1. Collect profile.
2. Build 95 features.
3. Sanitize features.
4. Run P1, P2, P3, P4, P6.
5. Run P5, P7, P8 scorecards.
6. Validate outputs.
7. Apply hard business rules.
8. Compute confidence.
9. Apply calibration.
10. Build meta-features.
11. Run meta-learner.
12. Convert to final score.
13. Generate explanation data.
14. Create ScoreReport.

### 11.2 Feature sanitization

- NaN → 0.50.
- Infinity → 0.50.
- Out-of-range → clamp.

### 11.3 Output validation

After each pillar:

- If NaN or infinity, replace with 0.50.
- If outside range, clamp.
- Log the issue.
- Continue safely.

### 11.4 Execution strategy

Run sequentially on the main thread unless profiling proves a real need for isolates. Pure Dart arithmetic is fast enough for this design [file:645].

---

## 12. Production File Map

### 12.1 Python offline files

```text
feature_schema.json
feature_engineering.py
train_pillars.py
train_meta.py
export_dart.py
parity_test.py
golden_test.json
```

### 12.2 Dart runtime files

```text
confidence_engine.dart
scoring_engine.dart
feature_engineering.dart
feature_sanitizer.dart
pillar_validator.dart
calibration.dart
metalearner.dart
shap_lookup.dart
scorecard_p5.dart
scorecard_p7.dart
scorecard_p8.dart
p1_scorer.dart
p2_scorer.dart
p3_scorer.dart
p4_scorer.dart
p6_scorer.dart
report_generator.dart
scoring_constants.dart
```

### 12.3 Asset files

```text
assets/constants/shap_lookup.json
assets/constants/meta_coefficients.json
assets/constants/feature_means.json
assets/constants/state_income_anchors.json
```

---

## 13. Suggested Artifact Roles

### 13.1 `feature_schema.json`

Defines the 95-feature contract, pillar ranges, and sanitization expectations.

### 13.2 `feature_engineering.py`

Generates the training-time features from synthetic or real data.

### 13.3 `train_pillars.py`

Tunes and trains pillar models.

### 13.4 `train_meta.py`

Trains the logistic meta-learner on out-of-fold pillar predictions.

### 13.5 `export_dart.py`

Exports ML pillar models and constants into Dart source.

### 13.6 `confidence_engine.dart`

Computes pillar confidence and neutralization behavior.

### 13.7 `scoring_engine.dart`

Orchestrates the full runtime scoring flow.

### 13.8 `golden_test.json`

Fixed parity test cases.

### 13.9 `parity_test.py`

Compares Python and Dart outputs.

### 13.10 `report_generator.dart`

Builds the final report and explanation output.

---

## 14. Validation Strategy

### 14.1 Golden parity test

For each fixed profile:

- Run Python inference.
- Run Dart inference.
- Compare outputs.
- Require max difference ≤ 1e-5.

### 14.2 Unit tests

Test:

- normalization,
- sanitization,
- scorecards,
- confidence logic,
- meta-learner mapping,
- score grade mapping,
- explanation selection,
- missing-data handling.

### 14.3 Integration tests

Test the full chain:

profile → features → pillars → confidence → meta-score → report.

### 14.4 Stability tests

Add tests for:

- partial data,
- invalid OCR,
- low-confidence steps,
- missing source documents,
- repeated scoring after onboarding progress.

---

## 15. Failure Modes and Countermeasures

| Failure mode | Cause | Countermeasure |
|---|---|---|
| TensorFlow/TFLite mismatch | Conversion drift | Use pure Dart export |
| Model fragmentation | Too many model types | Standardize on XGBoost + RF + scorecards |
| Weak confidence semantics | Low-data overconfidence | Add completeness/reliability/consistency |
| Meta-learner leakage | In-sample training | Use out-of-fold predictions |
| SHAP runtime cost | Too heavy for mobile | Use offline bins + lookup |
| Feature drift | Python and Dart mismatch | Golden tests and shared schema |

---

## 16. Security and Privacy

Since scoring is on-device, the main security risk is user data exposure, not model theft.

### 16.1 Use Keystore for session data

Use Android Keystore to encrypt stored profile/session data.

### 16.2 Remove obsolete model encryption

Do not use encrypted model files or model decryption at runtime.

### 16.3 Cleanup policy

After scoring, delete temporary OCR artifacts, parsed CSVs, and intermediate feature vectors where possible.

---

## 17. Build Order

1. Freeze schema.
2. Build synthetic data generator.
3. Build training feature pipeline.
4. Train pillar models.
5. Add calibration.
6. Train meta-learner.
7. Export Dart scorers.
8. Build runtime feature engine.
9. Implement confidence engine.
10. Implement SHAP lookup.
11. Implement report generator.
12. Run parity tests.
13. Run integration tests.
14. Optimize.
15. Ship.

---

## 18. Practical Implementation Notes

- Keep every formula deterministic.
- Keep every runtime path testable.
- Avoid hidden heuristics.
- Prefer clarity over cleverness.
- Never change feature definitions without retraining.
- Never ship without parity validation.

---

## 19. Final Recommendation

This unified architecture is already strong enough to start implementation. The remaining work is implementation discipline: keep the schema frozen, keep runtime logic aligned, and validate every exported artifact against Python before merging.

If you want the next step, the best deliverable is a **single implementation backlog** with ticket-style tasks for each file in this document.
