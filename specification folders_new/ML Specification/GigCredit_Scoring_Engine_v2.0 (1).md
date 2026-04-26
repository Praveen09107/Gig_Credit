# GigCredit On-Device Scoring Engine v2.0 — Production Implementation

## Executive Summary

This document defines the full end-to-end architecture for a **100% on-device** credit scoring system for Flutter. It is designed to be practical to implement, deterministic, testable, explainable, and fast enough for mobile execution without TensorFlow, TFLite, ONNX, or native ML runtime dependencies. The system uses offline Python training, m2cgen-generated Dart inference for the learned pillars, deterministic Dart scorecards for rule-based pillars, a calibrated logistic meta-learner, confidence adjustment, SHAP-derived explanations, and a golden parity test suite.

The final system is built around one principle: **deployability first, model purity second**. That means every component must survive device deployment, reproduce outputs exactly, and be understandable during review and debugging [file:645][file:630].

---

## 1. System Goals

The architecture must satisfy the following constraints:

1. Run fully on the user’s device.
2. Avoid any runtime ML interpreter.
3. Produce exactly reproducible scores for the same input.
4. Support offline operation.
5. Be explainable enough for lenders and users.
6. Allow dynamic score updates as the user completes more onboarding steps.
7. Keep the scoring pipeline small enough for mobile compilation.
8. Preserve parity between Python training and Dart inference.
9. Separate score logic from report generation.
10. Fail safely when data is incomplete or corrupted.

This system is not trying to optimize benchmark numbers in isolation. It is trying to optimize the full production path: data collection, feature engineering, model inference, calibration, confidence handling, explanation generation, and mobile deployment [file:645][web:650].

---

## 2. Recommended Final Architecture

### 2.1 High-level Flow

The cleanest architecture is:

- Offline Python pipeline trains all models.
- Python exports the learned scorers into Dart source files.
- Flutter app computes all 95 features locally.
- Dart scorers compute pillar outputs.
- Confidence engine adjusts pillar reliability.
- Meta-learner combines pillars into final score.
- SHAP lookup tables generate explanations.
- ScoreReport is saved locally and optionally sent to backend for reporting.

This is the architecture that best matches your constraints because it eliminates the fragile model conversion chain that caused the earlier failures [file:645][file:642].

### 2.2 Component Diagram

```text
[User Inputs / OCR / Verification]
            |
            v
[Feature Engineering: 95 features]
            |
            v
[Sanitization + Missingness Handling]
            |
            +------------------------------+
            |                              |
            v                              v
[ML Pillars P1,P2,P3,P4,P6]        [Rule Pillars P5,P7,P8]
[m2cgen Dart scorers]              [Deterministic Dart scorecards]
            |                              |
            +--------------+---------------+
                           v
               [Pillar Validation Layer]
                           |
                           v
                [Confidence Engine]
                           |
                           v
          [Calibration + Confidence Adjustment]
                           |
                           v
                [Meta-Learner Logistic Model]
                           |
                           v
         [Final Score 300-900 + Grade + Band]
                           |
                           v
           [SHAP Explanation / Reason Builder]
                           |
                           v
                    [ScoreReport]
```

---

## 3. Pillar Strategy

The best architecture is not “best model per pillar at any cost.” The best architecture is the one with the highest production reliability. For your use case, the pillar design should be split as follows:

| Pillar | Type | Suggested Model | Reason |
|---|---|---|---|
| P1 Income Stability | ML | XGBoost Regressor | Strong on tabular numeric features, easy to export |
| P2 Payment Discipline | ML | XGBoost Regressor | Handles mixed numeric/ratio patterns well |
| P3 Debt Management | ML | XGBoost Regressor | Good for nonlinear debt thresholds |
| P4 Savings Behaviour | ML | XGBoost Regressor | Captures balance progression and ratio interactions |
| P5 Work Identity | Rule | Dart scorecard | Better as deterministic verification logic |
| P6 Financial Resilience | ML | RandomForest Regressor | Good for sparse binary flags and interactions |
| P7 Social Accountability | Rule | Dart scorecard | Best implemented as weighted indicators |
| P8 Tax Compliance | Rule | Dart scorecard | Deterministic, interpretable, low variance |

This is the most honest design because it uses ML where the signal is continuous and nonlinear, and uses rules where the signal is mostly binary and governance-sensitive [file:645].

### 3.1 Why not “optimal model per pillar”

Using different libraries for each pillar looks attractive in research, but it is a deployment trap. CatBoost, LightGBM, TensorFlow, and ONNX all add conversion and parity risk. For mobile deployment, the practical loss in accuracy is usually much smaller than the loss in reliability from a fragmented stack [file:645][web:650].

If a pillar model cannot be exported, validated, and compiled safely, it is not optimal for your product even if it is slightly better on paper.

---

## 4. Offline Training Pipeline

### 4.1 Synthetic Dataset Generation

The training dataset should contain 15,000 profiles. Each profile must include:

- work type,
- 95 engineered features,
- final creditworthiness label,
- pillar labels for P1, P2, P3, P4, P6.

The dataset should be stratified across work type and credit tier so that all important combinations are represented.

#### Suggested distribution

- Platform workers: 35%
- Vendors: 25%
- Tradespeople: 25%
- Freelancers: 15%

#### Tier distribution within each work type

- Excellent: 15%
- Good: 25%
- Average: 30%
- Poor: 20%
- Very Poor: 10%

This prevents one work type from dominating training and keeps the final meta-learner more robust [file:645].

### 4.2 Feature Source Design

The 95 features should be grouped into pillars as follows:

- P1 Income Stability: 13 features
- P2 Payment Discipline: 15 features
- P3 Debt Management: 9 features
- P4 Savings Behaviour: 12 features
- P5 Work Identity: 18 features
- P6 Financial Resilience: 11 features
- P7 Social Accountability: 10 features
- P8 Tax Compliance: 7 features

The feature engineering code used in training must exactly match the on-device feature engineering code. If they differ, the whole architecture fails because the model will see different values during training and inference [file:642][file:645].

### 4.3 Recommended Feature Distributions

Use realistic distributions rather than uniform random noise:

- Income-like values: LogNormal.
- Ratios: Beta distribution.
- Time-series stability: AR(1) or similar autocorrelated process.
- Binary flags: Bernoulli.
- Counts: Poisson or clipped discrete distributions.

This helps the model learn the kind of patterns actually found in gig worker financial data. Synthetic data should not merely be statistically valid; it should be behaviorally plausible.

---

## 5. Training Procedure

### 5.1 Model Training Order

Train the models in this order:

1. Generate synthetic data.
2. Clean and normalize the dataset.
3. Split into train/validation sets.
4. Run Optuna hyperparameter tuning.
5. Train final pillar models.
6. Evaluate validation metrics.
7. Extract SHAP values.
8. Train the meta-learner with out-of-fold predictions.
9. Export scorers to Dart.
10. Validate Python vs Dart parity.

### 5.2 Hyperparameter Search

The search space should stay small enough to keep export manageable. For m2cgen compatibility, favor shallow trees with limited ensemble size.

#### XGBoost search space

- n_estimators: 80 to 150
- max_depth: 3 to 4
- learning_rate: 0.01 to 0.3
- subsample: 0.6 to 1.0
- colsample_bytree: 0.5 to 1.0
- gamma: 0.0 to 1.0
- min_child_weight: 5 to 30
- reg_alpha: 0.0 to 0.5
- reg_lambda: 0.0 to 0.5
- tree_method: exact

#### RandomForest search space

- n_estimators: 80 to 150
- max_depth: 3 to 4
- min_samples_split: 5 to 30
- min_samples_leaf: 5 to 20
- max_features: sqrt, log2, 0.7, 0.8

The reason for depth limits is simple: deeper trees produce much larger Dart code and increase the chance of export errors or runtime mismatch. The goal is not the largest model; the goal is the most stable mobile model [file:645].

### 5.3 Validation Targets

Suggested validation targets:

- P1 RMSE <= 0.08
- P2 RMSE <= 0.08
- P3 RMSE <= 0.10
- P4 RMSE <= 0.08
- P6 RMSE <= 0.10

If a pillar exceeds its target, do not immediately add complexity. First check synthetic data quality, label noise, feature leakage, and whether the validation split is representative.

---

## 6. Pillar Model Details

### 6.1 P1 Income Stability

This pillar should capture:

- income level,
- month-to-month volatility,
- growth slope,
- number of active earning months,
- balance consistency,
- state or city income anchor normalization.

XGBoost is a good fit because income stability is nonlinear and threshold-heavy. For example, a user moving from unstable to stable income may look much better once the volatility ratio crosses a certain boundary.

### 6.2 P2 Payment Discipline

This pillar should capture:

- utility bill punctuality,
- EMI punctuality,
- recurring payment completion,
- P2P transfer regularity,
- bounce behavior,
- late fee patterns.

This pillar often benefits from tree splits around punctuality ratios and missed-payment counts, so XGBoost is again a strong fit.

### 6.3 P3 Debt Management

This pillar should capture:

- EMI-to-income ratio,
- debt count,
- outstanding debt load,
- repeated EMI stacking,
- debt band logic.

This is the most threshold-sensitive pillar. It should also have hard rule overrides, such as capping the score when EMI burden is too high.

### 6.4 P4 Savings Behaviour

This pillar should capture:

- average savings balance,
- surplus ratio,
- month-over-month savings trend,
- end-of-month balance stability,
- withdrawal pattern regularity.

It tends to work best with nonlinear trees because savings behavior is often not linear over income.

### 6.5 P6 Financial Resilience

This pillar should capture:

- insurance participation,
- emergency fund indicators,
- medical insurance presence,
- household buffer behavior,
- repayment resilience signals.

RandomForest is a defensible choice here because many features are binary or sparse, and RF handles a combination of weak signals reasonably well without overfitting as aggressively as boosted trees.

---

## 7. Scorecards for Rule Pillars

### 7.1 P5 Work Identity

P5 should be a deterministic weighted scorecard, not an ML model. It should include:

- Aadhaar verification,
- PAN verification,
- face verification,
- document consistency,
- workproof presence,
- platform screenshots,
- experience indicators.

The reason to keep P5 rule-based is governance. Identity features should be explainable and auditable, not hidden inside a tree ensemble.

### 7.2 P7 Social Accountability

P7 should evaluate government scheme participation and civic profile indicators, such as:

- e-Shram enrollment,
- welfare scheme presence,
- formal registration evidence,
- subsidy or scheme consistency.

This pillar is best represented with explicit weights and deterministic scoring.

### 7.3 P8 Tax Compliance

P8 should score:

- ITR filing status,
- years filed,
- consistency of declared income,
- GST registration if applicable,
- tax documentation availability.

This pillar should remain simple, because tax compliance logic is easier to maintain when it is explicit rather than learned.

---

## 8. Calibration Layer

Calibration is important because raw tree outputs are usually good at ranking but not perfectly aligned as probabilities.

### 8.1 Recommended calibration flow

For each ML pillar:

1. Train the raw model.
2. Collect out-of-fold predictions.
3. Fit a calibration mapping.
4. Export the mapping as a small lookup table or calibration function.
5. Apply the calibration on device before confidence adjustment.

### 8.2 Calibration recommendation

- Use isotonic calibration for pillars with enough data and stable validation curves.
- Use sigmoid / Platt-like calibration if isotonic overfits or the pillar is noisy.

This hybrid approach is safer than forcing the same calibrator onto every pillar.

### 8.3 Why calibration matters

Without calibration, the meta-learner receives pillar scores that may be well-ranked but not meaningfully comparable. Calibration makes the pillar scores more consistent and improves the final score’s stability.

---

## 9. Confidence Engine

The confidence engine should not be a cosmetic multiplier. It should be a formal reliability model.

### 9.1 Confidence dimensions

Each pillar confidence should have three subcomponents:

- Completeness: how much required data exists.
- Reliability: how trustworthy the source is.
- Applicability: whether the pillar should be meaningfully scored at all.

### 9.2 Confidence formula

A practical formulation:

```text
confidence = 0.50*completeness + 0.30*reliability + 0.20*consistency
```

Then:

```text
if confidence < 0.30:
    pillar_score = 0.50
    pillar_status = "neutral_excluded"
else:
    adjusted_score = calibrated_score * confidence + 0.50 * (1 - confidence)
```

This keeps weak evidence from overstating certainty while still allowing partial scoring.

### 9.3 Minimum data gate

Do not compute a meaningful final score until minimum data requirements are met. For example:

- Step 1 identity collection completed,
- Step 2 verification completed,
- Step 3 bank statement with at least 30 transactions completed.

If minimum data is not available, return an explicit insufficient-data state instead of producing a fake-looking number.

---

## 10. Meta-Learner Design

### 10.1 Input Layout

The meta-learner should take 20 inputs:

- 8 pillar scores,
- 4 work-type one-hot flags,
- 8 interaction terms for P1 and P2 with work type.

The reason to include only P1 and P2 interactions is that they contribute the most overall signal. Expanding interactions for all 8 pillars would create too many features relative to the available sample size.

### 10.2 Why logistic regression

A logistic regression meta-learner is the right choice because:

- it is interpretable,
- it is easy to export to Dart,
- it is stable on mobile,
- it allows direct probability-to-score mapping,
- it is much less fragile than a second tree ensemble.

### 10.3 Final score mapping

The meta-learner should output a probability in [0, 1]. Then map it to the CIBIL-like range:

```text
final_score = round(probability * 600 + 300)
```

This yields a score between 300 and 900.

### 10.4 Grade mapping

| Score | Grade | Risk Band |
|---|---|---|
| 800-900 | S | Exceptional |
| 720-799 | A | Excellent |
| 640-719 | B | Good |
| 560-639 | C | Average |
| 480-559 | D | Below Average |
| 300-479 | E | Poor |

The final score and grade should be deterministic for the same inputs.

---

## 11. SHAP Explainability

### 11.1 Purpose

SHAP should only be used for explanation. It should never affect score computation.

### 11.2 Offline extraction

For each ML pillar model:

1. Compute SHAP values on training or validation data.
2. Aggregate each feature into value bins.
3. Store average SHAP contribution per bin.
4. Export the lookup tables as JSON.

### 11.3 On-device explanation

On device, the app should not compute full SHAP. Instead it should:

- bin the feature value,
- look up the precomputed SHAP impact,
- rank the impacts by absolute magnitude,
- generate top positive and negative reasons.

### 11.4 Explanation output structure

For each report:

- Top 3 strengths,
- Top 3 weaknesses,
- Pillar-level reasons,
- Human-readable suggestion text.

This is much more practical than trying to render mathematically exact SHAP values on mobile.

---

## 12. On-Device Runtime Pipeline

### 12.1 Inference Steps

At runtime, scoring should happen in this exact order:

1. Collect user profile data.
2. Build the 95-feature vector.
3. Sanitize features.
4. Compute P1-P8 pillar scores.
5. Validate pillar outputs.
6. Apply hard rules and caps.
7. Compute confidence per pillar.
8. Apply calibration and confidence adjustment.
9. Build meta-features.
10. Run logistic meta-learner.
11. Convert probability to final score.
12. Generate explanations.
13. Save and display ScoreReport.

### 12.2 Feature Sanitization

Every feature should pass through a strict guard:

- NaN → 0.50
- Infinity → 0.50
- Out of range → clamp to valid bounds

This matters because generated Dart code will not behave safely if NaN values are allowed to flow into tree arithmetic.

### 12.3 Pillar Validation

After each pillar prediction:

- if NaN or Inf, replace with 0.50,
- if outside [0, 1], clamp,
- log the anomaly,
- continue instead of crashing.

### 12.4 Sequential Execution

Run sequentially on the main thread. Do not use isolates unless profiling proves a real need. For this architecture, the inference time is already small enough that isolate overhead is usually unnecessary.

---

## 13. Dart Project Structure

```text
lib/scoring/
├── scoring_engine.dart
├── feature_engineering.dart
├── feature_sanitizer.dart
├── pillar_validator.dart
├── confidence_engine.dart
├── calibration.dart
├── metalearner.dart
├── shap_lookup.dart
├── scorecard_p5.dart
├── scorecard_p7.dart
├── scorecard_p8.dart
├── p1_scorer.dart
├── p2_scorer.dart
├── p3_scorer.dart
├── p4_scorer.dart
├── p6_scorer.dart
└── scoring_constants.dart

assets/constants/
├── shap_lookup.json
├── meta_coefficients.json
├── feature_means.json
└── state_income_anchors.json
```

### 13.1 What each file does

- `feature_engineering.dart`: builds the 95 features.
- `feature_sanitizer.dart`: handles NaN/Inf/bounds.
- `pillar_validator.dart`: checks all raw outputs.
- `confidence_engine.dart`: computes reliability scores.
- `calibration.dart`: applies calibration lookup.
- `metalearner.dart`: computes final probability and score.
- `shap_lookup.dart`: returns explanation impacts.
- `p1_scorer.dart` etc.: m2cgen-generated scorers.

---

## 14. Validation and Testing

### 14.1 Golden Parity Test

Create a fixed set of 100 complete profiles. For each profile:

- compute Python output,
- compute Dart output,
- compare scores,
- assert max difference <= 1e-5.

This is the most important test in the entire system.

### 14.2 Unit Tests

At minimum, test:

- feature normalization,
- transaction tagging,
- scorecard outputs,
- confidence edge cases,
- NaN sanitizer,
- meta-learner probability mapping,
- grade assignment,
- risk band mapping.

### 14.3 Integration Tests

Test the full flow:

- profile input → feature vector → pillar scores → final score → report.

### 14.4 Stability Tests

Add tests for:

- missing documents,
- partial onboarding,
- low-confidence pillars,
- out-of-range values,
- repeated scoring across sessions.

---

## 15. Security and Privacy

Because scoring runs on-device, the main security task is not model encryption; it is user data protection.

### 15.1 Recommended security measures

- Encrypt session data using Android Keystore.
- Store only the minimum necessary profile state.
- Clear temporary OCR and parsing artifacts after scoring.
- Add root/debug detection if needed.
- Verify app signature to reduce tampering risk.

### 15.2 What is no longer needed

- TFLite model encryption.
- Model decryption logic.
- Model file integrity checks for `.tflite` files.
- Runtime model loading pools.

These are obsolete in a pure Dart scoring design.

---

## 16. Dynamic Scoring Behavior

The score should evolve as the user progresses through onboarding.

Example behavior:

- After early steps, only a subset of pillars has real data.
- Missing pillars get low confidence and neutralized scores.
- As more documents are added, pillar confidence improves.
- Final score becomes more stable and informative.

This is a product advantage, not just a technical feature. It gives users immediate feedback and encourages completion.

---

## 17. Common Failure Modes and Fixes

### Failure 1: TensorFlow conversion mismatch

**Cause:** model conversion chain changes numerical behavior.

**Fix:** use direct Dart export and validate parity.

### Failure 2: Overly complex pillar stack

**Cause:** too many different model libraries.

**Fix:** standardize on XGBoost + RF + scorecards.

### Failure 3: Weak confidence semantics

**Cause:** low-data pillars still produce overconfident scores.

**Fix:** split confidence into completeness, reliability, applicability.

### Failure 4: Unstable explanations

**Cause:** exact SHAP too heavy for mobile.

**Fix:** use offline SHAP bins and runtime lookup.

### Failure 5: Meta-learner leakage

**Cause:** training meta-LR on in-sample pillar outputs.

**Fix:** use out-of-fold predictions only.

---

## 18. Final Recommended Build Order

1. Freeze the 95-feature schema.
2. Implement offline synthetic data generation.
3. Implement training-time feature pipeline.
4. Train P1, P2, P3, P4 with XGBoost.
5. Train P6 with RandomForest.
6. Implement P5, P7, P8 scorecards.
7. Add calibration per pillar.
8. Train logistic meta-learner with OOF predictions.
9. Generate SHAP lookup tables.
10. Export scorers to Dart.
11. Implement feature sanitization and validation.
12. Build confidence engine.
13. Implement final scoring flow.
14. Add golden parity tests.
15. Ship only after every parity test passes.

---

## 19. Most Honest Technical Verdict

This architecture is already close to the best feasible version for your use case. The strongest improvement is not to add more model variety; it is to make the stack more predictable, calibratable, and verifiable.

The most important choices are:

- keep inference on-device,
- use exportable tree models,
- keep rule pillars deterministic,
- calibrate before combining,
- use confidence carefully,
- validate every output against Python.

If these rules are followed, the system is implementable and defensible.

If they are not followed, the scoring engine becomes a demo that fails in production.

---

## 20. Implementation Notes for Engineering Team

- Do not let feature engineering drift between Python and Dart.
- Do not add a second runtime unless a profiler proves a hard need.
- Do not use “optimal model per pillar” if that breaks parity.
- Do not compute SHAP live on mobile.
- Do not use weighted sum as final score unless there is no meta-learner.
- Do not silently score with missing minimum data.
- Do not ship without a golden test.

These are not suggestions. These are the rules that prevent the previous failure mode.

---

## 21. Suggested Next Engineering Deliverables

1. `feature_schema.json`
2. `feature_engineering.py`
3. `train_pillars.py`
4. `train_meta.py`
5. `export_dart.py`
6. `confidence_engine.dart`
7. `scoring_engine.dart`
8. `golden_test.json`
9. `parity_test.py`
10. `report_generator.dart`

These 10 artifacts are enough to move from specification to implementation.
