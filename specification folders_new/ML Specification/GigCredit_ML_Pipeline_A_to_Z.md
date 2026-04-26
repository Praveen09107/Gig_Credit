# GigCredit ML Pipeline — A to Z Implementation Specification

## 1. Purpose

This document defines the **complete machine learning pipeline** for the GigCredit scoring engine, from raw data generation to mobile-exported inference artifacts. It is intended to be used as a direct implementation blueprint by an agent or engineering team.

The objective is to remove ambiguity in the ML workflow so the implementation can be produced without guessing any critical decisions.

---

## 2. ML Pipeline Scope

The ML pipeline covers:
- synthetic data generation,
- feature engineering,
- pillar target generation,
- train/validation splitting,
- hyperparameter search,
- model training,
- model calibration,
- SHAP extraction,
- meta-learner training,
- model export to Dart,
- parity testing,
- validation gating,
- artifact packaging.

The ML pipeline does **not** cover UI, onboarding forms, PDF rendering, or report layout except where those affect scoring outputs.

---

## 3. End-to-End Pipeline Map

### 3.1 Offline ML workflow

1. Generate synthetic profiles.
2. Compute raw domain values.
3. Convert raw values into 95 features.
4. Split dataset into train/validation folds.
5. Train pillar models for P1, P2, P3, P4, and P6.
6. Fit calibration mappings.
7. Compute SHAP values and build lookup tables.
8. Build out-of-fold predictions.
9. Train meta-learner.
10. Export model logic to Dart.
11. Generate constants and lookup assets.
12. Run parity validation.
13. Package runtime artifacts.

### 3.2 Runtime inference workflow

1. Receive verified profile.
2. Engineer 95 features.
3. Sanitize the feature vector.
4. Slice features by pillar.
5. Run pillar scorers.
6. Validate pillar outputs.
7. Compute confidence.
8. Apply calibration and neutralization.
9. Build meta-features.
10. Run meta-learner.
11. Convert probability to final score.
12. Build explanations from SHAP lookup.
13. Return ScoreReport.

---

## 4. Data Generation Stage

### 4.1 Objective

Generate synthetic data that resembles the financial behavior of Indian gig workers closely enough for model training.

### 4.2 Required outputs

Each synthetic row must include:
- raw transaction aggregates,
- identity signals,
- tax signals,
- insurance signals,
- scheme signals,
- work type,
- final label,
- pillar labels for P1, P2, P3, P4, P6.

### 4.3 Required distributions

The generator must produce realistic distributions for:
- income,
- income variability,
- recurring expenses,
- EMI burden,
- savings behavior,
- payment punctuality,
- insurance adoption,
- tax filing behavior.

### 4.4 Work-type modeling

Synthetic data must include at least:
- platform workers,
- vendors,
- tradespeople,
- freelancers.

Each work type should exhibit different income volatility, payment cadence, and document availability patterns.

### 4.5 Label generation

Label generation should use a latent creditworthiness score built from weighted behavioral variables, then transformed into:
- continuous label in [0,1],
- tier label,
- pillar-specific targets.

### 4.6 Noise policy

Add noise carefully:
- enough to avoid overfitting,
- not so much that learning becomes impossible.

Noise should be heteroskedastic where appropriate. For example, freelancers can have more income volatility than salary-like workers.

---

## 5. Feature Engineering Stage

### 5.1 Input contract

The feature generator takes a structured `VerifiedProfile` and produces a fixed-length 95-feature array.

### 5.2 Pipeline order

1. Normalize raw inputs.
2. Tag transactions.
3. Aggregate monthly behavior.
4. Compute derived financial ratios.
5. Compute identity and formalization features.
6. Apply domain normalization.
7. Clamp invalid values.
8. Return ordered 95-vector.

### 5.3 Design rule

The feature generator must be deterministic and side-effect free.

### 5.4 Feature bucket responsibilities

#### P1
Income stability and predictability.

#### P2
Repayment and payment discipline.

#### P3
Debt burden and leverage.

#### P4
Savings and liquidity resilience.

#### P5
Identity and work evidence.

#### P6
Insurance and emergency resilience.

#### P7
Scheme participation and social linkage.

#### P8
Tax compliance and financial formalization.

### 5.5 Runtime parity requirement

The exact same equations, bounds, and anchor constants must be used in training and production. This includes:
- normalization anchors,
- ratio formulas,
- clipping thresholds,
- invalid-value handling.

---

## 6. Transaction Tagging Stage

### 6.1 Why this matters

Transaction tagging is one of the most important preprocessing layers because all downstream financial features depend on it.

### 6.2 Tagging architecture

Use a four-layer resolver:

1. **Keyword resolver**
   - Detects obvious platform names and utility names.

2. **Pattern resolver**
   - Interprets transaction structure such as UPI, NEFT, IMPS, and NACH.

3. **Heuristic resolver**
   - Uses amount and recurrence patterns.

4. **Fallback resolver**
   - Marks unmatched entries as uncategorized.

### 6.3 Output tags

Suggested tags:
- GIG_INCOME,
- SALARY,
- EMI_DEBIT,
- UTILITY_PAYMENT,
- SAVINGS,
- P2P_TRANSFER,
- CASH_WITHDRAWAL,
- BANK_CHARGES,
- UNCATEGORIZED.

### 6.4 Tagging output contract

Each transaction should receive:
- tag,
- confidence,
- evidence source,
- optional reason code.

### 6.5 Failure rules

If the tagger is uncertain, it should degrade to UNCATEGORIZED rather than inventing a false tag.

---

## 7. Monthly Aggregation Stage

### 7.1 Aggregation goal

Convert tagged transactions into monthly financial behavior statistics.

### 7.2 Required monthly metrics

At minimum compute:
- monthly credits,
- monthly debits,
- monthly balance,
- monthly gig-income,
- monthly utility spend,
- monthly EMI spend,
- monthly savings activity,
- monthly cash withdrawals,
- monthly charge events,
- monthly transaction count,
- monthly active income months.

### 7.3 Time-window policy

Use as much history as available, with a preferred window of 6–12 months.

### 7.4 Stability metrics

Derive:
- coefficient of variation,
- trend slope,
- month-to-month persistence,
- recurrence ratio,
- volatility inverse.

These are core inputs to P1, P2, P4, and P6.

---

## 8. Pillar Feature Computation Stage

### 8.1 P1 Income Stability

P1 should include normalized measures of:
- average monthly income,
- income volatility inverse,
- earning month ratio,
- income trend,
- balance consistency,
- recency of income,
- recurring gig pattern strength.

### 8.2 P2 Payment Discipline

P2 should include:
- utility payment punctuality,
- EMI punctuality,
- recurring payment consistency,
- bounce inverse,
- late fee inverse,
- payment rhythm stability.

### 8.3 P3 Debt Management

P3 should include:
- EMI-to-income ratio inverse,
- debt count inverse,
- outstanding debt inverse,
- credit utilization inverse,
- rollover risk,
- overdue behavior,
- debt band score.

### 8.4 P4 Savings Behaviour

P4 should include:
- average savings ratio,
- balance growth slope,
- buffer months,
- month-end surplus,
- liquidity ratio,
- withdrawal control,
- savings persistence.

### 8.5 P5 Work Identity

P5 should include:
- Aadhaar verification,
- PAN verification,
- face match score,
- document trust,
- address consistency,
- work proof strength,
- platform screenshot quality,
- employment consistency.

### 8.6 P6 Financial Resilience

P6 should include:
- insurance flags,
- emergency fund ratio,
- ITR history,
- coverage consistency,
- shock resilience,
- tax buffer indicators.

### 8.7 P7 Social Accountability

P7 should include:
- government scheme registration,
- worker registry linkage,
- formal enrollment,
- benefit stability,
- account linkage.

### 8.8 P8 Tax Compliance

P8 should include:
- ITR filing history,
- filing frequency,
- declared income ratio,
- GST registration,
- tax quality,
- tax consistency.

---

## 9. Feature Normalization Stage

### 9.1 Normalization goals

The pipeline should place every feature into a learned-friendly numeric range.

### 9.2 Normalization types

Use one of the following by feature class:
- min-max,
- bounded ratio normalization,
- capped inverse normalization,
- domain-anchor normalization,
- binary passthrough.

### 9.3 Inverse metrics

Where risk is bad, transform it as:

`score = 1 - normalized_risk`

### 9.4 Anchor normalization

For income-like values:

`normalized_value = raw_value / anchor`

Then cap to [0,1] or a narrow safe window.

### 9.5 Sanitization rules

All invalid values must become 0.50 or a context-specific fallback before scoring.

---

## 10. Train/Validation Split Stage

### 10.1 Split ratio

Use 80% training and 20% validation.

### 10.2 Stratification

Stratify by:
- work type,
- tier,
- target bucket.

### 10.3 Data leakage rules

Never let validation rows influence:
- feature statistics,
- calibration fit,
- SHAP training bins,
- meta-learner training.

### 10.4 OOF requirement

The meta-learner must be trained on out-of-fold pillar predictions only.

---

## 11. Pillar Model Training Stage

### 11.1 Models to train

Train ML models for:
- P1,
- P2,
- P3,
- P4,
- P6.

### 11.2 Model families

- P1: XGBoost regressor
- P2: XGBoost regressor
- P3: XGBoost regressor
- P4: XGBoost regressor
- P6: RandomForest regressor

### 11.3 Hyperparameter optimization

Use Optuna with 100 trials per pillar.

### 11.4 XGBoost search space

- `n_estimators`: 80–150
- `max_depth`: 3–4
- `learning_rate`: logarithmic search
- `subsample`: 0.6–1.0
- `colsample_bytree`: 0.5–1.0
- `gamma`: 0.0–1.0
- `min_child_weight`: 5–30
- `reg_alpha`: 0.0–0.5
- `reg_lambda`: 0.0–0.5

### 11.5 RandomForest search space

- `n_estimators`: 80–150
- `max_depth`: 3–4
- `min_samples_split`: 5–30
- `min_samples_leaf`: 5–20
- `max_features`: sqrt, log2, 0.7, 0.8

### 11.6 Mandatory tree method

XGBoost must use exact tree method for export safety.

### 11.7 Training output

For each model save:
- fitted model object,
- best parameters,
- validation metrics,
- feature importance ordering,
- calibration mapping,
- SHAP metadata.

---

## 12. Calibration Stage

### 12.1 Purpose

Calibration aligns raw model outputs to a more stable interpretation before they feed the meta-learner.

### 12.2 Calibration options

Use:
- isotonic regression when enough validation data exists,
- sigmoid calibration when data is limited.

### 12.3 Output format

Export calibration as:
- coefficients,
- threshold table,
- piecewise mapping,
- or lookup bins.

### 12.4 Order constraint

Calibration must happen after raw pillar validation and before confidence adjustment.

---

## 13. SHAP Extraction Stage

### 13.1 Offline SHAP computation

For each trained ML pillar:
1. Create TreeExplainer.
2. Compute SHAP values.
3. Compute feature bins.
4. Aggregate SHAP by feature bin.
5. Store the result in a compact lookup JSON.

### 13.2 Bin design

Use percentile bins, typically 10 bins per feature.

### 13.3 On-device lookup contract

At runtime the explanation layer should:
- read a feature value,
- determine bin index,
- retrieve precomputed SHAP impact,
- contribute it to the explanation ranking.

### 13.4 Explanation ranking

The explanation engine should rank:
- positive drivers,
- negative drivers,
- neutral or low-impact features.

---

## 14. Meta-Learner Training Stage

### 14.1 Input construction

Meta-learner inputs are:
- 8 pillar scores,
- 4 work-type one-hot flags,
- 8 interaction terms between P1/P2 and work type.

### 14.2 Why out-of-fold predictions matter

Using the same data to train pillar models and train the meta-learner would create leakage. The meta-learner must see only out-of-fold outputs.

### 14.3 Logistic regression model

Use a single logistic regression model.

### 14.4 Final output

The logistic regression produces a probability which is then scaled to the 300–900 score range.

### 14.5 Coefficient export

Export:
- coefficients,
- intercept,
- optional feature naming metadata.

---

## 15. Dart Export Stage

### 15.1 Export objective

The trained models must be converted into pure Dart implementation code or equivalent deterministic Dart arithmetic functions.

### 15.2 Export requirements

The exported Dart files must be:
- deterministic,
- small,
- dependency-free,
- inspectable,
- parity-verifiable.

### 15.3 Export artifacts

Export separate scorer modules for:
- P1,
- P2,
- P3,
- P4,
- P6.

Also export:
- meta coefficients,
- SHAP lookup tables,
- feature anchors,
- validation constants.

### 15.4 Export constraints

Do not export model logic that relies on:
- native runtimes,
- floating-point unstable shortcuts,
- hidden state,
- random operations.

---

## 16. Parity Testing Stage

### 16.1 Golden dataset

Create a fixed golden test set containing complete feature vectors and expected outputs.

### 16.2 Parity rule

Python and Dart outputs must match within tolerance.

### 16.3 Test categories

- feature parity,
- pillar parity,
- confidence parity,
- calibration parity,
- meta-learner parity,
- final score parity.

### 16.4 Failure policy

If parity fails:
1. identify whether the bug is in feature engineering, export, calibration, or scoring,
2. do not patch at random,
3. rerun the affected stage from source.

---

## 17. On-Device Inference Stage

### 17.1 Runtime flow

1. Receive profile.
2. Resolve raw inputs.
3. Generate 95 features.
4. Sanitize features.
5. Run pillar scorers.
6. Validate pillar outputs.
7. Compute confidence.
8. Calibrate and adjust.
9. Build meta-features.
10. Run logistic regression.
11. Compute final score.
12. Derive grade and risk band.
13. Build SHAP explanations.
14. Return ScoreReport.

### 17.2 Runtime guarantees

The runtime must be fast, deterministic, and safe from invalid numeric states.

---

## 18. Score Computation Stage

### 18.1 Final score formula

The final score is derived from meta-learner probability:

`score = round(300 + 600 * probability)`

### 18.2 Grade mapping

- 800–900: S
- 720–799: A
- 640–719: B
- 560–639: C
- 480–559: D
- 300–479: E

### 18.3 Risk band mapping

- 651+: Low
- 451–650: Medium
- 300–450: High

---

## 19. Confidence Adjustment Stage

### 19.1 Neutral fallback

If pillar confidence drops below threshold, set the pillar to 0.50.

### 19.2 Confidence-informed blending

A confidence-weighted adjustment should blend calibrated score with neutral score.

### 19.3 Why this matters

This ensures the score reflects evidence quality, not just numerical output.

---

## 20. Artifact Packaging Stage

### 20.1 Required offline artifacts

- feature schema,
- model training summary,
- calibration map,
- SHAP lookup,
- meta coefficients,
- golden test cases,
- parity test script.

### 20.2 Required runtime artifacts

- pillar scorers,
- confidence engine,
- scorecards,
- scorer constants,
- SHAP lookup reader,
- report generator.

---

## 21. Common Failure Modes

### 21.1 Feature mismatch

If training and runtime features differ, scores become meaningless.

### 21.2 Calibration drift

If calibration is fit incorrectly, the meta-learner gets distorted inputs.

### 21.3 Low-confidence overreach

If confidence is ignored, the system will over-score weakly supported users.

### 21.4 Export mismatch

If exported Dart arithmetic differs from Python, parity fails.

### 21.5 SHAP misuse

If SHAP is used to modify score instead of explain it, the architecture becomes unstable.

---

## 22. Engineering Acceptance Criteria

The ML pipeline is implementable only if all of the following are true:
- 95 features are frozen and documented,
- all pillar models are trained and validated,
- meta-learner is trained on OOF pillar outputs,
- calibration is exported,
- SHAP lookup tables are generated,
- Dart export succeeds,
- parity tests pass,
- the final score stays in 300–900,
- confidence handling is active,
- low-data gating works.

---

## 23. Implementation Checklist

### Data
- [ ] Synthetic generator completed
- [ ] Work-type stratification completed
- [ ] Tier labels defined

### Features
- [ ] Transaction tagging implemented
- [ ] Monthly aggregation implemented
- [ ] 95-feature map frozen
- [ ] Sanitizer implemented

### Models
- [ ] P1 trained
- [ ] P2 trained
- [ ] P3 trained
- [ ] P4 trained
- [ ] P6 trained
- [ ] P5/P7/P8 scorecards implemented

### Calibration and explainability
- [ ] Calibration exported
- [ ] SHAP lookup exported
- [ ] Reason ranking implemented

### Meta and runtime
- [ ] Meta-learner trained
- [ ] Dart export completed
- [ ] Parity tests passed
- [ ] ScoreReport generation implemented

---

## 24. Final Statement

This document defines the complete ML pipeline in a way that is intended to support direct implementation. It is deliberately explicit about model choice, data flow, calibration order, confidence handling, parity constraints, and runtime execution so that an agent should not need to infer missing architecture decisions.

If you want, I can convert this into a **single polished MD file artifact** and then create a second companion document with **pseudocode for every stage**.
