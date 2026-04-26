# GigCredit ML Reference: Evaluation Engine, Confidence Engine, and SHAP Explainability

Status: Reference specification for production-grade implementation
Audience: ML engineer, app engineer, backend engineer, QA, release owner
Purpose: Define an implementation blueprint for a deterministic, auditable, high-quality scoring system

---

## 1. Scope and Principles

This document defines the ML quality and reliability layer for the scoring stack, with focus on:

- Evaluation Engine (offline model quality and release gating)
- Confidence Engine (runtime trust adjustment and score stability)
- Explainability Engine (SHAP lookup based, explanation-only)

Design principles:

1. Determinism first
2. Privacy first (on-device scoring path)
3. Explicit contracts over implicit behavior
4. Release gates are objective and reproducible
5. Explainability must never alter score computation

---

## 2. Canonical Contracts

### 2.1 Feature and pillar contract

- Feature vector length: 95
- Canonical features: f_00 to f_94
- Pillar slices:
  - P1: indices 0 to 12
  - P2: indices 13 to 27
  - P3: indices 28 to 36
  - P4: indices 37 to 48
  - P5: indices 49 to 66
  - P6: indices 67 to 77
  - P7: indices 78 to 87
  - P8: indices 88 to 94

### 2.2 Meta-learner input contract

- Meta input length: 44
- Ordered layout:
  - 0 to 7: adjusted pillar scores P1..P8
  - 8 to 11: work-type one-hot [platform, vendor, tradesperson, freelancer]
  - 12 to 43: interactions Pi times work-type-j in nested order

### 2.3 Score output contract

- Probability domain: 0.0 to 1.0
- Final score mapping: round(300 + probability * 600)
- Final score bounds: 300 to 900
- Risk bands:
  - High: <= 450
  - Medium: 451 to 650
  - Low: >= 651

### 2.4 Minimum scoring gate

A score is only eligible when minimum onboarding proof is available:

- Step-1 complete
- Identity verification complete
- Bank statement processed with minimum transaction count

If gate fails:

- No normal scoring path
- Return ineligible state with explicit reason

---

## 3. End-to-End Scoring Pipeline

### 3.1 Runtime path (online scoring request)

1. Validate minimum gate
2. Sanitize raw features
3. Slice feature blocks by pillar contract
4. Run ML pillars (P1, P2, P3, P4, P6)
5. Run scorecards (P5, P7, P8)
6. Apply domain rule constraints (for example debt cap)
7. Apply confidence adjustments
8. Build 44-d meta input
9. Run standardized logistic meta-learner
10. Convert probability to score and risk band
11. Generate explainability summary (SHAP lookup)
12. Persist deterministic decision payload

### 3.2 Offline path (evaluation and release)

1. Build binary target from final label
2. Stratified train/val/test split
3. Train logistic meta model with cross-validation
4. Apply calibration candidates
5. Tune decision threshold
6. Run production gate checks
7. Run stress scenarios
8. Emit evaluation report
9. Block release if any required gate fails

---

## 4. Evaluation Engine Specification

### 4.1 Inputs

Required inputs:

- Dataset with f_00..f_94
- final_label column
- work_type column
- Trained pillar models for P1, P2, P3, P4, P6

Expected artifacts:

- real_ready_evaluation_report.json
- meta coefficients artifact
- model selection details

### 4.2 Target generation

Binary target strategy:

- Compute threshold by quantile (default 0.60) unless explicitly provided
- Convert final_label to binary with threshold
- Verify two-class target

Controls:

- label_quantile
- label_threshold override

### 4.3 Split strategy

- Train/Validation/Test default split: 70/15/15 equivalent from val_size and test_size
- Stratify on binary target
- Fixed random seed for reproducibility

### 4.4 Meta feature construction

Per sample:

1. Predict P1, P2, P3, P4, P6 from model slices
2. Compute P5, P7, P8 from scorecard means
3. Build work-type one-hot
4. Build 32 interactions
5. Concatenate into 44-d vector

### 4.5 Sanitization before calibration and scoring

Apply score-block sanitization against training score statistics:

- Compute z-score by pillar score dimension
- Compute deviation penalty if absolute z exceeds stability threshold
- Blend toward score mean based on deviation magnitude
- Rebuild full 44-d vector

Objective:

- Reduce brittle behavior under moderate shift/noise
- Preserve ranking where possible

### 4.6 Robust augmentation

Recommended robust augmentation sets over score-block:

- Gaussian noise at 1 percent
- Gaussian noise at 2 percent
- Gaussian noise at 3 percent
- Feature dropout at 5 percent to neutral row score
- Feature dropout at 10 percent to neutral row score
- Systematic downshift at 5 percent

Train logistic model on augmented stack for better stability under mild perturbations.

### 4.7 Model selection

Search dimensions:

- Solver: lbfgs, liblinear
- Class weight: none, balanced
- C grid: logarithmic sequence from low regularization to high flexibility

CV objective:

- Maximize train-only ROC-AUC under stratified folds

### 4.8 Calibration strategy

Candidates:

- none
- isotonic regression
- platt scaling

Selection baseline metric:

- Validation Brier score (lower is better)

Robust selection extension:

- Evaluate each calibration candidate across stress scenarios
- Build robust score combining baseline Brier and worst-shift penalties
- Select candidate with minimum robust score

### 4.9 Threshold tuning

Baseline tuning:

- Scan threshold in [0.05, 0.95]
- Optimize objective: Youden J or F1 or balanced accuracy

Robust tuning:

- Evaluate threshold on stressed validation probabilities
- Penalize thresholds that violate recall floor in worst scenario
- Penalize thresholds with poor baseline balanced accuracy

Fallback rule:

- If robust threshold breaks production gate, fallback to baseline threshold
- Log fallback reason in report

### 4.10 Metric bundle

Required metrics:

- ROC-AUC
- PR-AUC
- Brier score
- Log loss
- Precision
- Recall
- F1
- Specificity
- Balanced accuracy
- Threshold used

### 4.11 Production gate

Required checks and default thresholds:

- ROC-AUC >= 0.75
- PR-AUC >= 0.60
- Brier <= 0.20
- Recall >= 0.65
- Balanced accuracy >= 0.70

Gate decision:

- GO if all checks pass
- NO_GO otherwise

### 4.12 Stress gate

Required scenario families:

- Gaussian noise 1 percent
- Gaussian noise 3 percent
- Feature dropout 5 percent
- Feature dropout 10 percent
- Systematic downshift 5 percent

Default limits:

- Max ROC-AUC drop: 0.03
- Max PR-AUC drop: 0.04
- Max Brier increase: 0.02
- Min recall floor: 0.70

Scenario-specific exceptions can be explicit and documented, not implicit.

### 4.13 Evaluation report schema

Required top-level blocks:

- timestamp
- dataset
- target
- splits
- model_selection
- calibration
- threshold_tuning
- production_gate
- stress_test
- validation_metrics
- test_metrics

All numeric fields should be JSON numbers, not strings.

---

## 5. Confidence Engine Specification

### 5.1 Why confidence exists

Raw pillar predictions are not equally trustworthy. Confidence represents evidence quality and completeness. It stabilizes outputs when evidence is weak.

### 5.2 Canonical confidence adjustment formula

Adjusted pillar:

adjusted = raw * confidence + 0.5 * (1 - confidence)

Where:

- raw in [0, 1]
- confidence in [0, 1]
- 0.5 is neutral anchor

### 5.3 Hard low-confidence override policy

Recommended strict policy:

- If confidence < 0.30, set adjusted pillar to 0.50
- Mark pillar as Not enough data in UI

This avoids false certainty under sparse evidence.

### 5.4 Confidence dimensions

Confidence should be composite per pillar from evidence signals:

1. Completeness score
- Fraction of required fields present for pillar

2. Verification quality score
- Source reliability weight (verified API > OCR-only > user-entered)

3. Freshness score
- Penalize stale documents beyond allowed window

4. Consistency score
- Penalize contradictory cross-signals across steps

5. Signal quality score
- OCR confidence, parse confidence, extraction confidence

Composite suggestion:

confidence_pillar = w1*c + w2*v + w3*f + w4*k + w5*q

with weights summing to 1.0 and each component clamped to [0,1].

### 5.5 Runtime confidence contract

For each pillar P1..P8 produce:

- confidence value in [0,1]
- reason codes list
- missing_fields list
- low_confidence boolean

Suggested reason code taxonomy:

- missing_required_fields
- weak_source_proof
- low_ocr_confidence
- inconsistent_identity_signal
- stale_document
- low_transaction_volume

### 5.6 Per-pillar confidence guidance

P1 Income Stability:

- Bank statement coverage length
- Income signal stability quality
- Work proof consistency

P2 Payment Discipline:

- Bill/payment extraction completeness
- Recurring obligation identification confidence

P3 Debt Management:

- EMI extraction confidence
- Loan evidence verification status

P4 Savings Behaviour:

- Savings event detection confidence
- Month-over-month continuity quality

P5 Work and Identity:

- Identity verification status
- Work-type proof confidence

P6 Financial Resilience:

- Insurance and safety net field completeness
- Emergency buffer proxy confidence

P7 Social Accountability:

- Community/proof artifacts present and verified

P8 Tax Compliance:

- ITR/GST evidence quality and recency

### 5.7 Confidence and release quality

Confidence policy must be versioned and regression tested. Any change in policy should trigger:

- golden re-evaluation
- tolerance revalidation
- explainability consistency check

---

## 6. Explainability Engine (SHAP Lookup) Specification

### 6.1 Explainability boundary

Explainability is strictly post-score interpretation.

Non-negotiable rule:

- SHAP outputs must not feed back into probability or final score.

### 6.2 Artifact schema

shap_lookup.json structure:

- schema_version
- pillars object with keys p1, p2, p3, p4, p6
- per feature key f_XX:
  - edges length N+1
  - shap length N

Bin lookup semantics:

- choose bin where value in [edge_i, edge_{i+1})
- final bin includes upper boundary

### 6.3 Runtime lookup algorithm

For each explainable pillar feature:

1. Read feature value
2. Read edges and shap arrays
3. Locate bin index
4. Return contribution shap[index]

Aggregate:

- top positive drivers
- top negative drivers

### 6.4 Golden validation for SHAP

Use shap_golden_examples.json and assert for every record:

- selected_bin exact match
- expected_contribution match within strict float tolerance

Then run top-factor ranking parity on shared sample set.

### 6.5 Ranking stability guidance

Because close values can swap rank due to float ties, define tie-breaker:

1. Higher absolute contribution first
2. On ties, feature key lexical ascending

Document tie-breaker in contract to avoid platform drift.

### 6.6 UX wording guidance

Do:

- Say contributing factors or key drivers
- Present as estimate or contribution

Do not:

- Claim causal certainty
- Claim SHAP changed the score

---

## 7. Determinism and Parity Requirements

### 7.1 Determinism artifacts

Required:

- golden_inference_pack.json
- scoring_tolerance_policy.json
- meta_coefficients.json

### 7.2 Tolerance policy

Recommended defaults from current contract:

- Pillar probability absolute tolerance <= 0.005
- Final score tolerance <= 1 point
- Risk band exact match required

### 7.3 Cross-runtime parity

Validate parity across:

- Python reference implementation
- Dart runtime implementation
- Optional TFLite meta runtime if used

For each golden sample:

- Meta input ordering exact
- Probability delta within tolerance
- Score and risk band policy satisfied

---

## 8. Artifact and Versioning Requirements

Versioned artifacts:

- meta_coefficients.json
- shap_lookup.json
- feature_contract_freeze.json
- scoring_tolerance_policy.json
- artifact_manifest.json with checksums

Manifest should include:

- artifact name
- semantic version
- checksum
- generated timestamp
- source commit id

---

## 9. Failure Modes and Safeguards

### 9.1 Common failure modes

1. Feature index mismatch
2. Meta input ordering mismatch
3. Calibration method drift between offline and runtime
4. Confidence fixed at 1.0 in production by accident
5. SHAP bin-edge interpretation mismatch
6. Silent fallback to incompatible threshold

### 9.2 Mandatory safeguards

1. Contract assertions at startup
- feature length == 95
- meta length == 44

2. Build-time schema tests
- JSON field existence and types

3. Golden parity tests in CI
- score and risk parity checks

4. Gate-enforced release
- block deploy on NO_GO

5. Audit logs
- include model version, threshold version, confidence policy version

---

## 10. Implementation Blueprint for Perfect Scoring System

### 10.1 Build order

Phase A: Contracts

1. Freeze feature map and meta ordering
2. Freeze tolerance policy
3. Freeze SHAP schema and tie-breaker

Phase B: Evaluation engine hardening

1. Implement robust augmentation
2. Implement robust calibration selection
3. Implement robust threshold tuning with fallback
4. Emit full evaluation report and gate decisions

Phase C: Confidence engine hardening

1. Implement per-pillar confidence components
2. Add hard override for low confidence
3. Emit reason codes and missing fields
4. Add confidence regression tests

Phase D: Explainability hardening

1. Implement exact lookup and boundary handling
2. Add golden lookup tests
3. Add top-factor ranking determinism tests

Phase E: Integration hardening

1. Bind confidence outputs to scoring and UI
2. Validate golden parity end-to-end
3. Validate stress resilience in pre-release pipeline

### 10.2 Acceptance checklist

Functional:

- Minimum gate behavior correct
- Score mapping and risk bands correct
- Confidence adjustments applied per policy
- SHAP outputs generated and displayed

Quality:

- Production gate GO
- Stress gate GO
- Golden parity pass
- SHAP golden validation pass

Operational:

- Artifact manifest complete
- Checksums validated
- Versioned release notes generated

---

## 11. Recommended Test Matrix

### 11.1 Unit tests

- Feature sanitization edge cases (NaN, Inf, underflow, overflow)
- Meta input builder ordering test
- Confidence formula and hard-override tests
- SHAP bin boundary tests

### 11.2 Integration tests

- Minimum gate fail path
- Full scoring path with deterministic sample
- Confidence-lowered scenario changes pillar display state
- Explainability generation for each ML pillar

### 11.3 Regression tests

- Golden inference pack replay
- Threshold strategy fallback replay
- Calibration mode selection replay
- Stress scenarios metrics snapshot

---

## 12. Operational Monitoring Recommendations

Track in production-like telemetry:

- confidence distribution per pillar
- proportion of low-confidence overrides
- risk-band distribution drift
- calibration drift indicators (Brier trend)
- explainability feature frequency drift

Set alerts for:

- sudden confidence collapse in any pillar
- risk-band shift outside expected range
- repeated gate failure in pre-release runs

---

## 13. Explicit Current-State Notes to Resolve

Current code and artifact state indicates the following alignment tasks should be completed for perfect closure:

1. Confidence engine currently behaves as default-confidence for key ML pillars unless enriched runtime confidence is wired in. Move to full per-pillar confidence policy.
2. Keep robust threshold fallback behavior documented and test-covered to avoid silent policy drift.
3. Keep SHAP strictly explanation-only and verify with golden examples for every release.
4. Keep deterministic contracts and parity policy as release blockers, not informational checks.

---

## 14. Definition of Done for This ML Layer

This ML layer is done only when all conditions below hold:

1. Contracts frozen and versioned
2. Evaluation engine gates pass and are reproducible
3. Confidence engine is implemented with measurable evidence inputs
4. SHAP lookup runtime is deterministic and validated
5. Golden parity is green across all runtimes in scope
6. All artifacts are checksum-protected and release-traceable

When all six are true, scoring can be considered production-grade and implementation-complete.
