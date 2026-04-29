# V3.0 Architecture Overview (CORRECTED)

## Full Pipeline — 6 Stages

```
VerifiedProfile (from onboarding/OCR — FROZEN, do not touch)
        ↓
STAGE 1: Feature Engineering + Work-Type Normalisation
  ├── Extract 95 base features from VerifiedProfile
  ├── Normalise 5 features by work-type medians (JSON lookup + division)
  └── Output: 95 features (5 rescaled)
        ↓
STAGE 2: Cross-Pillar Feature Engineering (95 → 115)
  ├── 20 deterministic interaction features (Groups A-F)
  └── Output: 115-element feature vector
        ↓
STAGE 3: Eight Pillar Models (run in parallel)
  ├── P1: LightGBM GBDT (13 base + 4 cross = 17 features) → raw score
  ├── P2: XGBoost GBDT (15 base + 4 cross = 19 features)  → raw score
  ├── P3: XGBoost shallow depth=2 (9 base + 4 cross = 13)  → raw score
  ├── P4: LightGBM GBDT (12 base + 4 cross = 16 features) → raw score
  ├── P5: Dart Scorecard (18 features, KYC gate)            → raw score
  ├── P6: ExtraTreesRegressor (11 base + 3 cross = 14)     → raw score
  ├── P7: Dart Scorecard (10 features)                      → raw score
  └── P8: Dart Scorecard (7 features)                       → raw score
        ↓
  Calibrate 5 ML pillars via isotonic regression knots
        ↓
STAGE 4: Conformal Prediction Confidence Engine
  ├── Per-pillar × per-work-type confidence from conformal intervals
  ├── Replaces old manual formula (0.5×completeness + 0.3×reliability + 0.2×consistency)
  ├── Provable 90% coverage guarantee
  └── Adjust uncertain pillar scores toward 0.50
        ↓
STAGE 5: Logistic Meta-Learner → probability
  ├── 20 inputs: 8 pillar scores + 8 confidence values + 4 cross-pillar features
  ├── LogisticRegression dot-product (30 lines of Dart)
  └── Output: probability [0,1]
        ↓
STAGE 6: Score Mapping (300-900) + Grade + Risk Band
  ├── GigCredit Score = round(300 + probability × 600)
  ├── Grade: A+ (800+), A (750+), B+ (700+), B (650+), C+ (600+), C (550+), D (<550)
  └── Risk: Low (700+), Medium (550-699), High (<550)
```

---

## On-Device Explainability (runs after scoring, always available)

```
STAGE 6 output (final score + pillar scores)
        ↓
L1: Pillar Contribution Decomposition (pure arithmetic)
  → "P1 contributed 142 pts, P2 contributed 118 pts..."
        ↓
L2: Enhanced SHAP Lookup (20-bin, work-type-aware JSON)
  → Top 5 strengths + Top 5 concerns per feature
        ↓
L3: Actionable/Non-Actionable Tagging (3-tier JSON)
  → 🟢 Immediate / 🟡 Behavioural / 🔴 Non-actionable
        ↓
L4: Score Trajectory Simulation
  → "Reach 687 in 7 days by uploading insurance (+18 pts)"
        ↓
L8: Causal Chain Rules (on-device, 15 pattern rules)
  → "Your debt is high because income is seasonal — stabilise income first"
```

## Server-Side Explainability (when connected)

```
L5: Live SHAP (exact, per-model-type: LightGBM/XGBoost/ExtraTrees)
L6: Explanation Faithfulness Score (50-run perturbation test)
L7: Peer Cohort Mirror (25 nearest neighbours comparison)
L8-server: Full DoWhy causal graph
L9: Delta-SHAP (returning users: every score change point explained)
L10: LLM Translation (Gemini → Tamil/Hindi/Telugu/Kannada/English)
```

---

## Loan Decision Pipeline (Server-Side)

```
Score Report
  → POST /api/v1/loan/products → show eligible products + max amount
  → POST /api/v1/loan/kfs → RBI Key Fact Statement (MUST acknowledge)
  → POST /api/v1/loan/apply → 3-stage decision:
      ├── Gate 1: Hard Rules (7 binary checks — regulatory)
      ├── Gate 2: Affordability (DSCR ≥ 1.25, EMI ratio ≤ 50%, LTI ≤ 10×)
      └── Gate 3: LightGBM Classifier (18 features → repay probability)
  → Decision: approved | rejected
      ├── If approved: risk-based interest rate (12-24% by score)
      └── If rejected: AAN + 3 DiCE counterfactual paths + alternative product
```

---

## Technology Stack

| Component | Technology | Owner |
|-----------|-----------|-------|
| P1 scorer | LightGBM → m2cgen → Dart | Dev A generates, Dev B imports |
| P2 scorer | XGBoost → m2cgen → Dart | Dev A generates, Dev B imports |
| P3 scorer | XGBoost (shallow) → m2cgen → Dart | Dev A generates, Dev B imports |
| P4 scorer | LightGBM → m2cgen → Dart | Dev A generates, Dev B imports |
| P5 scorer | Hand-written Dart scorecard | Dev A writes |
| P6 scorer | ExtraTrees → m2cgen → Dart | Dev A generates, Dev B imports |
| P7 scorer | Hand-written Dart scorecard | Dev A writes |
| P8 scorer | Hand-written Dart scorecard | Dev A writes |
| Meta-learner | LogisticRegression → Dart dot-product | Dev A trains, Dev B implements |
| JSON constants | 11 files (Python → JSON) | Dev A generates, Dev B loads |
| Backend | FastAPI + MongoDB | Dev A |
| Flutter app | Dart + Flutter | Dev B |
| Explainability | L1-L4,L8 on-device / L5-L10 server | Dev B (on-device) / Dev A (server) |
| Fairness | Python service (async) | Dev A |
| Audit trail | SHA-256 hash chain + MongoDB | Dev A |

---

## Boundary Contract — FROZEN

The `VerifiedDataBundle` output from onboarding/OCR is **strictly frozen**. No changes permitted upstream of scoring engine. All new features are computed FROM the existing verified data.

---

## Feature Count Summary

| Count | What |
|-------|------|
| 95 | Base features (from VerifiedProfile) |
| 5 | Work-type normalised (rescaled in place) |
| 20 | Cross-pillar features (indices 95-114) |
| **115** | **Total feature vector** |
