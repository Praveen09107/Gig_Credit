# GigCredit — Full End-to-End System Design
## Part 2: OCR, Scoring, XAI, Loan Pipeline & Backend

---

## 7. OCR & DOCUMENT PIPELINE

### 7.1 Service Architecture

```
DocumentUploadCard widget
    │
    ├── ocrServiceProvider (Riverpod)
    │       ├── DemoOcrService  (demo mode — loads from assets JSON)
    │       └── RealOcrService  (production — PaddleOCR + Syncfusion)
    │
    └── onExtracted callback → parent screen handler
```

### 7.2 DemoOcrService (`demo_ocr_service.dart`)
- Loads `assets/ocr/expected_outputs.json` (cached after first load)
- Returns pre-defined structured data per `docType` key
- 1800ms simulated delay for realism
- `_lowconf` suffix forces fallback contract path
- Used in demo/test environments

### 7.3 RealOcrService (`real_ocr_service.dart`)

**PDF Path:**
```
File.readAsBytes() → PdfDocument → PdfTextExtractor.extractText(page) → raw text
Confidence: 0.95 (direct text extraction)
```

**Image Path:**
```
PaddleOcrFlutter.init() → _ocr.recognize(imagePath) → List<OcrResult>
Each result has .text → join all lines → raw text string
```

**Document Classification (keyword matching):**
| DocType | Required Keywords |
|---|---|
| `aadhaar_front/back` | AADHAAR, AADHAR, UIDAI |
| `pan` | INCOMETAX, PERMANENTACCOUNT, PAN pattern `[A-Z]{5}\d{4}[A-Z]` |
| `bank_statement` | HDFCBANK, ICICIBANK, BALANCE, ACCOUNTSTATEMENT |
| `utility_*` | BILL, INVOICE, AMOUNT, PAYMENT, DUE |
| `work_rc` | REGISTRATION, VEHICLE, CHASSIS, ENGINE |
| `work_dl_front/back` | DRIVING, LICENCE, TRANSPORT |
| `gov_eshram` | ESHRAM, SHRAM, UAN, LABOUR |

**Field Extraction (current implementation):**
- Aadhaar number: regex `\d{4}\s?\d{4}\s?\d{4}`
- PAN number: regex `[A-Z]{5}\d{4}[A-Z]`
- All other docs: **raw text only** — no structured field extraction

**Error handling:** Wrong doc in wrong slot throws specific exception (e.g., "PAN in Aadhaar section") — caught by DocumentUploadCard, shown as error snackbar.

### 7.4 OCR Results Storage
```dart
ocrResultsProvider  // Map<String, Map<String, dynamic>>
  'aadhaar_front' → {aadhaar_number, raw_text, confidence, image_path}
  'aadhaar_back'  → {raw_text, confidence, image_path}
  'pan'           → {pan_number, raw_text, confidence, image_path}
  'bank_statement'→ {raw_text, parsed: true, statement_verified: true}
  'selfie'        → {image_path}
  // Steps 4-9 doc types stored similarly
```

---

## 8. ON-DEVICE SCORING PIPELINE

**Entry point:** `ScoreGeneratingScreen` → calls `ScorePipeline.execute()`

### 8.1 The 6-Stage Pipeline (`score_pipeline.dart`)

```
Stage 1: Feature Extraction
    FeatureEngineer.extract(profile) → List<double> [115 features]

Stage 3: Pillar Scoring
    ScoringEngine.scorePillars(features) → Map<String, double> rawScores
    ScoringEngine.calibrateScores(rawScores, calibrationKnotsJson) → calibrated

Stage 4: Confidence Bounds
    ConfidenceEngine.computeConfidence(workType, conformalIntervalsJson) → confidences
    ConfidenceEngine.adjustScores(calibratedScores, confidences) → adjustedScores

Stage 5: Meta-Learner
    MetaLearner.predict(adjustedScores, confidences, features, metaJson) → probability [0,1]

Stage 6: Score Mapping
    finalScore = (probability × 600 + 300).clamp(300, 900)
    ExplanationBundle.compute(...) → XAI bundle

Output: ScoreReportModel
```

### 8.2 Feature Engineering (`feature_engineer.dart`)

115 features in total, organized as:

| Range | Description | Source |
|---|---|---|
| f[0–12] | P1: Income features | Bank OCR / self-declared |
| f[13–27] | P2: Spending/obligations | Bank OCR |
| f[28–36] | P3: Debt servicing | EMI data / bank |
| f[37–48] | P4: Savings trajectory | Bank OCR |
| f[49–66] | P5: Identity/KYC | KYC verification results |
| f[67–77] | P6: Safety nets | Insurance / scheme data |
| f[78–87] | P7: Social accountability | Scheme enrollment |
| f[88–94] | P8: Tax/compliance | ITR/GST data |
| f[95–114] | Cross-pillar features | Derived from above |

**Current real feature mappings** (`profile_extractor_extension.dart`):
```dart
'avg_monthly_income_norm' → bankInfo.isVerified ? 0.42 : null  // HARDCODED
'income_stability_cv'     → 0.6   // MOCK
'income_growth_slope'     → 0.5   // MOCK
'aadhaar_verified'        → kycInfo.isVerified ? 1.0 : 0.0
'pan_verified'            → kycInfo.isVerified ? 1.0 : 0.0
'health_insurance_active' → insuranceInfo.isVerified ? 1.0 : 0.0
'itr_filed_binary'        → taxInfo.isVerified ? 1.0 : 0.0
```

**Fallback:** Any feature not mapped returns `ScoringConstants.featureDefaults[key] ?? 0.5`

### 8.3 Scoring Engine (`scoring_engine.dart`)

**8 Pillar Models:**

| Pillar | Model Type | File Size | Max Points | Features Used |
|---|---|---|---|---|
| P1 Income Reliability | m2cgen decision tree | 998KB | 150 | f[0–12] + f[95–98] |
| P2 Spending & Obligations | m2cgen decision tree | 542KB | 125 | f[13–27] + f[105–108] |
| P3 Debt Servicing | m2cgen decision tree | 28KB | 85 | f[28–36] + f[95–98] |
| P4 Savings Trajectory | m2cgen decision tree | 842KB | 90 | f[37–48] + f[99–102] |
| P5 Identity & KYC | Hand-written scorecard | — | 70 | f[49–66] (18 features) |
| P6 Safety Nets | m2cgen random forest | 5.9MB | 70 | f[67–77] + f[102–104] |
| P7 Social Accountability | Hand-written scorecard | — | 55 | f[78–87] (10 features) |
| P8 Tax & Compliance | Hand-written scorecard | — | 55 | f[88–94] (7 features) |

**P5/P7/P8 Scorecards:** Weighted dot-product of features against static weight arrays. Outputs [0,1].

**Calibration:** Only P1,P2,P3,P4,P6 get isotonic calibration:
```dart
isotonicInterpolate(rawScore, xKnots, yKnots)
// Piecewise linear interpolation matching sklearn's IsotonicRegression.predict()
// Loaded from calibration_knots.json asset
```

### 8.4 Confidence Engine (`confidence_engine.dart`)

```
For ML pillars (P1,P2,P3,P4,P6):
  halfWidth = conformalIntervalsJson[pillar][workType]
  intervalWidth = 2 × halfWidth
  if width ≤ 0.12 → confidence = 1.0 (HIGH)
  if width ≤ 0.20 → confidence = 0.75 (MEDIUM)
  else            → confidence = 0.50 (LOW)

For scorecard pillars (P5,P7,P8): confidence = 1.0 always

Score adjustment:
  adjusted = score × confidence + 0.50 × (1 - confidence)
```

### 8.5 Meta-Learner (`meta_learner.dart` + `meta_learner_lr.dart`)

**20-element input vector:**
- [0–7]: 8 adjusted pillar scores (P1–P8)
- [8–15]: 8 confidence values
- [16–19]: 4 cross-pillar features (from `top4_cross_pillar_indices` in meta JSON)

**Logistic regression:**
```dart
static const List<double> weights = [
  1.958723, 2.307520, -0.005181, 0.747076, 0.772355, 1.329725,
  0.261285, 0.212566, -0.414957×8, -0.085551, 0.110737, -0.113928, 0.097271
];
static const double intercept = -0.534658;

probability = sigmoid(intercept + sum(features[i] × weights[i]))
finalScore = (probability × 600 + 300).clamp(300, 900)
```

---

## 9. XAI EXPLAINABILITY PIPELINE (5 Layers)

**Entry:** `ExplanationBundle.compute(...)` — runs all 5 layers synchronously on-device.

### Layer 1 — Pillar Decomposition (`layer1_pillar_decomp.dart`)
- Computes each pillar's % contribution to final score
- Uses adjusted scores × weights from `weights.json`
- Output: `Map<String, int> pillarContributions` (e.g., P1: 32%)

### Layer 2 — SHAP Lookup (`layer2_shap_lookup.dart`)
- Pre-computed SHAP values in `shap_lookup.json` (per feature, per work type, 20 bins)
- For each feature: bin the value → look up SHAP impact
- Sort by absolute impact → top 5 positive = `topStrengths`, top 5 negative = `topConcerns`
- Each factor has: `featureName`, `direction`, `impactStrength`, `pillarLabel`, `actionText`

### Layer 3 — Actionable Tagging (`layer3_actionable.dart`)
- Reads `actionabilityJson` per feature
- Tags each concern as: `immediate` | `behavioural` | `non_actionable`
- Generates plain-language action text (e.g., "Upload ITR to boost Tax Compliance score")
- Output: `List<ActionableItem>` with priority sort

### Layer 4 — Trajectory Simulation (`layer4_trajectory.dart`)
- Simulates score improvement if user takes top actions
- Projects 30/60/90 day score improvement estimates
- Output: `TrajectoryResult` with projected score bands

### Layer 8 — Causal Rules (`layer8_causal_rules.dart`)
- Evaluates if-then rules from `causal_chains.json`
- Each rule has: `triggers` (feature index + operator + threshold) + `triggerLogic` (AND/OR)
- Work-type filtered: rules can be `platform_worker` | `vendor` | `all`
- Returns up to 3 matched causal chains
- Example rule: "If EMI/income > 0.4 AND savings < 0.3 → Debt Stress Loop pattern detected"

### Output: `ScoreReportModel`
```dart
ScoreReportModel {
  finalScore: int,          // 300–900
  grade: String,            // A+/A/B+/B/C+/C/D
  riskBand: String,         // Very Low / Low / Medium / High Risk
  proofId: String,          // GP-{timestamp}
  generatedAt: DateTime,
  overallConfidence: double,
  probability: double,      // meta-learner output
  workType: String,
  computeTimeMs: int,
  pillars: List<ScorePillarModel>,    // 8 pillars
  pillarContributions: Map<String,int>,
  topStrengths: List<ShapFactorModel>,
  topConcerns: List<ShapFactorModel>,
  tailoredSuggestions: List<String>,
  trajectory: TrajectoryResult,
  causalChains: List<CausalRule>,
}
```

---

## 10. LOAN APPLICATION PIPELINE (8 Screens)

**Route:** `/app/loans/apply` → `LoanApplicationScreen`

### Screen Flow
```
Screen 0: Product Selection
  - Calls LoanApiService.getProducts(score) → backend /loan/products
  - Filters by user's GigCredit score (score >= product.min_score)
  - Displays eligible products as cards (Emergency Advance, Working Capital, etc.)
  - User selects product → advances to Screen 1

Screen 1: Loan Configuration
  - Loan amount slider (range from product: min_amount to max_amount)
  - Tenure selector (from product.tenures list)
  - Purpose text input
  - Dynamic EMI preview (calculated locally)

Screen 2: Key Fact Statement (KFS)
  - Calls LoanApiService.generateKfs(amount, tenure, productId, score)
  - Displays: Amount, APR, EMI, Total Payable, Processing Fee
  - KFS calculated: EMI = P×r×(1+r)^n / ((1+r)^n - 1)
  - User must scroll to bottom + tap "I Acknowledge"
  - Sets _kfsAcknowledged = true

Screen 3: Personal Details Review
  - Pre-filled from verifiedProfileProvider (Step 1 data)
  - Additional loan-specific fields: purpose, existing EMI total

Screen 4: Eligibility Checks (Animated)
  - Runs 3.5s animated checks sequence:
    Stage 1 (0–3.5s): Aadhaar verified, PAN verified, Age check, Bank statement months, KFS acknowledged, Mobile verified, Score threshold
    Stage 2 (4–5s): DSCR calculation, Post-loan EMI ratio, LTI ratio
    Stage 3 (6.5s): "Sending to AI engine" loading card
  - At 8s: calls _submitToBackend() + advances to Screen 5

Screen 5: AI Processing
  - 3s animated "AI Evaluation" with progress bar
  - Decides outcome based on _isApproved (currently: loanAmount <= 55000)
  - Auto-advances to Screen 6 (approve) or Screen 7 (reject)

Screen 6: Approval View
  - Approved loan ID (simulated)
  - Approved amount, EMI, tenure, APR
  - "View Full Decision Report" button → navigates to XaiReportScreen
  - "Accept Offer" + "Decline" buttons

Screen 7: Rejection View
  - Rejection reason (from _isApproved logic)
  - Counter-offer display if applicable
  - "Accept Counter-Offer" or "Try Again Later"
  - "View Full Decision Report" button → navigates to XaiReportScreen
```

### Backend Submission (`_submitToBackend`)
```dart
// Called during Screen 4 → Screen 5 transition
final result = await LoanApiService.applyLoan(
  application: {loan_amount, tenure_months, product_id, purpose,
                kfs_acknowledged, aadhaar_verified, pan_verified},
  scoreReport: scoreProvider.reportData.toJson()
);
// Backend result is currently IGNORED for UI decision
// Frontend uses: _isApproved = _loanAmount <= 55000
```

### XAI Decision Report Screen (`xai_report_screen.dart`)
- Full-screen deep-dive into loan decision
- Receives `decisionData: Map<String, dynamic>` via route `extra`
- Displays: Decision summary, Hard Rules pass/fail, Affordability metrics, AI confidence
- SHAP waterfall chart for loan-specific factors
- Audit trail entry reference

---

## 11. BACKEND API COMPLETE REFERENCE

**Base URL:** `https://gig-credit.onrender.com` (production) | `http://172.17.101.115:8000` (local)

### 11.1 Auth Routes (`/auth`)
| Method | Path | Description |
|---|---|---|
| POST | `/auth/otp/send` | Sends OTP to mobile |
| POST | `/auth/otp/verify` | Verifies OTP → JWT token |

### 11.2 Government Verification (`/gov`)
| Method | Path | Payload | Response |
|---|---|---|---|
| POST | `/gov/aadhaar/verify` | `{aadhaar: "123456789012"}` | `{status, name, dob, state, otp}` |
| POST | `/gov/pan/verify` | `{pan: "ABCDE1234F"}` | `{status, name, dob, pan_active, itr_filed, otp}` |
| POST | `/gov/vehicle/rc/verify` | `{vehicle_number}` | `{owner_name, vehicle_class, chassis_number, rc_expiry}` |
| POST | `/gov/eshram/verify` | `{uan}` | `{status, name, worker_category, registration_date}` |
| POST | `/gov/pmsym/verify` | `{uan}` | `{status, months_contributed, last_contribution_date}` |
| POST | `/gov/income-tax/itr/verify` | `{pan, assessment_year}` | `{status, itr_form, gross_income, filing_date}` |

**Auth:** HMAC signature validation on all `/gov` endpoints (`verify_hmac_headers` dependency).

### 11.3 Bank Verification (`/bank`)
| Method | Path | Payload | Response |
|---|---|---|---|
| POST | `/bank/ifsc/verify` | `{ifsc: "HDFC0001234"}` | `{bank_name, branch_name, city, state}` |
| POST | `/bank/account/verify` | `{account_number, ifsc}` | `{account_holder, account_type, status}` |

### 11.4 Loan Routes (`/loan`)
| Method | Path | Payload | Response |
|---|---|---|---|
| POST | `/loan/products` | `{score: 647}` | `{eligible_products: [...]}` |
| POST | `/loan/kfs` | `{amount, tenure, product_id, score}` | `{amount, tenure, apr, emi, total_payable, processing_fee}` |
| POST | `/loan/apply` | `{application: {...}, score_report: {...}}` | Decision payload |
| GET | `/loan/decision/{loan_id}` | — | `{loan_id, status}` |

### 11.5 Loan Decision Logic (`/loan/apply`)

```
1. HardRulesEngine.evaluate(application, score_report, product_id)
   7 Rules checked in sequence:
   HR-1: KYC — aadhaar_verified AND pan_verified
   HR-2: Age — 18 ≤ age ≤ 65
   HR-3: Bank Statement — months ≥ 3
   HR-4: DSCR — income/(existing_emi + proposed_emi) ≥ threshold (1.40)
   HR-5: Minimum Score — score ≥ product.min_score
   HR-6: KFS Acknowledged — kfs_acknowledged AND within 24 hours
   HR-7: Mobile Verified
   
   If any fail → return rejected with rejection_bucket: "HARD_RULE"
   HR-4 or HR-5 failures → compute counter_offer

2. AffordabilityEngine.compute(application, score_report, product_id)
   Checks:
   - Post-loan EMI ratio: (existing_emi + proposed_emi)/income ≤ emi_ratio_cap (50%)
   - Loan-to-Income: amount/income ≤ max_lti_ratio (6×)
   
   Computes:
   - Base APR from score band lookup
   - APR adjustments (+2% if P2<0.5, +1.5% if P4<0.4, -1% if insurance active, etc.)
   - EMI via standard formula
   - Total cost of credit
   - Effective APR via IRR (Newton-Raphson, 200 iterations)
   - Max eligible amount
   
   If fails → return rejected with rejection_bucket: "AFFORDABILITY" + counter_offer

3. Model Score Check
   repayment_prob = 0.85 (hardcoded for demo)
   if < 0.65 → return rejected with rejection_bucket: "MODEL_SCORED"

4. Approved → return {decision: "approved", loan_id, details}

5. AuditTrailService.append_record(loan_id, decision, score_report, application)
```

---

## 12. AUDIT TRAIL (`audit_trail.py`)

**Immutable blockchain-style log:**

```python
Record structure:
{
  "audit_id": "GC-LOAN-20260502143000",
  "loan_id": "L3F8A9C2",
  "created_at": "2026-05-02T09:00:00Z",
  "prev_hash": "<sha256 of previous record>",
  "identity_snapshot": {aadhaar_verified, pan_verified},
  "score_snapshot": <full ScoreReportModel JSON>,
  "loan_request": {product_type, amount, tenure, kfs_acknowledged},
  "decision": <full decision payload>,
  "record_hash": SHA256(json.dumps(record, sort_keys=True) + prev_hash)
}
```

**Chain:** Each record's `prev_hash` equals the previous record's `record_hash`, creating a tamper-evident chain. First record uses `"0"×64` as prev_hash.

**Storage:** `audit_logs.json` (append-only JSON array on server filesystem).

---

## 13. SCORE REPORT DISPLAY

**Route:** `/app/score/report` → `ScoreReportScreen` (1,447 lines)

**Sections:**
1. Hero card: Score gauge (300–900), grade badge, risk band
2. Proof ID + generation timestamp
3. Confidence indicator + compute time
4. 8 Pillar breakdown bars (score/maxScore)
5. Top 3 Strengths (green SHAP factors)
6. Top 3 Concerns (red SHAP factors)
7. Actionable Suggestions (from L3)
8. Trajectory chart (30/60/90 day projection)
9. Causal Chain viewer (matched rules)
10. "Apply for a Loan" CTA button → `/app/loans/apply`
11. "Download Certificate" → `/app/score/report/certificate`

---

## 14. LOAN PRODUCTS CONFIGURATION

Defined in `backend/app/utils/loan_products.py`:

| Product | Min Score | Amount Range | Tenures | APR Range | DSCR | LTI |
|---|---|---|---|---|---|---|
| Emergency Cash Advance | 520 | ₹5K–₹25K | 1–3 months | 22%–14% | 1.25 | 3× |
| Income Bridge | 580 | ₹10K–₹82K | 3–6 months | 20%–13% | 1.35 | 4× |
| Working Capital Loan | 600 | ₹25K–₹5L | 3–18 months | 18%–12% | 1.40 | 6× |
| Growth Capital | 680 | ₹50K–₹10L | 6–36 months | 16%–10% | 1.50 | 8× |

APR by score band (example Emergency Advance): 520-599: 22%, 600-639: 19%, 640-719: 16%, 720+: 14%

---

## 15. APP NAVIGATION MAP

```
/ (Splash)
├── /auth/login
├── /auth/signup
└── /auth/otp

/app (AppShell — 5 tab nav)
├── /app/home          (Dashboard)
├── /app/about         (About GigCredit)
├── /app/schemes       (Govt Schemes Info)
├── /app/guidance      (Input guidance)
├── /app/score         (Score intro)
│   ├── /app/score/how-it-works
│   ├── /app/score/flow/1   (Personal)
│   ├── /app/score/flow/2   (KYC)
│   ├── /app/score/flow/3   (Bank)
│   ├── /app/score/flow/4   (Utility)
│   ├── /app/score/flow/5   (Work)
│   ├── /app/score/flow/6   (Gov Schemes)
│   ├── /app/score/flow/7   (Insurance)
│   ├── /app/score/flow/8   (Tax)
│   ├── /app/score/flow/9   (EMI/Loans)
│   ├── /app/score/generating
│   └── /app/score/report
│       └── /app/score/report/certificate
├── /app/loans
│   └── /app/loans/apply
│       └── /app/loans/apply/report   (XAI Decision Report)
├── /app/applications
│   └── /app/applications/detail/:appId
└── /app/profile
    ├── /app/profile/buy-credits
    └── /app/profile/reports
```

---

## 16. DATA FLOW SUMMARY (End-to-End)

```
User Input (9 Steps)
    │
    ▼
VerifiedProfile (Riverpod state)
    │
    ▼ ScoreGeneratingScreen triggers pipeline
FeatureEngineer.extract(profile)
    → 115 features (mostly 0.5 defaults + ~10 real values)
    │
    ▼
ScoringEngine.scorePillars(features)
    → 8 raw pillar scores [0,1]
    │
    ▼
ScoringEngine.calibrateScores(raw, calibrationKnots)
    → Isotonic regression calibration for P1,P2,P3,P4,P6
    │
    ▼
ConfidenceEngine.computeConfidence(workType, conformalIntervals)
ConfidenceEngine.adjustScores(calibrated, confidences)
    → 8 adjusted pillar scores
    │
    ▼
MetaLearnerLR.score(20-element vector)
    → probability [0,1]
    → finalScore = (prob × 600 + 300).clamp(300, 900)
    │
    ▼
ExplanationBundle.compute(...)
    → L1: pillarContributions
    → L2: topStrengths + topConcerns (SHAP lookup)
    → L3: actionableItems
    → L4: trajectory
    → L8: causalChains
    │
    ▼
ScoreReportModel stored in scoreProvider
    │
    ▼
ScoreReportScreen renders all data
    │
    ▼ User taps "Apply for Loan"
LoanApplicationScreen (8 screens)
    │
    ├── LoanApiService.getProducts(score) → backend → eligible products
    ├── LoanApiService.generateKfs(...) → KFS disclosure
    ├── _submitToBackend() → backend:
    │       HardRulesEngine → AffordabilityEngine → AuditTrail
    │
    └── XaiReportScreen (decision explanation)
```
