# GigCredit Scoring Engine — Deep Technical Specification

## 1. Scope

This document defines the end-to-end machine learning scoring architecture for GigCredit at a level intended for direct implementation by an autonomous coding agent or engineering team. It focuses exclusively on the scoring engine: feature engineering, pillar models, confidence engine, calibration, meta-learner, SHAP explainability, parity validation, runtime execution, and artifact contracts.

This document deliberately avoids product/UI/business content except where it affects scoring correctness. The intent is to remove ambiguity and force a single implementable interpretation.

---

## 2. System Requirements

### 2.1 Functional requirements

The scoring system must:
1. Compute a credit score on-device in Flutter.
2. Convert verified profile data into 95 deterministic features.
3. Score 8 pillars: P1–P8.
4. Use learned ML models for P1, P2, P3, P4, and P6.
5. Use deterministic scorecards for P5, P7, and P8.
6. Apply pillar validation and confidence adjustment.
7. Apply a logistic meta-learner to produce the final score.
8. Return a score in the range 300–900.
9. Return a grade and risk band.
10. Return explanation artifacts based on SHAP lookup tables.
11. Be reproducible between Python training and Dart runtime.

### 2.2 Non-functional requirements

The scoring engine must:
- execute without TensorFlow Lite or ONNX at runtime,
- run with minimal memory overhead,
- be deterministic for identical inputs,
- be fully testable with golden cases,
- degrade safely when data is incomplete,
- support offline scoring,
- keep the runtime path free from complex ML interpreters.

### 2.3 Hard constraints

- Feature order must not change.
- Model slice indices must not change without retraining.
- Runtime and offline feature generation must match exactly.
- SHAP must not be computed live.
- Weighted sum final scoring is not allowed.
- NaN or infinity must never reach the final meta-learner.

---

## 3. Architectural Overview

The scoring system consists of the following layers:

1. **Raw input layer** — verified profile fields, parsed documents, OCR outputs, API-verification results.
2. **Feature engineering layer** — converts inputs into a 95-length feature vector.
3. **Feature sanitization layer** — clamps and repairs invalid numeric values.
4. **Pillar layer** — computes P1–P8 pillar outputs.
5. **Output validation layer** — ensures each pillar output is numerically valid.
6. **Confidence engine** — computes confidence per pillar and handles insufficient evidence.
7. **Calibration layer** — maps raw pillar outputs into calibrated values.
8. **Meta-learner** — combines all pillar signals into final credit probability.
9. **Score scaling layer** — converts probability to 300–900 score.
10. **Explainability layer** — SHAP lookup and explanation ranking.
11. **Report layer** — creates ScoreReport.

Each layer has a single responsibility. No layer should do work that belongs to another layer.

---

## 4. Data Model

### 4.1 VerifiedProfile

The runtime input should be represented as a strongly typed profile object with at least these groups:

- identity,
- bank,
- work,
- insurance,
- taxes,
- schemes,
- documents,
- runtime state.

### 4.2 Runtime states

Fields must have explicit states:
- missing,
- uploaded,
- OCR-extracted,
- API-verified,
- rejected,
- pending,
- overridden.

The confidence engine uses these states to determine reliability.

### 4.3 Source precedence

If multiple sources describe the same semantic field, precedence must be:
1. API verified.
2. digital official document extraction.
3. OCR.
4. user-entered fallback.
5. heuristic inference.

---

## 5. Feature Engineering Specification

### 5.1 Feature count and slicing

The system uses 95 features in fixed order.

| Pillar | Range | Count | Type |
|---|---:|---:|---|
| P1 | 0–12 | 13 | ML |
| P2 | 13–27 | 15 | ML |
| P3 | 28–36 | 9 | ML |
| P4 | 37–48 | 12 | ML |
| P5 | 49–66 | 18 | Scorecard |
| P6 | 67–77 | 11 | ML |
| P7 | 78–87 | 10 | Scorecard |
| P8 | 88–94 | 7 | Scorecard |

### 5.2 Feature engineering contract

Feature engineering should be implemented as a pure function:

`VerifiedProfile -> List<double>(95)`

It must not depend on UI state or asynchronous state once input data is resolved.

### 5.3 Domain anchors

Income-related features must use anchors derived from city or state median income.
The anchor selection order is:
1. work city if known,
2. city inferred from branch IFSC or address,
3. state/UT,
4. national fallback.

This ensures that a worker’s geography is normalized fairly.

### 5.4 Transaction tagging pipeline

Transaction tagging is not optional. It is a core step in feature engineering.

#### Layer 1: Keyword match
Recognize platform names, EMI keywords, utility providers, bank keywords.

#### Layer 2: Pattern match
Parse structured references such as UPI, NEFT, IMPS, NACH.

#### Layer 3: Amount-frequency heuristics
Infer a tag from recurrence and amount shape when narration is ambiguous.

#### Layer 4: Uncategorized fallback
Any transaction not matched must still remain in general aggregation but should not drive category-specific features.

### 5.5 Monthly aggregation

For each month compute:
- total credits,
- total debits,
- EMI sum,
- utility sum,
- recurring income sum,
- recurring expense sum,
- ending balance,
- bounce count,
- payment counts.

### 5.6 Feature normalization rules

Every feature must be numerically stable.

#### Rules
- ratio features: [0,1]
- inverse metrics: 1 - normalized_risk
- count metrics: capped and normalized
- income metrics: anchored normalization
- volatility metrics: higher risk => lower score
- missing values: domain-specific fallback or 0.50 fallback at runtime

### 5.7 Runtime sanitizer

The sanitizer must enforce:
- NaN -> 0.50
- +inf -> 0.50
- -inf -> 0.50
- any non-finite -> 0.50
- clamp all features to [0,1]

This prevents generated Dart scorers from seeing invalid values.

---

## 6. Synthetic Data Design

### 6.1 Training dataset

The offline pipeline must generate 15,000 synthetic records.

### 6.2 Synthetic realism goals

The data must preserve realistic patterns:
- intermittent income,
- recurring EMIs,
- utility bill cycles,
- sparse tax filing,
- insurance gaps,
- varying levels of formalization,
- different work-type behavior distributions.

### 6.3 Labels

For each profile generate:
- final target label,
- P1 label,
- P2 label,
- P3 label,
- P4 label,
- P6 label.

P5/P7/P8 do not require learned labels.

### 6.4 Label generation principle

Labels should be derived from a weighted latent creditworthiness function plus controlled noise. Noise should be enough to simulate realistic uncertainty but not so much that the target becomes random.

---

## 7. Offline Training Pipeline

### 7.1 Training order

1. Generate data.
2. Build features.
3. Split train/validation.
4. Tune pillar models.
5. Train final pillar models.
6. Calibrate outputs.
7. Compute SHAP values.
8. Train meta-learner using out-of-fold predictions.
9. Export Dart scorers.
10. Run parity tests.

### 7.2 Split rules

Use stratified 80/20 split by:
- work type,
- tier,
- label bucket.

### 7.3 Cross-validation

Use 5-fold stratified CV for:
- Optuna evaluation,
- out-of-fold meta training,
- calibration analysis.

### 7.4 Reproducibility

Fix random seeds in:
- synthetic generation,
- Optuna sampler,
- model constructor,
- cross-validation split.

Without reproducibility, parity testing becomes meaningless.

---

## 8. Pillar Model Engineering

### 8.1 P1 Income Stability

P1 should respond to:
- average income normalized to anchor,
- income variability,
- trend slope,
- active earning month ratio,
- recency of income,
- recurring income regularity,
- balance coherence.

#### Modeling rationale
Income is nonlinear. Small changes in volatility or persistence can significantly change creditworthiness. A tree ensemble is appropriate.

### 8.2 P2 Payment Discipline

P2 should respond to:
- on-time utility ratio,
- on-time EMI ratio,
- recurring payment consistency,
- bounce inverses,
- late fee inverses,
- cycle regularity.

#### Modeling rationale
Behavioral payment regularity is threshold-sensitive, so tree splits are effective.

### 8.3 P3 Debt Management

P3 should respond to:
- EMI-to-income ratio,
- outstanding debt,
- debt count,
- utilization,
- rollover behavior,
- overdue history,
- debt band indicators.

#### Modeling rationale
Debt behavior includes hard caps and threshold effects. A tree ensemble can capture this better than a linear model.

### 8.4 P4 Savings Behaviour

P4 should respond to:
- average savings balance ratio,
- growth slope,
- month-end surplus,
- liquidity ratio,
- buffer months,
- withdrawal discipline,
- savings persistence.

#### Modeling rationale
Savings is a nonlinear mix of stability, persistence, and liquidity.

### 8.5 P6 Financial Resilience

P6 should respond to:
- insurance flags,
- emergency fund ratios,
- ITR history,
- benefit participation,
- shock resilience,
- medical buffer,
- coverage consistency.

#### Modeling rationale
This pillar contains sparse binary signals and therefore benefits from bagging.

---

## 9. Model Hyperparameter Strategy

### 9.1 XGBoost constraints

Use:
- `tree_method = exact`
- `n_estimators` between 80 and 150
- `max_depth` between 3 and 4
- `learning_rate` in a moderate range
- subsample and colsample values below 1.0 to reduce overfit

### 9.2 RandomForest constraints

Use shallow forests and avoid deep trees.

### 9.3 Why shallow trees matter

The generated Dart source size grows with tree count and depth. Deep trees make the export larger, slower to compile, and harder to validate.

### 9.4 Hyperparameter objective

Use validation RMSE as the main tuning objective and monitor MAE and R² as supporting metrics.

---

## 10. Validation Metrics

### 10.1 Per-pillar validation

Record for every pillar:
- RMSE,
- MAE,
- R²,
- calibration error,
- feature importance ranking.

### 10.2 Target thresholds

Suggested thresholds:
- P1 RMSE <= 0.08
- P2 RMSE <= 0.08
- P3 RMSE <= 0.10
- P4 RMSE <= 0.08
- P6 RMSE <= 0.10

### 10.3 Failure handling

If targets are not met:
1. inspect synthetic data fidelity,
2. inspect feature leakage,
3. inspect calibration stability,
4. adjust hyperparameters only if needed,
5. do not increase model complexity without reason.

---

## 11. Deterministic Scorecard Design

### 11.1 P5 Work Identity

P5 should aggregate:
- Aadhaar verification,
- PAN verification,
- face match,
- document quality,
- address consistency,
- work evidence,
- employment proof,
- platform consistency.

### 11.2 P7 Social Accountability

P7 should aggregate:
- scheme registrations,
- worker registration,
- government enrollment,
- formalization evidence,
- benefit continuity.

### 11.3 P8 Tax Compliance

P8 should aggregate:
- ITR filing history,
- filing regularity,
- declared income ratio,
- GST consistency,
- tax document quality.

### 11.4 Scorecard range

Each scorecard must output a value in [0,1].

### 11.5 Why these are deterministic

These pillars are governance-sensitive and easier to audit when rules are explicit.

---

## 12. Output Validation Workflow

### 12.1 Validation rules

After each pillar output:
- if NaN, replace with 0.50,
- if infinite, replace with 0.50,
- if below 0, clamp to 0,
- if above 1, clamp to 1.

### 12.2 Why validate before confidence

Confidence should not operate on corrupt outputs. Validate first, then apply confidence.

### 12.3 Confidence floor

If pillar confidence < 0.30, replace the pillar output with 0.50 neutral.

### 12.4 Soft-fail philosophy

The system should avoid crashing for isolated pillar issues. It should degrade gracefully unless minimum-data gates fail.

---

## 13. Confidence Engine Specification

### 13.1 Confidence signals

For each pillar compute:
- completeness score,
- reliability score,
- consistency score.

### 13.2 Completeness

Completeness measures whether all expected evidence exists for the pillar.
Examples:
- bank statement present,
- OCR clean enough,
- required API responses available,
- no critical document missing.

### 13.3 Reliability

Reliability measures source trust level.
Examples:
- API-verified > document-extracted > OCR > user entry.

### 13.4 Consistency

Consistency measures agreement among sources.
Examples:
- bank income vs ITR income,
- address consistency across documents,
- face match against identity.

### 13.5 Formula

A recommended weighted formula:

`confidence = 0.5 * completeness + 0.3 * reliability + 0.2 * consistency`

### 13.6 Confidence adjustment formula

For acceptable confidence:

`adjusted_score = calibrated_score * confidence + 0.5 * (1 - confidence)`

For low confidence:

`adjusted_score = 0.5`

### 13.7 Confidence output contract

The confidence engine should return:
- pillar confidence value,
- confidence reason code,
- low-confidence flag,
- completeness/reliability/consistency components.

This makes the report explainable and debuggable.

---

## 14. Calibration Specification

### 14.1 Why calibration is needed

Raw tree scores are often usable but not well aligned across pillars. Calibration makes the outputs more comparable and useful as inputs to the meta-learner.

### 14.2 Supported calibration methods

#### Isotonic regression
Use when enough validation data exists.
Benefits:
- monotonic,
- flexible,
- nonparametric.

Risks:
- may overfit on small samples.

#### Sigmoid / Platt-like calibration
Use when data is smaller or noisier.
Benefits:
- simpler,
- more stable.

### 14.3 Calibration export

Export a compact representation that can run on-device, such as:
- lookup table,
- piecewise mapping,
- stored coefficient pair,
- bin-based transform.

### 14.4 On-device order

Always apply:
1. raw model output,
2. validation,
3. calibration,
4. confidence adjustment.

Never reverse the order.

---

## 15. Meta-Learner Specification

### 15.1 Purpose

The meta-learner converts the eight pillar scores into a final credit probability.

### 15.2 Inputs

The meta-features are:
- 8 pillar scores,
- 4 one-hot work type flags,
- 8 interaction terms for P1 and P2.

### 15.3 Why interactions are restricted

Only P1 and P2 interactions are included because:
- they contribute the largest share of score variance,
- they are the most work-type-sensitive,
- the training sample size does not justify more interaction explosion.

### 15.4 Logistic regression equations

The logistic meta-learner computes:

`logit = intercept + Σ(feature_i * coeff_i)`

`probability = 1 / (1 + exp(-logit))`

`final_score = round(probability * 600 + 300)`

### 15.5 Why logistic regression wins here

It is:
- interpretable,
- compact,
- easy to export,
- easy to validate,
- easier to debug than a second tree ensemble.

### 15.6 Training rule

Train the meta-learner only on out-of-fold pillar predictions. Do not train it on in-sample pillar outputs.

---

## 16. SHAP Explainability Specification

### 16.1 Why SHAP must be offline

Computing SHAP live on mobile is too expensive and unnecessary. Instead, precompute feature-attribution behavior offline and store the results as lookup tables.

### 16.2 Offline procedure

For each ML pillar:
1. Fit TreeExplainer.
2. Generate SHAP values over the training or validation set.
3. Bin each feature value by percentile.
4. Compute average SHAP value per bin.
5. Store bins and values in JSON.

### 16.3 On-device lookup

At runtime:
1. read feature value,
2. choose the correct bin,
3. retrieve the precomputed SHAP impact,
4. use it for explanation ranking.

### 16.4 Explanation outputs

For each pillar and overall report, output:
- strongest positive feature drivers,
- strongest negative feature drivers,
- pillar explanation text,
- user-friendly suggestions.

### 16.5 Why binning is acceptable

Binned SHAP preserves the non-linear behavior of tree models while keeping runtime simple.

---

## 17. Final Score Workflow

### 17.1 Full sequence

1. Build 95 features.
2. Sanitize features.
3. Compute P1–P4 and P6 raw scores.
4. Compute P5, P7, P8 scorecards.
5. Validate all pillar outputs.
6. Compute pillar confidence.
7. Calibrate pillar scores.
8. Apply confidence adjustment.
9. Build meta-features.
10. Compute meta probability.
11. Convert to 300–900 score.
12. Assign grade and risk band.
13. Generate explanations.
14. Return ScoreReport.

### 17.2 Hard stop rules

Do not compute final score if minimum data requirements are not met.

### 17.3 Low-confidence behavior

If one or more pillars are low-confidence:
- neutralize those pillars,
- reflect the weakness in the report,
- do not exaggerate certainty.

---

## 18. Runtime Safety Specification

### 18.1 Sanitizer responsibilities

The sanitizer must detect and repair invalid numeric states before any model function is called.

### 18.2 Pillar output validator responsibilities

The validator must ensure all pillar outputs are safe to use.

### 18.3 Failure containment

A single pillar failure must not crash the scoring engine unless it violates minimum data requirements.

### 18.4 Debug visibility

When validation or confidence rules intervene, the report should include reason codes so engineers can see why a pillar was neutralized.

---

## 19. Production Artifact Contract

### 19.1 Offline artifacts

- `feature_schema.json`
- `feature_engineering.py`
- `train_pillars.py`
- `train_meta.py`
- `export_dart.py`
- `parity_test.py`
- `golden_test.json`
- `meta_coefficients.json`
- `shap_lookup.json`
- `feature_means.json`
- `state_income_anchors.json`

### 19.2 Dart runtime artifacts

- `feature_engineering.dart`
- `feature_sanitizer.dart`
- `pillar_validator.dart`
- `confidence_engine.dart`
- `calibration.dart`
- `metalearner.dart`
- `shap_lookup.dart`
- `scorecard_p5.dart`
- `scorecard_p7.dart`
- `scorecard_p8.dart`
- `p1_scorer.dart`
- `p2_scorer.dart`
- `p3_scorer.dart`
- `p4_scorer.dart`
- `p6_scorer.dart`
- `scoring_engine.dart`
- `report_generator.dart`
- `scoring_constants.dart`

### 19.3 Output artifacts

- final score,
- grade,
- risk band,
- pillar scores,
- confidence values,
- explanations,
- report object,
- optional PDF.

---

## 20. Validation Strategy

### 20.1 Golden parity test

A fixed golden input must produce the same output in Python and Dart.

### 20.2 Tolerance

Numerical mismatch must remain within a very small tolerance, typically `1e-5` for the key numeric outputs.

### 20.3 Regression tests

Any change to:
- feature engineering,
- calibration,
- meta coefficients,
- scorecards,
- export code,

requires re-running parity tests.

### 20.4 Release gate

No release unless:
- golden tests pass,
- parity tests pass,
- confidence logic passes,
- edge-case tests pass.

---

## 21. Detailed Implementation Order

1. Define feature schema.
2. Implement transaction tagging.
3. Implement monthly aggregation.
4. Implement feature engineering.
5. Implement synthetic data generation.
6. Implement pillar training.
7. Implement calibration.
8. Implement SHAP extraction.
9. Implement meta-learner training.
10. Export Dart scorers.
11. Implement sanitizer and validator.
12. Implement confidence engine.
13. Implement on-device scoring workflow.
14. Implement report generator.
15. Run parity tests.
16. Harden error handling.
17. Optimize.
18. Ship.

---

## 22. Final Production Rules

- Feature order is immutable.
- Pillar slices are immutable unless retraining occurs.
- The meta-learner is the only final scoring method.
- SHAP is explanation only.
- Confidence is mandatory.
- Neutral fallback is allowed only for low-confidence or invalid outputs.
- Minimum-data gating is mandatory.
- Runtime model interpreters are not allowed.
- Python and Dart parity is mandatory.

---

## 23. Readiness Statement

This document is meant to be a **deep implementation specification**. It describes the scoring engine at a technical level sufficient for a coding agent to produce the pipeline without guessing the major architecture decisions.

It is intentionally strict because the earlier version of the system failed due to ambiguity and integration fragility.

This specification removes that ambiguity by defining:
- how the features are built,
- how the pillar models behave,
- how confidence works,
- how calibration is applied,
- how the meta-learner computes the final score,
- how SHAP explanations are generated,
- how the runtime should validate itself.

If you want, I can now convert this into a **clean standalone MD file artifact** and share it for direct use as the master requirements file.
