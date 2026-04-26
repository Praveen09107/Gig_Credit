# ================================================================================
# GIGCREDIT — DEV B AGENT IMPLEMENTATION GUIDE
# FOR: GPT 5.3 Codex (or any AI coding agent)
# ROLE: Flutter Frontend Developer + On-Device Scoring Integration
# ================================================================================

## ⚠️ READ THIS ENTIRE DOCUMENT BEFORE WRITING ANY CODE

You are Dev B on a 2-person hackathon team building **GigCredit** — a privacy-first
alternative credit scoring app for Indian gig workers. You own the **Flutter frontend
app** including UI, state management, OCR integration, and on-device scoring engine.
Your teammate (Dev A) owns the backend server and ML pipeline.

---

## 1. WHAT IS GIGCREDIT?

GigCredit helps gig workers (delivery drivers, vendors, freelancers) who have NO
traditional credit score to generate one using alternative financial data. The app:

1. Collects personal info + document uploads across a 9-step onboarding flow
2. Extracts data from documents via OCR (or demo fallback)
3. Sends identity numbers to Dev A's backend for verification
4. Computes a credit score ON-DEVICE using ML models (pure Dart arithmetic)
5. Sends the score to the backend for LLM-powered plain-language explanation
6. Displays score, 7 pillar breakdown, SHAP factors, suggestions, and loan offers

**This is a DEMO prototype.** Most of the pipeline is real, but face verification
and document authenticity checking are placeholders that return fixed values.

---

## 2. WHAT YOU OWN

```
YOU OWN AND WRITE CODE IN:
├── app/              ← Flutter application (Dart)

YOU NEVER TOUCH:
├── backend/          ← Dev A's FastAPI server
├── ml_pipeline/      ← Dev A's ML training pipeline

YOU READ BUT DON'T EDIT:
├── contracts/        ← API schemas (Dev A creates, you consume)
├── ml_pipeline/output/  ← ML model exports (Dev A creates, you copy into app/)
```

---

## 3. YOUR TECH STACK

| Component | Package | Purpose |
|-----------|---------|---------|
| State | flutter_riverpod | Reactive state management |
| Navigation | go_router | Declarative routing with bottom nav shell |
| Fonts | google_fonts | Inter font family |
| Animation | flutter_animate | Micro-animations |
| Charts | fl_chart | Pillar breakdown bar charts |
| Storage | hive, flutter_secure_storage | Session persistence |
| HTTP | http | API calls to backend |
| Crypto | crypto | HMAC-SHA256 signing |
| Camera | image_picker | Document upload |
| Files | file_picker | PDF upload (bank statements) |
| PDF Gen | pdf, printing | Report PDF export |
| PDF Read | pdfx | Bank statement text extraction |

---

## 4. APP ARCHITECTURE

```
lib/
├── main.dart                  → Entry point + ProviderScope
├── app/                       → App shell, router, theme, constants
├── core/                      → Feature-agnostic services (network, storage, errors, utils)
├── shared/                    → Reusable UI widgets (buttons, cards, dialogs, states, theme)
├── models/                    → Shared data classes (VerifiedProfile, ScoreResult, etc.)
├── services/                  → Global services (ApiClient, OcrService, StorageService)
├── state/                     → Global state providers (auth, profile, score, credits)
├── features/                  → 8 feature modules (auth, home, score, report, loans, applications, profile, credits)
│   └── score/flow/            → 9-step input sub-screens
└── scoring/                   → On-device scoring engine (ML models, feature engineering, SHAP)
```

### Bottom Navigation Tabs (5 tabs):
Home | Score | Loans | Applications | Profile

### Route Map:
```
/splash → /auth/login → /auth/signup → /auth/otp
/app/home
/app/score → /app/score/how-it-works → /app/score/flow/step-N → /app/score/generating → /app/score/report
/app/loans → /app/loans/details/:id
/app/applications → /app/applications/details/:id
/app/profile → /app/profile/buy-credits → /app/profile/reports
```

---

## 5. DESIGN SYSTEM

**Dark mode first. Premium fintech aesthetic.**

```dart
class AppColors {
  static const primary = Color(0xFF1A1A2E);       // Deep navy
  static const accent = Color(0xFF0F3460);         // Electric blue
  static const highlight = Color(0xFFE94560);      // Pink accent
  static const surface = Color(0xFF0A0A1A);        // Background
  static const card = Color(0xFF1E1E3A);           // Card background
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0C8);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const verified = Color(0xFF00E676);       // Green checkmark
}
```

Font: Google Fonts Inter. Use proper hierarchy (Bold for headers, Regular for body).
Cards: Glassmorphic with semi-transparent backgrounds and subtle gradient borders.
Animations: Every screen transition, verification badge, and loading state should animate.

---

## 6. IMPLEMENTATION ORDER (Follow This Exactly)

### STEP 1: Initialize Flutter Project
```bash
cd app
flutter create --org com.gigcredit .
```
Add all dependencies to pubspec.yaml (see planning_new/32_FLUTTER_DEPENDENCIES.md).

### STEP 2: Create Design System
- `lib/shared/theme/` — AppColors, AppTypography, AppSpacing
- `lib/app/app.dart` — MaterialApp with dark theme using AppColors
- `lib/app/app_router.dart` — GoRouter with all routes
- `lib/app/app_shell.dart` — BottomNavigationBar with IndexedStack for tab persistence

### STEP 3: Create Mock Services (CRITICAL — do this BEFORE any screens)
```dart
// lib/services/api_service.dart — Abstract interface
abstract class ApiService {
  Future<Map<String, dynamic>> sendOtp(String mobile);
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp);
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaar);
  Future<Map<String, dynamic>> verifyPan(String pan);
  Future<Map<String, dynamic>> verifyIfsc(String ifsc);
  Future<Map<String, dynamic>> verifyAccount(String accountNumber, String ifsc);
  Future<Map<String, dynamic>> checkLoans(String accountNumber);
  Future<Map<String, dynamic>> verifyVehicle(String vehicleNumber);
  Future<Map<String, dynamic>> verifyEshram(String uan);
  Future<Map<String, dynamic>> verifyPmsym(String uan);
  Future<Map<String, dynamic>> verifyInsurance(String policyNumber, String policyType);
  Future<Map<String, dynamic>> verifyItr(String pan, String assessmentYear);
  Future<Map<String, dynamic>> generateReport(Map<String, dynamic> payload);
}

// lib/services/mock_api_service.dart — Returns static demo JSON for EVERY endpoint
// lib/services/real_api_service.dart — HTTP calls with HMAC signing to Dev A's backend
```

```dart
// lib/services/ocr_service.dart — Abstract interface
abstract class OcrService {
  Future<Map<String, dynamic>> process(String filePath, String docType);
}

// lib/services/demo_ocr_service.dart — Returns pre-extracted text per document type
```

**WHY MOCKS FIRST**: You can build ALL screens without waiting for Dev A's backend.
Switch to real API later by changing one provider.

### STEP 4: Create Shared Widgets
Build these reusable components in `lib/shared/`:
- `PrimaryButton` — gradient accent button with loading state
- `AppCard` — glassmorphic card with rounded corners
- `DocumentUploadCard` — camera/gallery upload with thumbnail + processing states
- `VerificationBadge` — animated green checkmark with "Verified ✓" text
- `StepProgressBar` — 9 dots connected by lines showing current step
- `SectionHeader` — styled section title
- `EmptyStateView`, `ErrorStateView`, `LoadingView` — standard state views
- `StatusBadge` — colored pill badges (Verified, Pending, Failed)

### STEP 5: Build All Feature Screens

**Auth module** (`features/auth/`):
- LoginScreen — mobile number input + "Send OTP" button
- SignUpScreen — username + mobile + "Send OTP"
- OtpVerificationScreen — 6-digit input boxes + countdown timer + verify

**Home module** (`features/home/`):
- HomeScreen — hero card with CTA "Check Credit Score", privacy highlights

**Score module** (`features/score/`):
- ScoreIntroScreen — "What is GigCredit Score?" + "Show Me How" + "Check Score"
- ShowMeHowScreen — guidelines explaining what documents are needed
- 9 step flow screens (in `features/score/flow/`):
  - Step 1: Basic Profile (name, DOB, mobile, work type, income, etc.)
  - Step 2: Identity KYC (Aadhaar front/back upload + PAN upload + selfie)
  - Step 3: Bank Verification (bank name, IFSC, account#, bank statement PDF)
  - Step 4: Utility Bills (6 electricity + 6 LPG + 6 mobile bill uploads)
  - Step 5: Work Proof (dynamic by work type — RC, DL, earnings for platform workers)
  - Step 6: Gov Schemes (eShram UAN, PMSYM, Mudra, SHG — all optional)
  - Step 7: Insurance (health, vehicle, life policies)
  - Step 8: Tax (ITR acknowledgement, GST registration)
  - Step 9: EMI/Loans (toggle "active loans?" + up to 5 loan cards)
- ScoreGeneratingScreen — animated processing with sequential status updates

**Report module** (`features/report/`):
- ScoreReportScreen — score circle + 7 pillar bars + SHAP cards + LLM text + PDF export

**Loans module** (`features/loans/`):
- LoansScreen — 3 hardcoded lender offer cards + "Apply Now" + consent sheet

**Applications module** (`features/applications/`):
- ApplicationsScreen — submitted applications list with status tracking

**Profile module** (`features/profile/`):
- ProfileScreen — user info + credit balance + my reports + logout

**Credits module** (`features/credits/`):
- BuyCreditsSheet — quantity selector + payment (first 3 reports free, then 10 credits = ₹79)

### STEP 6: Build VerifiedProfile Data Model
This is the CENTRAL object that accumulates data across all 9 steps:
```dart
class VerifiedProfile {
  PersonalInfo personal;    // Step 1
  IdentityInfo identity;    // Step 2
  BankInfo bank;            // Step 3
  UtilityInfo utility;      // Step 4
  WorkProofInfo workProof;  // Step 5
  GovSchemesInfo govSchemes;// Step 6
  InsuranceInfo insurance;  // Step 7
  TaxInfo tax;              // Step 8
  EmiLoansInfo emiLoans;    // Step 9
  Map<int, String> stepStatus; // {1: "VERIFIED", 2: "VERIFIED", ...}
}
```
See `planning_new/05_DATA_CONTRACTS_AND_API_SCHEMAS.md` for the full schema.

### STEP 7: Connect Real API (After Dev A deploys)
```dart
// lib/core/network/hmac_signer.dart
class HmacSigner {
  final String hmacSecret, apiKey, deviceId;
  Map<String, String> sign(String body) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final bodyHash = sha256.convert(utf8.encode(body)).toString();
    final message = '$deviceId:$timestamp:$bodyHash';
    final signature = Hmac(sha256, utf8.encode(hmacSecret)).convert(utf8.encode(message)).toString();
    return {'X-Api-Key': apiKey, 'X-Device-Id': deviceId, 'X-Timestamp': timestamp, 'X-Signature': signature};
  }
}
```
Switch provider from MockApiService to RealApiService by changing one line.

### STEP 8: Integrate Scoring Engine

After Dev A commits model exports to `ml_pipeline/output/`, copy them:
- `ml_pipeline/output/dart_exports/*.dart` → `app/lib/scoring/models/`
- `ml_pipeline/output/json_configs/*.json` → `app/assets/config/`

Then implement:
```dart
// lib/scoring/features/feature_engineer.dart
// Converts VerifiedProfile → List<double>[95] (all values 0.0-1.0)
// See planning_new/COMP_18_FEATURE_ENGINEERING_95_FEATURES.md for all 95 features

// lib/scoring/engine/scoring_engine.dart
// Calls each pillar scorer with the correct feature slice
// P1 = scoreP1(features[0..12]), P2 = scoreP2(features[13..27]), etc.

// lib/scoring/engine/meta_learner.dart
// Loads meta_coefficients.json, builds 19-element input vector
// logit = dot(input, weights) + intercept → sigmoid → score = round(prob × 600) + 300

// lib/scoring/confidence/confidence_engine.dart
// adjusted = raw × confidence + 0.50 × (1 − confidence)

// lib/scoring/explainability/shap_lookup.dart
// Loads shap_lookup.json, finds bin for each feature value, returns top 3 +/- factors
```

### STEP 9: Report + PDF
- Call Dev A's `/api/report/generate` with score + SHAP data
- Display LLM explanation with typewriter animation
- Generate PDF with score, pillars, SHAP, explanation, suggestions

### STEP 10: Polish
- Page transition animations, shimmer loading, haptic feedback
- App icon, splash screen
- Release APK: `flutter build apk --release`

---

## 7. PLACEHOLDER COMPONENTS (Return fixed values)

```dart
// Face verification — always returns match
class DemoFaceVerifier {
  Future<FaceMatchResult> verify(String selfie, String aadhaarPhoto) async {
    await Future.delayed(Duration(seconds: 2));
    return FaceMatchResult(similarity: 0.95, matched: true);
  }
}

// Document authenticity — always returns authentic
class DemoDocAuthenticator {
  Future<AuthResult> check(String docPath) async {
    await Future.delayed(Duration(milliseconds: 500));
    return AuthResult(isAuthentic: true, confidence: 0.92);
  }
}

// Loan matching — hardcoded 3 offers
class DemoLoanMatcher {
  List<LoanOffer> getOffers(int score, String riskBand) => [
    LoanOffer(lender: "QuickCredit Finance", maxAmount: 100000, rate: 14.5, tenure: "12-36 months"),
    LoanOffer(lender: "GigFund NBFC", maxAmount: 50000, rate: 16.0, tenure: "6-24 months"),
    LoanOffer(lender: "WorkerFirst Capital", maxAmount: 75000, rate: 15.0, tenure: "12-24 months"),
  ];
}
```

---

## 8. API ENDPOINTS YOU CALL (Dev A's Backend)

Base URL: Check `contracts/decisions.md` for the Render URL.

All requests need HMAC headers (X-Api-Key, X-Device-Id, X-Timestamp, X-Signature).
All responses follow the schemas in `contracts/api_contract.json`.

Endpoints (13 total):
- POST /auth/otp/send, /auth/otp/verify
- POST /gov/aadhaar/verify, /gov/pan/verify, /gov/vehicle/rc/verify
- POST /gov/eshram/verify, /gov/pmsym/verify, /gov/insurance/policy/verify
- POST /gov/income-tax/itr/verify
- POST /bank/ifsc/verify, /bank/account/verify, /bank/loan/check
- POST /api/report/generate

See `DEV_A_AGENT_IMPLEMENTATION_GUIDE.md` sections 5.1-5.13 for exact request/response shapes.

---

## 9. SCORING PIPELINE EXECUTION ORDER

```
VerifiedProfile → FeatureEngineer (95 features) → sanitize (NaN→0.40, clamp [0,1])
→ 7 Pillar Scorers (P1-P7) → debt band cap → confidence adjustment
→ MetaLearner (19 inputs → logit → sigmoid → score 300-900)
→ Grade (S/A/B/C/D/E) → SHAP lookup (top 3+/3-)
→ Call /api/report/generate → assemble ReportData → render
```

Grade mapping: 800-900=S, 720-799=A, 640-719=B, 560-639=C, 480-559=D, 300-479=E

---

## 10. DEMO FALLBACK SCORE

If scoring produces NaN, negative, or out-of-range:
```dart
if (score.isNaN || score < 300 || score > 900) {
  return ScoreResult(finalScore: 682, grade: 'B', riskBand: 'Medium',
    pillarScores: {'p1': 0.72, 'p2': 0.68, 'p3': 0.55, 'p4': 0.61, 'p5': 0.78, 'p6': 0.45, 'p7': 0.60});
}
```

---

## 11. REFERENCE DOCUMENTS

For deeper details, read these files:
- `planning_new/PHASE_2_10_DEV_B_UI_UX_DETAILED.md` — screen-by-screen UI specs
- `planning_new/COMP_16_SCORING_ENGINE.md` — scoring pipeline details
- `planning_new/COMP_18_FEATURE_ENGINEERING_95_FEATURES.md` — all 95 features
- `planning_new/COMP_17_OCR_AND_PARSER_PIPELINE.md` — OCR strategy
- `planning_new/COMP_30_CROSS_STEP_VALIDATION.md` — cross-document validation
- `planning_new/05_DATA_CONTRACTS_AND_API_SCHEMAS.md` — API + data contracts
- `planning_new/32_FLUTTER_DEPENDENCIES.md` — pubspec.yaml
- `specification folders_new/frontend/` — 17 frontend specification files
- `specification folders_new/frontend/13.frontend-folder-structure-and-component-architecture.txt` — component architecture
- `specification folders_new/frontend/14-flutter-screen-list-and-route-map.txt` — route map
