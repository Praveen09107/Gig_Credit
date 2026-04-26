# GigCredit Scoring Engine — Full Technical Workflow Specification

## Document Purpose

This document is the **authoritative implementation specification** for the GigCredit scoring engine. It defines the full technical workflow, model architecture, inference pipeline, confidence handling, calibration, SHAP explainability, meta-learner logic, offline training process, on-device runtime behavior, validation strategy, and production artifact contract.

This specification is written so that an agent or engineering team can implement the entire scoring engine **without requiring any other reference**. If a future implementation conflicts with this document, this document takes precedence.

The design is intentionally optimized for:
- 100% on-device scoring,
- deterministic behavior,
- mobile performance,
- explainability,
- confidence-aware scoring,
- Python/Dart parity,
- minimal runtime dependencies.

---

## 1. Core Product Goal

GigCredit is a mobile credit scoring engine for gig workers and informal workers. It converts verified financial and identity inputs into a structured risk score on a 300–900 scale. The score must be:

- computed locally on the user’s Flutter device,
- explainable through pillar-level and feature-level reason codes,
- robust to partial or missing data,
- consistent across devices,
- reproducible from the same inputs,
- aligned with the feature engineering performed during training.

The system does **not** rely on TensorFlow Lite, ONNX, or runtime model interpreters. Model inference is compiled into pure Dart via generated source code or equivalent deterministic arithmetic implementations.

---

## 2. High-Level Architecture

The scoring engine is a layered hybrid system.

### 2.1 Layers

1. **Input acquisition layer**
   - Collects verified profile data.
   - Reads OCR outputs, bank statements, identity fields, tax fields, and scheme data.

2. **Feature engineering layer**
   - Converts raw verified profile data into 95 normalized features.
   - Applies domain anchors, ratio computation, sanitization, and fallback handling.

3. **Pillar scoring layer**
   - Computes pillar outputs for P1–P8.
   - ML pillars use tree-based regressors.
   - Non-ML pillars use deterministic scorecards.

4. **Validation layer**
   - Clamps and sanitizes each pillar output.
   - Detects NaN, infinity, out-of-range values, and missing-state anomalies.

5. **Confidence engine**
   - Computes confidence per pillar based on completeness, reliability, and consistency.
   - Neutralizes under-supported pillar outputs.

6. **Calibration layer**
   - Applies calibrated mapping to raw pillar outputs.
   - Makes pillar scores more comparable and meta-learner friendly.

7. **Meta-learner layer**
   - Combines all pillar scores plus work-type interactions into one probability.
   - Converts the probability to a final score on the 300–900 scale.

8. **Explainability layer**
   - Uses SHAP-derived offline lookup tables.
   - Produces feature-level and pillar-level explanation reasons.

9. **Reporting layer**
   - Builds ScoreReport.
   - Produces user-facing summaries, risk bands, and improvement reasons.

---

## 3. Design Principles

### 3.1 Deployment-first design

The scoring engine must be implementable on a mobile device. This means the design must prefer:
- exportable models,
- deterministic arithmetic,
- small runtime footprint,
- easy parity validation,
- no native runtime inference dependency.

### 3.2 Stability over maximal model variety

The best model per pillar in a research sense is not always the best model for production. The architecture intentionally prioritizes:
- one consistent model family for ML pillars,
- one export path,
- one validation approach,
- one runtime execution style.

### 3.3 Explainability as a first-class requirement

Every meaningful score movement must be explainable through a feature or pillar reason. Explanations should be generated from offline SHAP data rather than computed live on-device.

### 3.4 Confidence-aware scoring

If data is incomplete, the system should not pretend certainty. Confidence must be embedded into the score computation so that weakly supported pillars contribute less and low-data cases can be neutralized.

### 3.5 Training/runtime parity

The exact same feature definition must exist in training and on-device inference. This is non-negotiable.

---

## 4. Feature Schema

### 4.1 Total feature count

The system uses exactly 95 features.

### 4.2 Pillar allocation

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

### 4.3 Normalization contract

All raw values must be normalized into predictable ranges before they enter the pillar layer.

Rules:
- Ratios: clamp to [0, 1].
- Income-like values: normalize using a city/state income anchor.
- Counts: transform into bounded ratios or capped normalized values.
- Time-series stability metrics: invert where higher stability should map to higher score.
- Missing values: use domain fallback or neutral fallback depending on feature class.
- NaN and infinity at runtime: replace with 0.50.

### 4.4 Feature engineering invariants

The following must never diverge between training and runtime:
- feature order,
- normalization formula,
- anchor values,
- missing value fallback,
- transaction tagging rules,
- clipping bounds,
- pillar feature slicing indices.

Even a minor mismatch can break final score parity.

---

## 5. Input Acquisition Workflow

### 5.1 Input sources

The system consumes verified information from:
- user profile fields,
- Aadhaar/PAN identity verification,
- bank statement parsing,
- OCR-extracted utility bills,
- employment/work evidence,
- insurance evidence,
- government scheme evidence,
- tax filing evidence.

### 5.2 Data state model

Each input field should have at least one of these states:
- missing,
- uploaded,
- OCR-extracted,
- API-verified,
- rejected,
- pending verification,
- manually overridden.

### 5.3 Source trust hierarchy

If multiple sources provide the same semantic signal, prefer sources in this order:
1. API verification,
2. digitally extracted official document,
3. OCR from image,
4. user-entered text,
5. heuristic inference.

The confidence engine should reflect this hierarchy.

---

## 6. Synthetic Training Data Workflow

### 6.1 Purpose

Synthetic data is required for initial model training because the system does not begin with a large real-world dataset.

### 6.2 Data size

Use 15,000 synthetic profiles.

### 6.3 Stratification

Stratify across:
- work type,
- credit tier,
- key behavioral dimensions,
- income volatility levels,
- debt burden levels,
- document completeness levels.

### 6.4 Realism constraints

Synthetic profiles must respect Indian gig-worker behavior patterns:
- irregular but non-random income flows,
- strong seasonality in some work types,
- recurring EMI patterns,
- utility bill regularity,
- sparse tax filing history,
- common insurance gaps.

### 6.5 Labeling strategy

Each synthetic profile should produce:
- final binary or continuous creditworthiness target,
- P1 label,
- P2 label,
- P3 label,
- P4 label,
- P6 label.

P5/P7/P8 are deterministic and do not require learned labels.

---

## 7. Offline Training Workflow

### 7.1 Full sequence

The offline workflow is:

1. Generate synthetic dataset.
2. Engineer features.
3. Split into training and validation sets.
4. Train pillar models with Optuna tuning.
5. Evaluate validation metrics.
6. Calibrate pillar outputs.
7. Extract SHAP values.
8. Build OOF pillar predictions.
9. Train meta-learner.
10. Export models to Dart.
11. Generate constants and lookup tables.
12. Run parity validation.

### 7.2 Train/validation split

Use 80/20 split.

Stratify by:
- work type,
- tier,
- label distribution.

### 7.3 Cross-validation strategy

Use 5-fold stratified CV for:
- hyperparameter evaluation,
- meta-learner training data generation,
- calibration analysis.

### 7.4 Reproducibility

All offline training must use fixed seeds where possible. At minimum:
- global random seed,
- model-specific seed,
- CV split seed,
- Optuna sampler seed.

---

## 8. Pillar Model Architecture

### 8.1 ML pillars

#### P1 — Income Stability
Inputs should capture:
- monthly income level,
- volatility,
- trend slope,
- active earning months,
- balance consistency,
- anchor-normalized income,
- recurrence strength.

Recommended model: XGBoost regressor.

#### P2 — Payment Discipline
Inputs should capture:
- utility payment punctuality,
- EMI punctuality,
- recurring payments,
- bounce rate inverse,
- late fee behavior,
- payment repetition consistency,
- transaction regularity.

Recommended model: XGBoost regressor.

#### P3 — Debt Management
Inputs should capture:
- EMI-to-income ratio,
- debt count,
- outstanding debt burden,
- utilization,
- debt-band indicator,
- loan rollover tendency,
- overdue strength.

Recommended model: XGBoost regressor.

#### P4 — Savings Behaviour
Inputs should capture:
- average savings balance,
- savings rate,
- balance slope,
- month-end surplus,
- buffer months,
- liquidity ratio,
- withdrawal control,
- savings persistence.

Recommended model: XGBoost regressor.

#### P6 — Financial Resilience
Inputs should capture:
- health insurance,
- life insurance,
- accident insurance,
- insurance regularity,
- emergency fund ratio,
- medical buffer,
- ITR filing,
- scheme benefit behavior,
- shock resilience.

Recommended model: RandomForest regressor.

### 8.2 Why these models

These models are chosen because they are:
- strong on tabular structured data,
- easy to export to code,
- compatible with offline SHAP extraction,
- expressive enough for nonlinear credit behavior,
- practical for on-device deployment after code generation.

### 8.3 Tree constraints

For exportability:
- use `tree_method = exact` for XGBoost,
- keep depth shallow (3–4),
- cap tree count (80–150),
- avoid large ensembles that explode code size.

---

## 9. Rule-Based Pillar Architecture

### 9.1 P5 — Work Identity
This pillar should be deterministic and auditable.
It should combine:
- Aadhaar verification,
- PAN verification,
- face match score,
- address consistency,
- work evidence,
- screenshot evidence,
- employment consistency,
- document quality.

### 9.2 P7 — Social Accountability
This pillar should measure participation in formal or semi-formal schemes and social enrollment:
- e-Shram,
- PM-SYM,
- Mudra,
- PM-Kisan if relevant,
- formal worker registration,
- government linkage.

### 9.3 P8 — Tax Compliance
This pillar should evaluate:
- ITR filing status,
- years filed,
- declared income consistency,
- GST registration when applicable,
- tax document quality,
- tax continuity.

### 9.4 Why scorecards here

These pillars are better as rules because they are:
- directly explainable,
- easier to govern,
- less sensitive to model drift,
- easier to audit for users and lenders.

---

## 10. Transaction Tagging Workflow

### 10.1 Need for tagging

Bank statements must be converted into semantically tagged transactions before monthly aggregation.

### 10.2 Tagging layers

#### Layer 1: Keyword matching
Detect obvious patterns such as platform names, utility names, EMI keywords, and bank terms.

#### Layer 2: Structure matching
Detect UPI/NEFT/IMPS/NACH pattern structure and extract sender, receiver, mandate, or narrative fragments.

#### Layer 3: Amount-frequency heuristics
Use statistical frequency and amount patterns to infer likely tags when the raw label is ambiguous.

#### Layer 4: Fallback uncategorized bucket
If no tag is found, assign UNCATEGORIZED.

### 10.3 Tag propagation rules

Tags like GIG_INCOME, EMI_DEBIT, UTILITY_PAYMENT, SALARY, P2P_TRANSFER, CASH_WITHDRAWAL, and SAVINGS should feed specific features.

UNCATEGORIZED transactions must still count toward general cashflow features but should not drive special-purpose pillar features.

### 10.4 Importance to score integrity

Incorrect tagging can distort income stability, debt burden, and payment behavior features. Therefore transaction tagging is a core feature-engineering subsystem, not a side utility.

---

## 11. Monthly Aggregation Workflow

### 11.1 Aggregation steps

For each month in the observation window, compute:
- total credits,
- total debits,
- balance trajectory,
- EMI total,
- utility total,
- gig-income totals,
- bank charge totals,
- recurring payment frequency.

### 11.2 Time window

The model should work with available history but should prefer 6–12 months when present.

### 11.3 Output to feature computation

Monthly aggregates become the raw source for the 95 engineered features.

---

## 12. Feature Computation Workflow

### 12.1 P1 Income Stability features
Examples:
- average monthly income norm,
- income CV inverse,
- trend slope,
- earning month ratio,
- balance consistency,
- recency,
- growth strength.

### 12.2 P2 Payment Discipline features
Examples:
- utility on-time ratio,
- EMI on-time ratio,
- subscription consistency,
- bounce inverse,
- late fee inverse,
- payment regularity.

### 12.3 P3 Debt Management features
Examples:
- EMI-to-income ratio inverse,
- debt count inverse,
- outstanding debt inverse,
- credit utilization inverse,
- debt-band cap variable.

### 12.4 P4 Savings Behaviour features
Examples:
- average balance ratio,
- savings rate,
- balance growth slope,
- month-end surplus,
- liquidity ratio,
- buffer months.

### 12.5 P5 Work Identity features
Examples:
- Aadhaar verified,
- PAN verified,
- face match,
- address consistency,
- work proof,
- screenshot quality,
- experience normalizer.

### 12.6 P6 Financial Resilience features
Examples:
- insurance active flags,
- emergency fund ratio,
- ITR filed,
- scheme coverage,
- shock resilience index.

### 12.7 P7 Social Accountability features
Examples:
- social scheme registrations,
- formal work registration,
- government linkage,
- benefit stability.

### 12.8 P8 Tax Compliance features
Examples:
- recent ITR filed,
- years filed,
- declared income ratio,
- GST registration,
- tax quality and continuity.

### 12.9 Output contract

The result of feature computation is a 95-length numeric vector in the exact order required by the model slices.

---

## 13. Pillar Validation Workflow

### 13.1 Raw output validation

Every pillar score must be checked after model computation.

Rules:
- if score is NaN -> 0.50,
- if score is infinite -> 0.50,
- if score < 0 -> clamp to 0,
- if score > 1 -> clamp to 1.

### 13.2 Confidence floor handling

If confidence for a pillar is below 0.30:
- pillar becomes neutralized to 0.50,
- report should explicitly state insufficient evidence,
- meta-learner still receives the neutralized value.

### 13.3 Hard business rule overrides

Certain features can impose hard caps or forced behavior, for example:
- extreme EMI burden can cap debt score,
- low identity verification can cap work identity score,
- missing bank statement can block final scoring entirely.

---

## 14. Confidence Engine Workflow

### 14.1 Purpose

Confidence is a model-input quality signal. It expresses how much trust should be placed in each pillar output.

### 14.2 Confidence components

Each pillar confidence should be derived from:
- completeness,
- reliability,
- consistency.

### 14.3 Confidence formula

A recommended implementation:

	raw_confidence = 0.5 * completeness + 0.3 * reliability + 0.2 * consistency

### 14.4 Confidence adjustment formula

If confidence is acceptable:

	headjusted_score = calibrated_score * confidence + 0.5 * (1 - confidence)

If confidence is too low:
- return neutral 0.50,
- mark the pillar as low-confidence in the report.

### 14.5 Why this matters

Without confidence handling, the system would overstate certainty for incomplete profiles. Confidence ensures the score remains fair and stable across partial onboarding states.

---

## 15. Calibration Workflow

### 15.1 Why calibration exists

Raw tree outputs are often not aligned enough to be directly combined. Calibration makes the pillar values more consistent and compatible with the meta-learner.

### 15.2 Preferred calibration methods

- Isotonic regression for well-supported pillars.
- Sigmoid / Platt-style calibration when data is sparse or noisy.

### 15.3 Offline fit procedure

1. Generate out-of-fold predictions.
2. Fit calibration model on prediction vs label pairs.
3. Export calibration mapping.
4. Use the mapping on-device after raw inference.

### 15.4 Calibration outputs

For each ML pillar, export:
- calibrated mapping,
- calibration metadata,
- optional lookup bins or function parameters.

---

## 16. Meta-Learner Workflow

### 16.1 Role

The meta-learner is the final decision layer. It turns pillar scores into the final credit probability.

### 16.2 Input features

The meta-learner receives 20 inputs:
- 8 pillar scores,
- 4 work-type one-hot flags,
- 8 interaction terms for P1 and P2 with work type.

### 16.3 Why only P1 and P2 interactions

P1 and P2 are the strongest and most behaviorally variable pillars. Adding interactions for all pillars would increase complexity and variance without enough sample support.

### 16.4 Model choice

Use logistic regression because it is:
- interpretable,
- stable,
- lightweight,
- easy to export,
- easy to audit.

### 16.5 Final mapping

The logistic regression output is a probability in [0,1].
That is converted to a 300–900 score using:

	rounded_score = round(probability * 600 + 300)

### 16.6 Why this is the final score method

No weighted-sum alternate is allowed. The logistic meta-learner is the only final score method because it is trainable, adaptable, and consistent with the offline training process.

---

## 17. SHAP Explainability Workflow

### 17.1 Goal

Produce explanations that are fast enough for mobile and faithful enough for user-facing reports.

### 17.2 Offline SHAP generation

For each ML pillar:
- compute TreeExplainer SHAP values,
- bin feature values into percentile intervals,
- compute average SHAP contribution per bin,
- store results in JSON lookup tables.

### 17.3 On-device SHAP lookup

At runtime:
- determine which percentile bin a feature value belongs to,
- retrieve precomputed SHAP contribution,
- generate reason codes.

### 17.4 Output structure

The explainability engine should produce:
- top positive factors,
- top negative factors,
- pillar-level narrative,
- overall score movement summary.

### 17.5 Why lookup tables instead of live SHAP

Live SHAP is too expensive for mobile and unnecessary once the shape of the explanation is known offline. Lookup tables preserve most of the benefit while keeping runtime negligible.

---

## 18. On-Device Inference Workflow

### 18.1 Full runtime sequence

1. Load verified profile.
2. Generate feature vector.
3. Sanitize vector.
4. Slice the vector into pillar sub-vectors.
5. Run P1–P4 and P6 ML scorers.
6. Compute P5/P7/P8 scorecards.
7. Validate all pillar outputs.
8. Apply hard business rules.
9. Compute confidence per pillar.
10. Apply calibration and confidence adjustment.
11. Build meta-features.
12. Compute final probability.
13. Convert probability to score.
14. Derive grade and risk band.
15. Generate SHAP explanations.
16. Assemble ScoreReport.

### 18.2 Sequential execution requirement

Execution should be sequential by default. Parallel isolates are unnecessary because the pure Dart arithmetic path is already fast enough. Avoid parallel complexity unless profiling proves a strong need.

### 18.3 Runtime safety checks

The runtime must always guard against:
- NaN values,
- overflow/underflow,
- missing feature slices,
- null profile fields,
- invalid output ranges.

---

## 19. Report Generation Workflow

### 19.1 ScoreReport contents

The ScoreReport should include:
- final score,
- grade,
- risk band,
- pillar scores,
- confidence values,
- top SHAP reasons,
- negative and positive factors,
- explanation text,
- timestamp,
- work type,
- validation flags.

### 19.2 Score interpretation

The report should clearly distinguish between:
- high score because of strong evidence,
- moderate score because of partial evidence,
- neutral score because of insufficient data.

### 19.3 User-facing behavior

When confidence is low, the report should not be hidden; it should clearly explain why the system is less certain.

---

## 20. File and Artifact Contract

### 20.1 Offline artifacts

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

### 20.2 Runtime artifacts

- `confidence_engine.dart`
- `scoring_engine.dart`
- `feature_engineering.dart`
- `feature_sanitizer.dart`
- `pillar_validator.dart`
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
- `report_generator.dart`
- `scoring_constants.dart`

### 20.3 Output artifacts

- `ScoreReport`
- PDF report file
- summary JSON for backend storage if needed

---

## 21. Validation Workflow

### 21.1 Golden test

A fixed golden profile must always produce the same result.

### 21.2 Parity validation

Python and Dart must produce matched results within tolerance.

### 21.3 Validation gates

Do not ship if any of these fail:
- feature parity,
- score parity,
- calibration drift,
- confidence logic mismatch,
- explanation lookup mismatch.

### 21.4 Regression prevention

Every future change must re-run the golden tests. Any feature change, model change, or calibration change invalidates prior parity until revalidated.

---

## 22. Error Handling Workflow

### 22.1 Runtime anomalies

The system must handle:
- invalid OCR values,
- missing bank transactions,
- null identity fields,
- malformed JSON,
- missing calibration data,
- bad feature slices,
- scorer errors.

### 22.2 Standard fallback behavior

When a pillar cannot be scored properly:
- do not crash,
- return neutral or capped output,
- mark the pillar as low-confidence,
- continue scoring if minimum requirements are met.

### 22.3 Hard stop conditions

If minimum data requirements are not satisfied:
- do not compute final score,
- show insufficient-data state.

---

## 23. Performance Workflow

### 23.1 Target runtime

The full scoring pipeline should finish within approximately 15–20 ms on a midrange Android device once feature engineering is complete.

### 23.2 Code size constraints

The generated Dart source should stay compact enough for:
- app compilation,
- AOT compilation,
- maintainability,
- acceptable APK size.

### 23.3 Optimization priorities

Priority order:
1. correctness,
2. parity,
3. determinism,
4. speed,
5. code size.

Speed must not be achieved by sacrificing parity or explainability.

---

## 24. Security Workflow

### 24.1 On-device privacy

The design is privacy-first because the score is computed locally.

### 24.2 Sensitive storage

Use encrypted session storage where appropriate. Clean temporary artifacts after scoring.

### 24.3 Model protection

Since models are compiled into Dart code rather than shipped as TFLite files, the attack surface is reduced. The critical security problem becomes user-data security, not model-file decryption.

---

## 25. Implementation Order

The recommended implementation order is:

1. Freeze feature schema.
2. Implement data generator.
3. Implement feature engineering.
4. Implement pillar models.
5. Implement confidence engine.
6. Implement calibration.
7. Train meta-learner.
8. Generate SHAP lookup tables.
9. Implement Dart export.
10. Implement on-device inference.
11. Implement report generation.
12. Implement parity tests.
13. Run validation.
14. Optimize.
15. Ship.

---

## 26. Final Technical Summary

This scoring system is a hybrid of:
- tree-based ML scoring for behavioral pillars,
- deterministic scorecards for identity/scheme/tax pillars,
- confidence-aware adjustment for partial evidence,
- a logistic meta-learner for final score aggregation,
- offline SHAP lookup tables for explanation.

The architecture is explicitly designed to be:
- mobile-friendly,
- explainable,
- reproducible,
- testable,
- and production-implementable.

If implemented exactly as specified, the system should be capable of producing stable credit scores with a clear explanation trail and no runtime dependency on TensorFlow or TFLite.

---

## 27. Non-Negotiable Rules

1. Do not change feature ordering.
2. Do not change pillar slices without retraining.
3. Do not use a weighted sum instead of the meta-learner.
4. Do not compute SHAP live on-device.
5. Do not allow NaN to reach the scorer.
6. Do not ship without parity tests.
7. Do not ignore low-confidence pillars.
8. Do not weaken minimum-data gating.

These rules are essential for keeping the system correct.

---

## 28. Implementation Readiness Statement

This specification is ready to be used as the basis for agentic implementation. It defines the scoring engine workflow at a level of detail sufficient for engineering execution, testing, and code generation.

If you want the next step, the most useful output would be a **single final MD requirements file** formatted cleanly with a compact table of contents, section numbering, and implementation checklists.
