# GigCredit — Full End-to-End System Design
## Part 1: Architecture, Auth & 9-Step Input Pipeline

---

## 1. PROJECT OVERVIEW

**GigCredit** is a privacy-first, on-device credit scoring system for India's 400M+ gig economy workers who lack traditional credit histories. It collects 9 categories of financial evidence, runs 8 ML pillars on-device, produces a 300–900 credit score with full XAI explainability, then routes the user into an RBI-compliant loan application pipeline.

**Core Design Principles:**
- All ML inference runs **on-device** (Flutter/Dart) — raw data never leaves the phone
- Backend handles only identity verification APIs and loan audit trail
- Full explainability at every decision point (RBI requirement)
- Supports 4 gig worker archetypes: Platform Worker, Street Vendor, Tradesperson, Freelancer

---

## 2. TECH STACK

| Layer | Technology | Purpose |
|---|---|---|
| Mobile App | Flutter 3.x + Dart | Cross-platform UI (Android primary) |
| State Management | Riverpod (flutter_riverpod) | 16 providers, reactive state |
| Navigation | GoRouter | Declarative routing, 30+ routes |
| OCR (Images) | PaddleOCR (paddle_ocr_flutter) | On-device document scanning |
| OCR (PDFs) | Syncfusion Flutter PDF | Bank statement text extraction |
| ML Models | m2cgen-exported Dart | 8 pillar scoring models |
| Explainability | Custom Dart (5 layers) | SHAP lookup + causal rules |
| Backend | FastAPI (Python) | Identity APIs + loan pipeline |
| Database | MongoDB (Motor async) | Demo seeded identity records |
| Deployment | Render.com | Backend hosting |
| Auth | Firebase / OTP (simulated) | Phone number login |
| Audit Trail | SHA-256 chain (JSON file) | Immutable loan decision log |

---

## 3. FULL ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP (On-Device)                      │
│                                                                     │
│  ┌──────────────┐   ┌──────────────────────────────────────────┐   │
│  │   AUTH FLOW  │   │          9-STEP INPUT PIPELINE           │   │
│  │  Splash      │   │  Step1→Step2→Step3→Step4→Step5→          │   │
│  │  Login       │   │  Step6→Step7→Step8→Step9→Generating      │   │
│  │  OTP         │   └──────────────┬───────────────────────────┘   │
│  └──────────────┘                  │                               │
│                                    ▼                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   STATE LAYER (Riverpod)                    │   │
│  │  verifiedProfileProvider ──► 9 step models aggregated       │   │
│  │  stepStatusProvider      ──► per-step verified/pending      │   │
│  │  ocrResultsProvider      ──► raw OCR output map             │   │
│  │  scoreProvider           ──► ScoreReportModel output        │   │
│  │  loanProvider            ──► loan product + KFS data        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                    │                               │
│                                    ▼                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  SCORING PIPELINE (On-Device)               │   │
│  │                                                             │   │
│  │  FeatureEngineer (115 features)                             │   │
│  │       │                                                     │   │
│  │       ▼                                                     │   │
│  │  ScoringEngine ──► P1,P2,P3,P4 (m2cgen decision trees)     │   │
│  │                ──► P6 (m2cgen, 5.9MB random forest)        │   │
│  │                ──► P5,P7,P8 (hand-written scorecards)       │   │
│  │       │                                                     │   │
│  │       ▼                                                     │   │
│  │  IsotonicCalibration → ConfidenceEngine → MetaLearnerLR     │   │
│  │       │                                                     │   │
│  │       ▼                                                     │   │
│  │  ExplanationBundle (L1+L2+L3+L4+L8)                        │   │
│  │       │                                                     │   │
│  │       ▼                                                     │   │
│  │  ScoreReportModel (score 300-900, grade, pillars, XAI)      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                    │                               │
│                                    ▼                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  LOAN PIPELINE (8 Screens)                  │   │
│  │  ProductSelection → KFS → PersonalDetails → Eligibility →   │   │
│  │  AIProcessing → Decision → ActionView → XAI Report          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTPS API calls
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     FASTAPI BACKEND (Render.com)                    │
│                                                                     │
│  /auth      ──► OTP generation                                      │
│  /gov       ──► Aadhaar, PAN, eShram, ITR, RC verification         │
│  /bank      ──► IFSC lookup, account number verification            │
│  /loan      ──► Products, KFS, Apply (Hard Rules + Affordability)   │
│  /explain   ──► XAI narrative endpoint                             │
│  /score     ──► Score storage/retrieval                             │
│                                                                     │
│  MongoDB ──► aadhaar_db, pan_db, bank_db, eshram_db, itr_db        │
│  audit_logs.json ──► SHA-256 chained loan decision log              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. COMPLETE DIRECTORY STRUCTURE

```
Gig_Credit/
├── app/                          # Flutter mobile application
│   └── lib/
│       ├── main.dart             # Entry point, ProviderScope
│       ├── app/
│       │   ├── app_router.dart   # GoRouter: 30+ routes, auth guard
│       │   └── app_shell.dart    # 5-tab bottom navigation shell
│       ├── features/
│       │   ├── auth/             # Splash, Login, Signup, OTP
│       │   ├── home/             # Dashboard, About, Schemes
│       │   ├── score/
│       │   │   ├── screens/      # ScoreIntro, InputGuidance, Generating, Report
│       │   │   ├── flow/         # step1..step9 screens
│       │   │   └── widgets/      # StepSquareCard, PillarBreakdown
│       │   ├── report/           # ScoreReportScreen, CertificateScreen
│       │   ├── loans/            # LoanApplicationScreen, XaiReportScreen
│       │   ├── applications/     # ApplicationsScreen, ApplicationDetailScreen
│       │   ├── profile/          # ProfileScreen, ReportHistoryScreen
│       │   └── credits/          # BuyCreditsScreen
│       ├── models/
│       │   ├── verified_profile/ # 9 step data models + VerifiedProfile
│       │   ├── score_report_model.dart
│       │   ├── score_pillar_model.dart
│       │   ├── shap_factor_model.dart
│       │   ├── causal_chain.dart
│       │   ├── loan_product_model.dart
│       │   ├── loan_decision_model.dart
│       │   └── kfs_model.dart
│       ├── scoring/
│       │   ├── score_pipeline.dart   # Master 6-stage orchestrator
│       │   ├── features/             # FeatureEngineer, ProfileExtractor
│       │   ├── engine/               # ScoringEngine, ConfidenceEngine, MetaLearner
│       │   ├── models/               # p1..p6 scorers, meta_learner_lr, scorecards
│       │   ├── explainability/       # L1-L4, L8 XAI layers
│       │   ├── validation/           # CrossStepValidator
│       │   ├── placeholders/         # DemoFaceVerifier
│       │   └── constants/            # ScoringConstants, feature defaults
│       ├── services/
│       │   ├── ocr_service.dart      # Interface
│       │   ├── demo_ocr_service.dart # Asset-based mock OCR
│       │   ├── real_ocr_service.dart # PaddleOCR + Syncfusion PDF
│       │   ├── loan_api_service.dart # Loan backend + mock fallback
│       │   ├── scoring_service.dart  # Score report serialization
│       │   └── api_service.dart      # Gov/bank API client
│       └── state/                    # 16 Riverpod providers
│
├── backend/                      # FastAPI Python backend
│   └── app/
│       ├── main.py               # FastAPI app, CORS, lifespan
│       ├── api/                  # 8 routers
│       │   ├── gov_verification.py   # Aadhaar, PAN, eShram, ITR, RC
│       │   ├── bank_verification.py  # IFSC, Account
│       │   ├── otp_routes.py         # OTP send/verify
│       │   ├── loan_router.py        # Products, KFS, Apply
│       │   ├── scoring_router.py     # Score storage
│       │   ├── report_routes.py      # Report retrieval
│       │   └── explainability_router.py
│       ├── services/
│       │   ├── hard_rules.py         # 7 RBI hard rules engine
│       │   ├── affordability.py      # DSCR, EMI ratio, LTI, IRR
│       │   ├── audit_trail.py        # SHA-256 immutable chain
│       │   ├── fairness_engine.py    # Bias detection
│       │   └── llm_service.py        # Narrative generation
│       ├── auth/                 # HMAC request validation
│       ├── db/                   # MongoDB connection
│       ├── schemas/              # Pydantic request/response models
│       └── utils/                # Loan products config, error handlers
│
└── demo_data/                    # Seeded test data
    └── inputs/step_1..step_9/   # Per-step sample JSON
```

---

## 5. AUTHENTICATION FLOW

```
User opens app
      │
      ▼
SplashScreen (/)
  - Checks Firebase auth state
  - 2s delay → redirect
      │
      ├── isAuthenticated → /app/home
      └── not authenticated → /auth/login
                                    │
                        ┌───────────┴───────────┐
                        ▼                       ▼
                  LoginScreen             SignupScreen
                  /auth/login             /auth/signup
                        │                       │
                   Enter mobile            Enter name +
                   + password              mobile + password
                        │                       │
                        └───────────┬───────────┘
                                    ▼
                          OtpVerificationScreen
                          /auth/otp?mobile=&isSignup=
                          - 6-digit OTP input
                          - Simulated UIDAI SMS dialog
                          - On success → GoRouter redirect → /app/home
                                    │
                                    ▼
                          AppShell (5-tab nav)
                          ┌──────────────────────┐
                          │ Home │Score│Loans│App│Profile│
                          └──────────────────────┘
```

**Auth State:** `authProvider` (StateNotifierProvider) watches Firebase auth stream. GoRouter redirect guard at `_buildRouter()` enforces: unauthenticated users can only reach `/auth/*` routes.

---

## 6. THE 9-STEP INPUT PIPELINE

### 6.1 Navigation Flow
```
/app/score (ScoreIntroScreen)
    → /app/score/how-it-works (ShowMeHowScreen)   [optional]
    → /app/guidance (InputGuidanceScreen)          [optional]
    → /app/score/flow/1  (Step1PersonalScreen)
    → /app/score/flow/2  (Step2KycScreen)
    → /app/score/flow/3  (Step3BankScreen)
    → /app/score/flow/4  (Step4UtilityScreen)
    → /app/score/flow/5  (Step5WorkScreen)
    → /app/score/flow/6  (Step6GovSchemesScreen)
    → /app/score/flow/7  (Step7InsuranceScreen)
    → /app/score/flow/8  (Step8TaxScreen)
    → /app/score/flow/9  (Step9EmiLoansScreen)
    → /app/score/generating (ScoreGeneratingScreen)
    → /app/score/report    (ScoreReportScreen)
```

### 6.2 Step Progress Tracking
- `stepStatusProvider`: `Map<int, StepStatus>` — tracks each step as `pending | verified`
- `ScrollableStepLayout` widget shows a horizontal step indicator at top
- Any completed step can be re-visited via tap on indicator
- `VerificationBadge` widget shown on step header when `status == verified`

---

### STEP 1 — Personal Info (`PersonalInfo` model)

**Screen:** `step1_personal_screen.dart` (472 lines)

**Fields collected:**
| Field | Type | Validation | Stored In |
|---|---|---|---|
| Full Name | Text | `[a-zA-Z\s]+`, 2-50 chars | `personalInfo.fullName` |
| Date of Birth | Text | DD/MM/YYYY split check | `personalInfo.dateOfBirth` |
| Mobile Number | Text | 10 digits, starts 6-9 | `personalInfo.mobileNumber` |
| Current Address | Text | 10-200 chars | `personalInfo.currentAddress` |
| Permanent Address | Text | 10+ chars or same-as-current | `personalInfo.permanentAddress` |
| State of Residence | Dropdown | 36 Indian states/UTs | `personalInfo.stateOfResidence` |
| Primary Work Type | Dropdown | 4 types | `personalInfo.workType` |
| Monthly Income (₹) | Number | ₹1,000–₹5,00,000 | `personalInfo.selfDeclaredIncome` |
| Years in Profession | Stepper | 0–40 | `personalInfo.yearsInProfession` |
| Dependents | Stepper | 0–10 | `personalInfo.dependents` |
| Vehicle Ownership | Toggle | Boolean | `personalInfo.vehicleOwnership` |
| Secondary Income | Number | Optional, no validation | `personalInfo.secondaryIncome` |

**Work Types:** `platform_worker` | `vendor` | `tradesperson` | `freelancer`

**Cross-step effects:**
- `workType` → determines Step 5 document variant
- `vehicleOwnership == true` → shows vehicle insurance module in Step 7

**Submit logic:** `verifiedProfileProvider.updateStep1(PersonalInfo(...))` + `stepStatusProvider.setStatus(1, StepStatus.verified)`

**Mock fill:** Double-tap on name field fills all fields with Ravi Kumar demo data.

---

### STEP 2 — KYC Verification (`KycInfo` model)

**Screen:** `step2_kyc_screen.dart` (665 lines)

**Section A — Aadhaar:**
1. Enter 12-digit Aadhaar number
2. Tap "Verify" → `api.verifyAadhaar(text)` → POST `/gov/aadhaar/verify`
   - Backend: validates format `^[2-9]\d{11}$`, queries `aadhaar_db`, returns OTP
   - Fallback (API down): generates local OTP, prints to console
3. OTP dialog appears simulating UIDAI SMS
4. Enter OTP → exact match → `_aadhaarVerified = true`
5. Upload Aadhaar Front → `RealOcrService.extractDataFromImage(path, 'aadhaar_front')`
   - PaddleOCR scans image → keyword match (AADHAAR/UIDAI) → extract `\d{4}\s?\d{4}\s?\d{4}`
   - Auto-fills Aadhaar field if found
6. Upload Aadhaar Back → OCR runs, sets `_aadhaarBackExtracted = true`

**Section B — PAN:**
1. Enter 10-char PAN number
2. Tap "Verify" → `api.verifyPan(text)` → POST `/gov/pan/verify`
   - Backend: validates format `^[A-Z]{5}\d{4}[A-Z]$`, queries `pan_db`, returns OTP
3. OTP dialog simulating NSDL SMS
4. Enter OTP → `_panVerified = true`
5. Upload PAN card → OCR extracts `[A-Z]{5}\d{4}[A-Z]` pattern

**Section C — Live Selfie:**
1. Camera capture (useCamera: true on DocumentUploadCard)
2. `DemoFaceVerifier.verify(aadhaarPath, panPath, selfiePath)`
   - **CURRENT IMPLEMENTATION:** `Random().nextDouble() > 0.1` (90% random pass)
   - Shows "Face matched (95% confidence)" on success

**Completion gate:** `_aadhaarVerified && _aadhaarFrontExtracted && _panVerified && _panExtracted && _selfieVerified`

**Cross-validation:** `_runCrossValidation()` calls `CrossStepValidator.validate(ocrResults)` → currently returns `[]` (stub)

**Stored:** `KycInfo(isVerified: true, backVerified: bool, selfieVerified: bool)`

---

### STEP 3 — Bank Information (`BankInfo` model)

**Screen:** `step3_bank_screen.dart` (504 lines)

**Primary Bank:**
| Field | Validation | Verification |
|---|---|---|
| Bank Name | Non-empty | Auto-filled from IFSC API |
| Account Holder Name | Non-empty | Auto-filled from Account API |
| Branch Name | Non-empty | Auto-filled from IFSC API |
| IFSC Code | 11 chars | `api.verifyIfsc(text)` → POST `/bank/ifsc/verify` |
| Account Number | Non-empty, IFSC verified first | `api.verifyAccount(acc, ifsc)` → POST `/bank/account/verify` |
| MICR Code | Optional | None |
| UPI Details | Optional | None |
| Bank Statement PDF | Uploaded | Syncfusion PDF text extraction → keyword check |

**IFSC Verification flow:**
1. User enters 11-char IFSC
2. `api.verifyIfsc()` → backend returns bank name + branch
3. Auto-fills bank name and branch fields
4. `_ifscVerified = true`

**Account Verification flow:**
1. User enters account number (after IFSC verified)
2. `api.verifyAccount()` → backend returns account holder name
3. Auto-fills holder name field
4. `_accVerified = true`

**Bank Statement:**
- PDF upload → `RealOcrService` extracts all text via Syncfusion
- Checks if text contains bank keywords (HDFC, ICICI, BALANCE, etc.)
- Account number match against entered account: **code exists but bypassed for demo**
- Sets `_pdfUploaded = true`

**Secondary Bank:** Optional toggle. Same fields but no IFSC/account API verification.

**Completion gate:** `_isFormValid` (all fields non-empty + `_pdfUploaded`) AND `_ifscVerified && _accVerified`

**Stored:** `BankInfo(isVerified: true)` — **no field values stored in model**

---

### STEP 4 — Utility Bills (`UtilityInfo` model)

**Screen:** `step4_utility_screen.dart` (356 lines)

**Six optional modules, each with toggle + fields + up to 6 consecutive bill uploads:**

| Module | Fields | OCR DocType | Classification Keywords |
|---|---|---|---|
| ⚡ Electricity | Consumer No, Name, Amount | `utility_electricity` | BILL, INVOICE, AMOUNT, PAYMENT |
| 📶 WiFi/Broadband | Account No, Name, Amount | `utility_wifi` | BILL, INVOICE, AMOUNT |
| 🔥 Gas/LPG | BP Number, Name, Amount | `utility_gas` | BILL, INVOICE, AMOUNT |
| 📱 Mobile/Phone | Mobile No, Account No, Name, Amount | `utility_mobile` | BILL, INVOICE, AMOUNT |
| 🌐 Internet | Account No, Name, Amount | `utility_internet` | BILL, INVOICE, AMOUNT |
| 🏠 Rent | Tenant, Landlord, Address, Rent | `utility_rent` | BILL, INVOICE, AMOUNT |

**Upload logic:** Each slot shows "upload 1", on upload shows "upload 2", up to 6 consecutive months.

**No field validation.** `isDisabled: false` — always submittable.

**Stored:** `UtilityInfo(isVerified: true)` — **no field values stored**

---

### STEP 5 — Work Proof (`WorkInfo` model)

**Screen:** `step5_work_screen.dart` (345 lines)  
**Dynamic:** Screen content changes based on `personalInfo.workType` from Step 1.

**Platform Worker:**
- Vehicle Registration Number (text)
- RC Book Front photo → keyword: REGISTRATION, VEHICLE, CHASSIS
- DL Front + Back photos → keyword: DRIVING, LICENCE
- Vehicle Insurance Certificate (no classification)
- 3× Earnings Screenshots from platform app

**Street Vendor:**
- PM SVANidhi Application ID (text)
- SVANidhi Approval Letter photo
- Municipal Trade Licence photo

**Tradesperson:**
- NSDC Skill Certificate ID (text)
- Skill Certificate photo
- Work Order Letter photo

**Freelancer:**
- Freelance Platform Profile Screenshot
- Up to 5 Client Invoice photos (1 required, 4 optional)

**`isDisabled: false`** — always submittable regardless of uploads.

**Stored:** `WorkInfo(isVerified: true, platformId: ..., rcUploaded: bool, dlFrontUploaded: bool, ...)` — partial model storage

---

### STEP 6 — Government Schemes (`GovSchemesInfo` model)

**Screen:** `step6_gov_schemes_screen.dart` (214 lines)

**7 optional scheme modules:**

| Scheme | ID Field | Document | Score Impact |
|---|---|---|---|
| PM SVANidhi | Application ID | Approval Letter | P7 Social Accountability |
| eShram | UAN (12-digit) | eShram Card | P5 Identity, P6 Safety Net |
| PM-SYM Pension | Account Number | Pension Card | P6 Safety Net |
| PMJJBY Life Insurance | URN | Certificate | P6 Safety Net |
| PMMY/Mudra Loan | Account Number | Sanction Letter | P7 Social |
| PPF Account | Account Number | Passbook | P4 Savings |
| Udyam/MSME | Registration Number | Certificate | P7 Social |

**Skip button** available. `isDisabled: false`.

**Stored:** `GovSchemesInfo(isVerified: true)` — **no scheme data stored**

---

### STEP 7 — Insurance (`InsuranceInfo` model)

**Screen:** `step7_insurance_screen.dart` (200 lines)

| Insurance Type | Fields | Condition |
|---|---|---|
| 🏥 Health | Policy Number, Holder Name, Document | Always optional |
| 🚗 Vehicle | Policy Number, Holder Name, Document | Only if `vehicleOwnership == true` (Step 1) |
| 🛡️ Life | Policy Number, Holder Name, Document | Always optional |

**Cross-step link:** Vehicle module visibility controlled by `ref.watch(verifiedProfileProvider).personalInfo.vehicleOwnership`

**Skip button** available. `isDisabled: false`.

**Stored:** `InsuranceInfo(isVerified: true)` — **no policy data stored**

---

### STEP 8 — Tax Records (`TaxInfo` model)

**Screen:** `step8_tax_screen.dart` (202 lines)

**ITR Module (optional):**
- PAN Number (should match Step 2 PAN — **not validated**)
- Name as per ITR
- Assessment Year dropdown (2022-23 to 2025-26)
- Annual Income (₹)
- ITR-V / e-Acknowledgement upload
- Form 26AS upload (optional)

**GST Module (optional):**
- GSTIN (15-char, should match `[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}` — **not validated**)
- Legal Name as per GST
- Annual Turnover (₹)
- GST Certificate / GSTR-3B upload

**Skip button** available. `isDisabled: false`.

**Stored:** `TaxInfo(isVerified: true)` — **no tax data stored**

---

### STEP 9 — EMI & Loans (`EmiLoansInfo` model)

**Screen:** `step9_emi_loans_screen.dart` (234 lines)

**Toggle:** "Do you have active EMIs or loans?"

**If yes — up to 5 loan entries, each with:**
- Lender Name (text, free-form)
- Monthly EMI Amount (₹, number)
- Previous Debit Date (date picker, 2018–now)
- Latest Debit Date (date picker, 2018–now)

**If no:** Shows green "No active loans — positive signal" card.

**No validation** on EMI amounts. No cross-check against bank statement.

**Submit → navigates to `/app/score/generating`**

**Stored:** `EmiLoansInfo(isVerified: true)` — **EMI amounts not stored in model**

---

### 6.3 The VerifiedProfile Aggregation Model

```dart
class VerifiedProfile {
  PersonalInfo personalInfo;    // Step 1: 12 fields
  KycInfo kycInfo;              // Step 2: isVerified, selfieVerified
  BankInfo bankInfo;            // Step 3: isVerified only
  UtilityInfo utilityInfo;      // Step 4: isVerified only
  WorkInfo workInfo;            // Step 5: partial fields
  GovSchemesInfo govSchemesInfo;// Step 6: isVerified only
  InsuranceInfo insuranceInfo;  // Step 7: isVerified only
  TaxInfo taxInfo;              // Step 8: isVerified only
  EmiLoansInfo emiLoansInfo;    // Step 9: isVerified only
}
```

**State management:** `VerifiedProfileNotifier` (StateNotifier) with `updateStep1()` through `updateStep9()`. Each update creates a new `VerifiedProfile` instance with the updated step and all other steps carried forward (immutable pattern).

**16 Riverpod Providers:**
1. `authProvider` — Auth session
2. `verifiedProfileProvider` — 9-step data aggregate
3. `stepStatusProvider` — Step completion map
4. `scoreProvider` — ScoreReportModel output
5. `ocrResultsProvider` — OCR output map
6. `ocrServiceProvider` — OCR service selector (demo vs real)
7. `apiServiceProvider` — Backend API client
8. `loanProvider` — Loan product selection
9. `loanApplicationsProvider` — Application history
10. `userProvider` — User profile data
11. `creditProvider` — Credit balance
12. `applicationProvider` — Current application state
13. `languageProvider` — Language selection
14. `connectivityProvider` — Network status
15. `navProvider` — Bottom nav index
16. `loanApiServiceProvider` — Loan API client
