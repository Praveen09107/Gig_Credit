# DEV B — COMPLETE IMPLEMENTATION GUIDE (v3.0)

> **Role**: Flutter/Dart App — Scoring Engine + UI + On-Device XAI
> **Zero overlap with Dev A** — you never touch Python/ML/backend code.
> **Reference docs**: V3_17 through V3_22, V3_26-V3_28

---

# TABLE OF CONTENTS

1. [Your Responsibilities](#1-your-responsibilities)
2. [What You Do NOT Touch](#2-what-you-do-not-touch)
3. [What You Receive From Dev A](#3-what-you-receive-from-dev-a)
4. [Execution Order](#4-execution-order)
5. [Task B1: Data Models](#task-b1)
6. [Task B2: Feature Engineer Update](#task-b2)
7. [Task B3: Scoring Engine Update](#task-b3)
8. [Task B4: Confidence Engine (NEW)](#task-b4)
9. [Task B5: Meta-Learner (Dart)](#task-b5)
10. [Task B6: L1 Pillar Decomposition](#task-b6)
11. [Task B7: L2 Enhanced SHAP Lookup](#task-b7)
12. [Task B8: L3 Actionable Tagging](#task-b8)
13. [Task B9: L4 Trajectory Simulation](#task-b9)
14. [Task B10: L8 Causal Chain Rules](#task-b10)
15. [Task B11: Explanation Bundle](#task-b11)
16. [Task B12: Score Pipeline Rewrite](#task-b12)
17. [Task B13: Score Report UI](#task-b13)
18. [Task B14: Loan UI (4 Screens)](#task-b14)
19. [Task B15: API Service Classes](#task-b15)
20. [Task B16: Integration & Testing](#task-b16)
21. [Deliverables Checklist](#deliverables-checklist)

---

# 1. YOUR RESPONSIBILITIES

You own **all Flutter/Dart code** in `app/`. Specifically:

| Area | What You Build | Files |
|------|---------------|-------|
| Data Models | 11 model classes (new + modified) | `models/*.dart` |
| Feature Engineer | 115-feature extractor + normalisation | `scoring/features/feature_engineer.dart` |
| Scoring Engine | 8-pillar scorer with cross-pillar routing | `scoring/engine/scoring_engine.dart` |
| Confidence Engine | Conformal prediction confidence | `scoring/engine/confidence_engine.dart` (NEW) |
| Meta-Learner | 20-input LR dot-product | `scoring/engine/meta_learner.dart` |
| On-Device XAI | L1 + L2 + L3 + L4 + L8 | `scoring/explainability/*.dart` (5 files) |
| Explanation Bundle | Combines all XAI layers | `scoring/explainability/explanation_bundle.dart` |
| Score Pipeline | 6-stage orchestrator | `scoring/score_pipeline.dart` |
| Score Report UI | 10+ widgets, animations | `features/report/screens/*.dart` |
| Loan UI | 4 screens (products, KFS, apply, decision) | `features/loans/screens/*.dart` |
| API Services | HTTP clients for backend | `services/scoring_service.dart`, `loan_service.dart` |

# 2. WHAT YOU DO NOT TOUCH

- `ml_pipeline/` — Dev A only
- `backend/` — Dev A only
- Any `.py` files — Dev A only
- Model training, SHAP computation — Dev A only
- You DO NOT generate the Dart scorer files — Dev A generates them via m2cgen, you import them

# 3. WHAT YOU RECEIVE FROM DEV A

**10 Dart files** (copy to `app/lib/scoring/models/`):
- `p1_scorer.dart` (17 inputs), `p2_scorer.dart` (19), `p3_scorer.dart` (13), `p4_scorer.dart` (16), `p6_scorer.dart` (14)
- `scorecard_p5.dart` (18, KYC gate), `scorecard_p7.dart` (10), `scorecard_p8.dart` (7)
- `meta_learner_lr.dart` (20 inputs), `scoring_constants.dart`

**10 JSON files** (copy to `app/assets/constants/`):
- `shap_lookup_v3.json`, `tabnet_attention.json`, `calibration_knots.json`, `conformal_intervals.json`
- `meta_lr_coefficients.json`, `pillar_weights.json`, `actionability_tags.json`
- `feature_display_names.json`, `work_type_medians.json`, `causal_chains.json`

**1 Golden test file** (copy to `app/test/golden/`):
- `golden_100.json`

**Before integration**: You can work on ALL tasks B1-B15 using mock data. You only need Dev A's files for B16 (integration).

# 4. EXECUTION ORDER

```
B1: Data Models ──────────────────────────┐ (no dependency)
B2: Feature Engineer ─────────────────────┤ (needs B1)
B3: Scoring Engine ───────────────────────┤ (needs B1)
B4: Confidence Engine ────────────────────┤ (needs B1)
B5: Meta-Learner ─────────────────────────┤ (needs B1)
B6-B10: XAI Layers (parallel) ───────────┤ (needs B1)
B11: Explanation Bundle ──────────────────┤ (needs B6-B10)
B12: Score Pipeline ──────────────────────┤ (needs B2-B5, B11)
B13: Score Report UI ─────────────────────┤ (needs B1, parallel with B12)
B14: Loan UI ─────────────────────────────┤ (needs B1, parallel with B12)
B15: API Services ────────────────────────┤ (needs B1)
B16: Integration + Testing ───────────────┘ (needs ALL + Dev A deliverables)
```

**Critical path**: B1 → B2 → B3 → B12 → B16
**Parallelizable**: B6-B10, B13, B14, B15 can all run in parallel once B1 is done

---

# TASK B1: Data Models
**Ref**: V3_17

Create/modify 11 model classes. **Start here** — everything depends on these.

**Files to create**:
- [ ] `models/actionable_item.dart` — 3-tier (immediate/behavioural/non_actionable)
- [ ] `models/trajectory_result.dart` — 3-path score projection
- [ ] `models/causal_chain.dart` — root cause + chain + fix
- [ ] `models/conformal_interval.dart` — low/high/halfWidth
- [ ] `models/loan_decision_model.dart` — 4-bucket decision + AAN + counterfactuals
- [ ] `models/kfs_model.dart` — all RBI KFS fields
- [ ] `models/loan_product_model.dart` — with max_eligible_amount + score_gap

**Files to modify**:
- [ ] `models/score_report_model.dart` — add: pillarContributions (L1), trajectory (L4), causalChains (L8), overallConfidence, probability, workType, computeTimeMs. Add nullable server fields: llmExplanation, peerCohort, efs, deltaShap
- [ ] `models/score_pillar_model.dart` — add: code, rawScore, calibratedScore, conformalLow, conformalHigh, confidence, weight, attention. Change maxScore from fixed to per-pillar (150/125/85/90/70/70/55/55)
- [ ] `models/shap_factor_model.dart` — add: pillarLabel, meanAbsShap, actionType, actionText

---

# TASK B2: Feature Engineer Update
**File**: `app/lib/scoring/features/feature_engineer.dart`
**Ref**: V3_18, V3_26, V3_27

**3 things happen in extract()**:
1. Compute 95 base features from VerifiedProfile. **CRITICAL: Use the null-safety fallback pattern below**.
2. **NEW**: Normalise 5 features by work-type medians (Stage 1)
3. **NEW**: Compute 20 cross-pillar features f95-f114 (Stage 2)

**Missing Data Fallback Pattern (Zero Nulls allowed)**:
```dart
double getFeature(String key, VerifiedProfile profile) {
  double? raw = profile.extractFeature(key);   // 1. Try real value
  if (raw != null && !raw.isNaN && raw >= 0.0 && raw <= 1.0) return raw;
  return ScoringConstants.featureDefaults[key]!; // 2. Fall back to median
}
```

**Feature Sourcing Map**:
```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SOURCE 1 — Bank Statement OCR (P1, P2, P3, P4)
  Computable from parsed transactions:
  ✅ avg_monthly_income_norm       (mean of monthly credits)
  ✅ income_stability_cv           (std/mean of monthly credits)
  ✅ income_growth_slope           (linear regression slope, 6 months)
  ✅ utility_ontime_ratio          (utility debit timing vs due dates)
  ✅ emi_to_income_ratio           (outgoing EMI debits / total credits)
  ✅ bounce_count_norm             (returned cheques / total transactions)
  ✅ savings_rate_norm             (end-of-month balance trend)
  ✅ avg_balance_norm              (mean daily balance)
  → If bank OCR fails: USE feature_defaults.json

SOURCE 2 — KYC API Response (P5)
  ✅ aadhaar_verified              (UIDAI API boolean)
  ✅ pan_verified                  (IT API boolean)
  ✅ face_match_score              (Aadhaar face match confidence 0–1)
  ✅ address_match_score           (declared vs Aadhaar address match)
  ✅ dob_consistent                (DOB matches across documents)
  → These are ALWAYS available if user completed KYC

SOURCE 3 — Insurance OCR (P6)
  ✅ health_insurance_active       (policy active boolean)
  ✅ life_insurance_active         (policy active boolean)
  ✅ insurance_premium_norm        (monthly premium / income)
  → Default 0.0 if document not uploaded

SOURCE 4 — ITR/GST Upload (P8)
  ✅ itr_filed_binary              (ITR acknowledgement present)
  ✅ gst_registered                (GST certificate present)
  ✅ itr_income_vs_bank_match      (declared vs bank income ratio)
  → Default 0.0 if document not uploaded

SOURCE 5 — Onboarding Form (self-declared)
  ✅ declared_work_type            (from Step 2 selection)
  ✅ gig_experience_months_norm    (from Step 3 form input)
  ✅ eshram_enrolled               (from Step 6 checkbox)
  ⚠️ pmsym_active                 (checkbox — user may not know)
  → Use feature_defaults for uncertain self-declared fields

SOURCE 6 — NOT COLLECTABLE (use feature_defaults always)
  ❌ peer_review_score_norm        (no collection mechanism yet)
  ❌ customer_rating_norm          (platform API not integrated)
  ❌ multi_platform_count_norm     (cannot verify without platform API)
  ❌ advance_tax_paid              (requires CA letter — skip for demo)
  ❌ ppf_account_active            (no document upload for this yet)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RULE FOR DEV B: Features in Source 6 ALWAYS use
feature_defaults.json. Never attempt to compute them.
Add a comment in the code: // TODO: connect platform API post-hackathon
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Array size changes from 95 to 115**.

**New P8 features** (f88-f94): Extract from `profile.taxInfo` and `profile.govSchemesInfo`.

**Work-type normalisation**: Divide 5 features by work-type median, clamp to [0,2], divide by 2.
```dart
features[1] = (features[1] / median['income_cv']).clamp(0.0, 2.0) / 2.0;
```

**Cross-pillar features**: 20 deterministic formulas using existing features (see V3_26 for all formulas). Group F (f112-f114) defaults to 0.50 (no time-series on device).

**Checklist**:
- [ ] Array size = 115 (not 95)
- [ ] P8 features extracted (f88-f94)
- [ ] Work-type normalisation runs on f1, f2, f4, f28, f47
- [ ] Cross-pillar features computed (f95-f114)
- [ ] All values clamped to [0, 1]

---

# TASK B3: Scoring Engine Update
**File**: `app/lib/scoring/engine/scoring_engine.dart`
**Ref**: V3_18

**Each ML scorer now receives base + cross-pillar features**:
```dart
'P1': scoreP1([...f.sublist(0, 13), f[95], f[96], f[97], f[98]]),    // 17
'P2': scoreP2([...f.sublist(13, 28), f[105], f[106], f[107], f[108]]), // 19
'P3': scoreP3([...f.sublist(28, 37), f[95], f[96], f[97], f[98]]),    // 13
'P4': scoreP4([...f.sublist(37, 49), f[99], f[100], f[101], f[102]]), // 16
'P5': scoreP5(f.sublist(49, 67)),                                      // 18
'P6': scoreP6([...f.sublist(67, 78), f[102], f[103], f[104]]),        // 14
'P7': scoreP7(f.sublist(78, 88)),                                      // 10
'P8': scoreP8(f.sublist(88, 95)),                                      // 7
```

**P5 KYC Gate**: If f[49] < 0.5 or f[50] < 0.5, force P5 = 0.0.

**Calibration**: Add isotonic calibration using knots from `calibration_knots.json`. Only for P1, P2, P3, P4, P6.

**Exact Isotonic Math Function (Use verbatim)**:
```dart
/// Sklearn-compatible isotonic interpolation.
/// Matches sklearn.isotonic.IsotonicRegression.predict() exactly.
/// [xKnots] and [yKnots] are from calibration_knots.json per pillar.
double isotonicInterpolate(
    double x, List<double> xKnots, List<double> yKnots) {

  // Below lower bound → return leftmost y (sklearn clips, not extrapolates)
  if (x <= xKnots.first) return yKnots.first;

  // Above upper bound → return rightmost y (sklearn clips, not extrapolates)
  if (x >= xKnots.last) return yKnots.last;

  // Binary search for the interval [xKnots[i], xKnots[i+1]] containing x
  int lo = 0, hi = xKnots.length - 2;
  while (lo < hi) {
    int mid = (lo + hi) ~/ 2;
    if (xKnots[mid + 1] < x) { lo = mid + 1; } else { hi = mid; }
  }

  // Linear interpolation within interval (piecewise linear = sklearn default)
  double t = (x - xKnots[lo]) / (xKnots[lo + 1] - xKnots[lo]);
  return yKnots[lo] + t * (yKnots[lo + 1] - yKnots[lo]);
}
```

**Checklist**:
- [ ] Cross-pillar indices match V3_26 routing table exactly
- [ ] Input sizes: P1=17, P2=19, P3=13, P4=16, P5=18, P6=14, P7=10, P8=7
- [ ] P5 KYC gate implemented
- [ ] Isotonic calibration applied to 5 ML pillars
- [ ] All outputs clamped to [0, 1]

---

# TASK B4: Confidence Engine (NEW)
**File**: `app/lib/scoring/engine/confidence_engine.dart`
**Ref**: V3_18

**Replaces** the old formula `0.5 × completeness + 0.3 × reliability + 0.2 × consistency`.

Uses `conformal_intervals.json` to compute per-pillar confidence:
- `2 × half_width ≤ 0.12` → confidence = 1.0 (HIGH)
- `2 × half_width ≤ 0.20` → confidence = 0.75 (MEDIUM)
- `2 × half_width > 0.20` → confidence = 0.50 (LOW)

Scorecard pillars (P5, P7, P8) always get confidence = 1.0.

**Score adjustment**: `adjusted = score × confidence + 0.50 × (1 - confidence)`

---

# TASK B5: Meta-Learner (Dart)
**File**: `app/lib/scoring/engine/meta_learner.dart`
**Ref**: V3_18

**20 inputs** (NOT 24):
- [0-7]: 8 calibrated pillar scores
- [8-15]: 8 conformal confidence values
- [16-19]: 4 cross-pillar features at indices from `top4_cross_pillar_indices` in JSON

**Implementation**: Simple sigmoid dot-product:
```dart
double z = intercept;
for (int i = 0; i < 20; i++) z += input[i] * coefficients[i];
return 1.0 / (1.0 + math.exp(-z));
```

---

# TASK B6: L1 Pillar Decomposition
**File**: `app/lib/scoring/explainability/layer1_pillar_decomp.dart`
**Ref**: V3_19

Pure arithmetic — no SHAP, no JSON lookup. Decomposes final score into per-pillar point contributions using `adjusted_score × weight × meta_coefficient`. Normalises to sum to `finalScore - 300`.

**User sees**: Waterfall chart showing "P1 contributed +142 pts, P2 +118 pts..."

---

# TASK B7: L2 Enhanced SHAP Lookup
**File**: `app/lib/scoring/explainability/layer2_shap_lookup.dart`
**Ref**: V3_19

Loads `shap_lookup_v3.json`. For each feature: look up work-type-specific SHAP array, find bin index from feature value, get impact. Sort by absolute impact. Return top 5 positive + top 5 negative.

Also computes **pillar-level SHAP aggregation** (sum feature SHAPs per pillar).

---

# TASK B8: L3 Actionable Tagging
**File**: `app/lib/scoring/explainability/layer3_actionable.dart`
**Ref**: V3_19

Loads `actionability_tags.json`. For each negative SHAP factor:
- 🔴 `non_actionable` → **NEVER show** as improvement suggestion
- 🟢 `immediate` → Show with "easy • 1-7 days" badge
- 🟡 `behavioural` → Show with "medium • 1-3 months" badge

Sort: 🟢 first, then 🟡, then by expected_gain_pts. Max 8 items.

---

# TASK B9: L4 Trajectory Simulation
**File**: `app/lib/scoring/explainability/layer4_trajectory.dart`
**Ref**: V3_19

3 projected score paths:
- **7-day**: Only 🟢 immediate actions (top 3)
- **1-3 months**: Immediate + top 2 behavioural
- **Full potential**: All top 5 actions

Each path shows projected score + projected grade.

---

# TASK B10: L8 Causal Chain Rules
**File**: `app/lib/scoring/explainability/layer8_causal_rules.dart`
**Ref**: V3_19

Loads `causal_chains.json` (15 rules). For each rule: check trigger conditions against feature values, check work_type applicability. Return max 3 matched chains.

**Exact Evaluator Logic (Use verbatim)**:
```dart
bool evaluateRule(CausalRule rule, List<double> features) {
  List<bool> results = rule.triggers.map((t) {
    double val = features[t.featureIndex];
    return switch (t.operator) {
      ">"  => val > t.threshold,
      "<"  => val < t.threshold,
      ">=" => val >= t.threshold,
      "<=" => val <= t.threshold,
      _    => false,
    };
  }).toList();
  return rule.triggerLogic == "AND"
      ? results.every((r) => r)
      : results.any((r) => r);
}
```

---

# TASK B11: Explanation Bundle
**File**: `app/lib/scoring/explainability/explanation_bundle.dart`
**Ref**: V3_19

Combines L1 + L2 + L3 + L4 + L8 into a single `ExplanationBundle` object. Called once after scoring. Target: total < 8ms.

---

# TASK B12: Score Pipeline Rewrite
**File**: `app/lib/scoring/score_pipeline.dart`
**Ref**: V3_22

**The main orchestrator — 6 stages**:

```
Stage 1: FeatureEngineer.extract() → 115 features (includes normalisation + cross-pillar)
Stage 3: ScoringEngine.scorePillars() → 8 raw scores (with cross-pillar routing)
         → P5 KYC gate → calibrate ML pillars (isotonic)
Stage 4: ConfidenceEngine.compute() → 8 confidence values
         → adjust scores by confidence
Stage 5: MetaLearner.predict(20 inputs) → probability
Stage 6: probability × 600 + 300 → GigCredit score (300-900)
         → ExplanationBundle.compute() (L1+L2+L3+L4+L8)
```

**Loads 10 JSON files at startup** (via main.dart asset loader).

**Builds ScoreReportModel** with all fields: score, grade, 8 pillars, pillar contributions, strengths, concerns, actions, trajectory, causal chains, conformal intervals.

---

# TASK B13: Score Report UI
**File**: `features/report/screens/score_report_screen.dart`
**Ref**: V3_20

**10 widgets** (top to bottom):

| # | Widget | XAI Layer | What It Shows |
|---|--------|-----------|---------------|
| 1 | ScoreGaugeWidget | — | Animated circular gauge 300→final, grade badge |
| 2 | PillarWaterfallChart | **L1** | Stacked horizontal bars, per-pillar point contribution |
| 3 | PillarRadarChart | — | 8-axis radar with conformal band |
| 4 | StrengthCards | **L2** | Green cards, top 3-5 positive SHAP factors |
| 5 | ConcernCards | **L2+L3** | Orange cards, only 🟢/🟡 items, never 🔴 |
| 6 | PillarDetailCards (×8) | — | Expandable, score bar + conformal range |
| 7 | CausalInsightCard | **L8** | Root cause chain (only if triggered) |
| 8 | ActionImprovementCards | **L3** | Tagged actions with difficulty + horizon + gain |
| 9 | TrajectoryWidget | **L4** | 3-path timeline (7d / 1-3mo / full) |
| 10 | LoanButton + Share | — | Navigate to loan flow |

**Animations**: Score count-up (1.5s), staggered waterfall bars (100ms), radar grow-in (0.8s), strength cards slide-left, concern cards slide-right.

**Server enrichment** (when connected — call POST /explain/full):
- L7 peer cohort section, L6 EFS note, L9 Delta-SHAP, L10 NL report

---

# TASK B14: Loan UI (4 Screens)
**Ref**: V3_21

**Screen 1 — Product Selection**: Show 3 products, eligible ones with max_eligible_amount, ineligible greyed with score gap. Risk-based interest rate displayed.

**Screen 2 — KFS Display**: All RBI-mandatory fields. Checkbox MUST be checked to proceed. Cooling-off period highlighted.

**Screen 3 — Application**: Amount slider capped at max_eligible_amount. Live EMI recalculation. Affordability preview (DSCR, EMI ratio).

**Screen 4 — Decision**: Two states:
- **Approved**: Green card + approval details + upgrade counterfactual
- **Rejected**: AAN (primary + secondary reasons) + 3 DiCE paths + alternative product offer. Amount adjustment path ALWAYS present.

---

# TASK B15: API Service Classes
**Files**: `services/scoring_service.dart`, `services/loan_service.dart`

HTTP clients for backend endpoints:
- `storeScore()` → POST /score/store
- `getExplanation()` → POST /explain/full
- `getProducts()` → POST /loan/products
- `getKfs()` → POST /loan/kfs
- `applyForLoan()` → POST /loan/apply

All with error handling and offline fallback.

---

# TASK B16: Integration & Testing
**Ref**: V3_23

1. Copy Dev A's 10 Dart files → `app/lib/scoring/models/`
2. Copy 10 JSON files → `app/assets/constants/`
3. Update `pubspec.yaml` assets section (10 entries)
4. Delete old files (`meta_scorer.dart`, etc.)
5. Run `dart analyze lib/scoring/` → zero errors
6. Copy `golden_100.json` → `app/test/golden/`
7. Run golden parity test (100 profiles, ±5 score tolerance)
8. Run full smoke test on device (8 pillars, XAI, loan flow)

---

# DELIVERABLES CHECKLIST

## Data Models (Task B1)
- [ ] ActionableItem — 3-tier actionable/behavioural/non_actionable
- [ ] TrajectoryResult + TrajectoryPath — 3 future paths
- [ ] CausalChain — root cause chain model
- [ ] ConformalInterval — low/high/halfWidth
- [ ] LoanDecisionModel + AanResult + CounterfactualPath + AlternativeOffer
- [ ] KfsModel — all RBI fields
- [ ] LoanProductModel — with maxEligibleAmount
- [ ] ScoreReportModel updated — 8 pillars, XAI fields, server-enriched nullables
- [ ] ScorePillarModel updated — conformal bounds, confidence, weight
- [ ] ShapFactorModel updated — actionType, pillarLabel

## Scoring Engine (Tasks B2-B5)
- [ ] FeatureEngineer: 115 features, work-type normalisation, cross-pillar
- [ ] ScoringEngine: 8 pillars with correct cross-pillar routing
- [ ] P5 KYC gate: returns 0 if Aadhaar OR PAN not verified
- [ ] Isotonic calibration: applied to P1, P2, P3, P4, P6 only
- [ ] ConfidenceEngine: conformal-based (not old formula)
- [ ] MetaLearner: 20 inputs, sigmoid dot-product
- [ ] Score mapping: 300-900, grades A+ through D

## On-Device XAI (Tasks B6-B11)
- [ ] L1 Pillar Decomposition: waterfall points that sum to score-300
- [ ] L2 Enhanced SHAP: 20-bin, work-type-aware, 115 features, pillar aggregation
- [ ] L3 Actionable Tagging: 🟢🟡🔴, never show 🔴 as improvement
- [ ] L4 Trajectory: 3 paths (7d / 1-3mo / full), projected score + grade
- [ ] L8 Causal Rules: 15 patterns, max 3 shown
- [ ] ExplanationBundle: combines all, < 8ms total

## Score Pipeline (Task B12)
- [ ] Loads 10 JSON files at startup
- [ ] 6-stage pipeline in correct order
- [ ] Builds complete ScoreReportModel

## Score Report UI (Task B13)
- [ ] ScoreGaugeWidget with count-up animation
- [ ] PillarWaterfallChart (L1) with staggered bars
- [ ] PillarRadarChart with 8 axes + conformal band
- [ ] StrengthCards (L2) — green, top 5 positive
- [ ] ConcernCards (L2+L3) — orange, only 🟢/🟡 factors
- [ ] 8 PillarDetailCards with conformal range bars
- [ ] CausalInsightCard (L8) — shows if triggered
- [ ] ActionImprovementCards (L3) — difficulty + horizon + gain
- [ ] TrajectoryWidget (L4) — 3-path timeline
- [ ] Server enrichment (L7/L6/L9/L10) when connected

## Loan UI (Task B14)
- [ ] Product Selection: 3 products, max eligible, ineligible greyed with gap
- [ ] KFS Display: all RBI fields, mandatory checkbox
- [ ] Application: slider ≤ max_eligible, live EMI, affordability preview
- [ ] Decision Approved: card + upgrade counterfactual
- [ ] Decision Rejected: AAN + 3 DiCE paths + alternative + amount adjustment

## Integration (Task B16)
- [ ] 10 Dart scorer files copied and imported
- [ ] 10 JSON assets copied and registered in pubspec.yaml
- [ ] Old files deleted (meta_scorer.dart, etc.)
- [ ] `dart analyze` passes clean
- [ ] Golden parity: 100/100 within ±5 pts
- [ ] Full smoke test: 8 pillars, XAI, loan flow, dark mode
