# ================================================================================
# GIGCREDIT — COMPLETE FRONTEND PLANNING DOCUMENT
# Document 34 | planning_new
# Owner: Dev B (Flutter Frontend + On-Device Scoring Integration)
# Source: Full analysis of all 16 frontend specification files in frontend/
# ================================================================================

## PURPOSE

This document is the master frontend planning reference derived from a complete
line-by-line analysis of all 16 frontend specification files. It defines every
screen, component, state category, interaction effect, notification behavior,
and implementation order for the GigCredit Flutter application.

Every decision in this document is traceable to a specific frontend spec file.
This planning document takes priority over the previous PHASE_2_10_DEV_B_UI_UX_DETAILED.md
for screen-level detail. Both documents are complementary and should be used together.

---

## SECTION 1: FOLDER STRUCTURE (AUTHORITATIVE)

Based on `13.frontend-folder-structure-and-component-architecture.txt`

```
app/lib/
├── main.dart                         # ProviderScope + Hive init + runApp
├── app/
│   ├── app.dart                      # MaterialApp.router + dark theme
│   ├── app_router.dart               # GoRouter — all routes defined here
│   ├── app_shell.dart                # Bottom nav shell (IndexedStack, 5 tabs)
│   ├── app_constants.dart            # App-wide magic strings, timeouts, limits
│   └── app_assets.dart              # All asset path constants
├── core/
│   ├── network/
│   │   ├── hmac_signer.dart          # HMAC-SHA256 signing for all API calls
│   │   └── api_endpoints.dart        # All 13 endpoint path constants
│   ├── storage/
│   │   ├── hive_storage.dart         # Hive box wrappers
│   │   └── secure_storage.dart       # flutter_secure_storage wrappers
│   ├── utils/
│   │   ├── formatters.dart           # Rs. amounts, dates, masked mobile
│   │   └── validators.dart           # Mobile, Aadhaar, PAN, IFSC validators
│   ├── errors/
│   │   ├── app_exception.dart        # Typed exceptions for each module
│   │   └── error_mapper.dart         # Maps raw errors to user messages
│   └── extensions/
│       └── string_extensions.dart    # maskMobile(), toTitleCase()
├── shared/
│   ├── theme/
│   │   ├── app_colors.dart           # DONE — full color palette
│   │   ├── app_typography.dart       # DONE — Inter font hierarchy
│   │   └── app_spacing.dart          # DONE — 8px grid spacing
│   ├── widgets/
│   │   ├── primary_button.dart       # Gradient fill, loading state, disabled
│   │   ├── secondary_button.dart     # Outlined, no fill
│   │   ├── app_card.dart             # Glassmorphic card, gradient border
│   │   ├── app_text_field.dart       # Consistent input field, inline error
│   │   ├── phone_input_field.dart    # +91 prefix, 10-digit validator
│   │   ├── otp_input_widget.dart     # 6 individual boxes, auto-advance
│   │   ├── step_progress_bar.dart    # 9-dot progress indicator with lines
│   │   ├── document_upload_card.dart # 4-state upload card (see OCR states)
│   │   ├── upload_card_shimmer.dart  # Shimmer overlay for OCR processing
│   │   ├── extracted_data_chip.dart  # Green "Data extracted ✓" chip
│   │   ├── verification_badge.dart   # Animated green checkmark badge
│   │   ├── status_badge.dart         # Colored pill — Verified/Pending/Failed
│   │   ├── section_header.dart       # Styled section title with optional icon
│   │   ├── info_card.dart            # Compact info display card
│   │   ├── empty_state_view.dart     # Empty state with icon + CTA
│   │   ├── error_state_view.dart     # Error state with retry + message
│   │   ├── loading_view.dart         # Full-screen loading indicator
│   │   ├── inline_message_banner.dart# Inline error/success strip
│   │   ├── confirmation_dialog.dart  # Reusable yes/no modal
│   │   └── info_bottom_sheet.dart    # Lightweight sheet for explanations
│   └── layouts/
│       └── scrollable_step_layout.dart # Step screen layout with fixed bottom bar
├── models/                           # App-wide shared Dart models
│   ├── user_model.dart
│   ├── auth_session_model.dart
│   ├── credit_balance_model.dart
│   ├── score_report_model.dart       # Full report with all 7 pillars + SHAP
│   ├── score_pillar_model.dart       # Per-pillar: id, code, title, subtitle, score
│   ├── shap_factor_model.dart        # factor, impact, label — positive/negative
│   ├── loan_offer_model.dart
│   ├── loan_application_model.dart
│   ├── application_timeline_item.dart
│   └── verified_profile/            # Central VerifiedProfile model
│       ├── verified_profile.dart     # Root object accumulating all 9 steps
│       ├── personal_info.dart        # Step 1
│       ├── identity_info.dart        # Step 2
│       ├── bank_info.dart            # Step 3
│       ├── utility_info.dart         # Step 4
│       ├── work_proof_info.dart      # Step 5
│       ├── gov_schemes_info.dart     # Step 6
│       ├── insurance_info.dart       # Step 7
│       ├── tax_info.dart             # Step 8
│       └── emi_loans_info.dart       # Step 9
├── services/                         # App-wide technical service wrappers
│   ├── api_service.dart              # Abstract interface — 13 methods
│   ├── mock_api_service.dart         # Returns static JSON for all 13 endpoints
│   ├── real_api_service.dart         # HTTP + HMAC signing to FastAPI backend
│   ├── ocr_service.dart              # Abstract interface
│   ├── demo_ocr_service.dart         # Returns pre-extracted text per doc type
│   ├── storage_service.dart          # Unified Hive + SecureStorage wrapper
│   └── connectivity_service.dart     # Online/offline status stream
├── state/                            # Global Riverpod providers
│   ├── auth_provider.dart            # Auth state + session
│   ├── user_provider.dart            # Current user identity
│   ├── nav_provider.dart             # Active tab index
│   ├── score_provider.dart           # Score state, report, generation status
│   ├── credit_provider.dart          # Free reports + credit balance
│   ├── loan_provider.dart            # Loan eligibility + selected offer
│   ├── application_provider.dart     # Applications list + refresh
│   ├── language_provider.dart        # Selected language (en/ta/hi)
│   └── connectivity_provider.dart    # Online/offline reactive state
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── otp_verification_screen.dart
│   │   ├── widgets/
│   │   │   ├── auth_mode_switcher.dart
│   │   │   └── otp_resend_timer.dart
│   │   └── controllers/
│   │       └── auth_controller.dart
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   └── widgets/
│   │       ├── hero_score_card.dart
│   │       └── privacy_highlight_section.dart
│   ├── score/
│   │   ├── screens/
│   │   │   ├── score_intro_screen.dart
│   │   │   ├── show_me_how_screen.dart
│   │   │   └── score_generating_screen.dart
│   │   ├── flow/                     # 9 step screens
│   │   │   ├── step1_personal_screen.dart
│   │   │   ├── step2_kyc_screen.dart
│   │   │   ├── step3_bank_screen.dart
│   │   │   ├── step4_utility_screen.dart
│   │   │   ├── step5_work_screen.dart
│   │   │   ├── step6_gov_schemes_screen.dart
│   │   │   ├── step7_insurance_screen.dart
│   │   │   ├── step8_tax_screen.dart
│   │   │   └── step9_emi_loans_screen.dart
│   │   ├── widgets/
│   │   │   ├── step_square_card.dart
│   │   │   ├── score_status_message.dart  # Sequential animated message
│   │   │   └── score_benefit_card.dart
│   │   └── controllers/
│   │       └── score_flow_controller.dart
│   ├── report/
│   │   ├── screens/
│   │   │   ├── score_report_screen.dart
│   │   │   └── certificate_screen.dart
│   │   └── widgets/
│   │       ├── report_header.dart
│   │       ├── score_summary_card.dart
│   │       ├── pillar_breakdown_list.dart
│   │       ├── pillar_contribution_bar.dart
│   │       ├── shap_factors_section.dart
│   │       ├── llm_explanation_card.dart
│   │       ├── suggestion_card.dart
│   │       ├── report_action_bar.dart
│   │       └── certificate_panel.dart
│   ├── loans/
│   │   ├── screens/
│   │   │   ├── loans_screen.dart
│   │   │   └── loan_detail_screen.dart
│   │   └── widgets/
│   │       ├── loan_offer_card.dart
│   │       └── consent_confirmation_sheet.dart
│   ├── applications/
│   │   ├── screens/
│   │   │   ├── applications_screen.dart
│   │   │   └── application_detail_screen.dart
│   │   └── widgets/
│   │       ├── application_card.dart
│   │       ├── application_timeline.dart
│   │       └── application_status_chip.dart
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   └── report_history_screen.dart
│   │   └── widgets/
│   │       ├── user_info_card.dart
│   │       ├── credit_balance_card.dart
│   │       └── account_option_tile.dart
│   └── credits/
│       ├── screens/
│       │   └── buy_credits_screen.dart
│       └── widgets/
│           ├── purchase_quantity_selector.dart
│           └── purchase_summary_card.dart
└── scoring/                          # ON-DEVICE ENGINE — separate from UI
    ├── features/
    │   └── feature_engineer.dart     # VerifiedProfile → List<double>[95]
    ├── models/                       # m2cgen exports from Dev A go here
    │   ├── score_p1_income.dart
    │   ├── score_p2_payment.dart
    │   ├── score_p3_debt.dart
    │   ├── score_p4_savings.dart
    │   ├── score_p5_work.dart        # Deterministic scorecard
    │   ├── score_p6_resilience.dart
    │   └── score_p7_social.dart      # Deterministic scorecard
    ├── engine/
    │   ├── scoring_engine.dart       # Orchestrates all 7 pillar scorers
    │   ├── confidence_engine.dart    # Per-pillar confidence adjustment
    │   └── meta_learner.dart         # 19-input LR → sigmoid → 300-900
    ├── explainability/
    │   └── shap_lookup.dart          # Bin-based lookup from shap_lookup.json
    └── placeholders/
        ├── demo_face_verifier.dart   # Always returns similarity: 0.95
        └── demo_doc_authenticator.dart # Always returns isAuthentic: true
```

---

## SECTION 2: ROUTE MAP (COMPLETE)

Based on `2-navigation-architecture.txt` and `14-flutter-screen-list-and-route-map.txt`

```
PRE-AUTH ROUTES:
  /splash
  /auth/login
  /auth/signup
  /auth/otp

POST-AUTH SHELL (ShellRoute with BottomNav):
  /app/home                           # Tab 0 — Home
  /app/score                          # Tab 1 — Score landing
  /app/score/how-it-works             # Score instructional view
  /app/score/flow/:stepNumber         # Steps 1–9 (dynamic route)
  /app/score/generating               # Full-screen blocking generate
  /app/score/report                   # Report screen
  /app/score/report/certificate       # Certificate child screen
  /app/loans                          # Tab 2 — Loans
  /app/loans/detail/:offerId          # Offer detail + consent
  /app/applications                   # Tab 3 — Applications list
  /app/applications/detail/:appId     # Application tracking detail
  /app/profile                        # Tab 4 — Profile
  /app/profile/buy-credits            # Credit purchase screen
  /app/profile/reports                # Report history screen
```

**Route Guards:**
- All `/app/*` routes redirect to `/auth/login` if auth state is unauthenticated
- `/app/score/flow/*` checks credit eligibility before entering step 1
- `/app/score/report` redirects to `/app/score` if no score result exists
- `/app/loans` shows gated empty state (not a redirect) if no score session

---

## SECTION 3: GLOBAL STATE PROVIDERS (RIVERPOD)

Based on `10 state-management-and-global-rules.txt` and `15-sample-json-models-and-dummy-data-contracts..txt`

| Provider | Type | Owns |
|---|---|---|
| `authProvider` | `StateNotifierProvider<AuthNotifier, AuthState>` | isAuthenticated, token, userId |
| `currentUserProvider` | `StateNotifierProvider<UserNotifier, UserModel?>` | name, mobile, isVerified, preferredLanguage |
| `activeTabProvider` | `StateProvider<int>` | 0–4 bottom nav index |
| `creditBalanceProvider` | `StateNotifierProvider<CreditNotifier, CreditBalanceModel>` | freeReportsUsed, freeRemaining, creditBalance |
| `scoreSessionProvider` | `StateNotifierProvider<ScoreSessionNotifier, ScoreSessionState>` | generationStatus, scoreResult, reportData |
| `verifiedProfileProvider` | `StateNotifierProvider<ProfileNotifier, VerifiedProfile>` | All 9 step data objects |
| `stepStatusProvider` | `StateNotifierProvider<StepStatusNotifier, Map<int, StepStatus>>` | {1: NOT_STARTED, 2: VERIFIED, ...} |
| `loanProvider` | `StateNotifierProvider<LoanNotifier, LoanState>` | offersList, selectedOffer, eligibilityStatus |
| `applicationProvider` | `StateNotifierProvider<ApplicationNotifier, ApplicationState>` | applicationsList, selectedApp, refreshStatus |
| `languageProvider` | `StateProvider<String>` | en / ta / hi |
| `connectivityProvider` | `StreamProvider<bool>` | true = online, false = offline |
| `apiServiceProvider` | `Provider<ApiService>` | Switches mock ↔ real in one line |
| `ocrServiceProvider` | `Provider<OcrService>` | Switches demo ↔ real OCR |

**State Enum Definitions:**
```dart
enum AuthStatus { unauthenticated, loading, authenticated, error }
enum StepStatus { notStarted, inProgress, ocrComplete, pendingVerification, verified, rejected }
enum ScoreGenerationStatus { idle, generating, success, error }
enum UploadCardState { empty, processing, extracted, fallback, uploadError }
enum LoanEligibilityStatus { noScore, eligible, noOffers }
```

---

## SECTION 4: SCREEN-BY-SCREEN PLANNING

### 4.1 SPLASH SCREEN
**File:** `features/auth/screens/splash_screen.dart`
**Spec:** `1-auth-module.txt` Sections 3–6

**Layout:**
- Full-screen dark background (`AppColors.surface`)
- GigCredit logo centered (scale + fade-in animation)
- Tagline: *"Privacy-first. Explainable. Built for the real world."*
- No loading spinner visible to user

**Behavior:**
- On mount: check auth session via `authProvider`
- If valid session → navigate to `/app/home` (replace, no back)
- If no session → navigate to `/auth/login` (replace)
- Minimum display time: 1.5 seconds even if check is faster

**Animations:**
- Logo: `opacity 0→1` + `scale 0.8→1.0` over 800ms with ease-out
- Tagline: delayed 400ms, fade-in only

---

### 4.2 LOGIN SCREEN
**File:** `features/auth/screens/login_screen.dart`
**Spec:** `1-auth-module.txt` Sections 9–10, 26–28

**Layout:**
- Gradient background (navy → deep blue top to bottom)
- Logo + app name at top
- `AuthModeSwitcher` widget (Login / Sign Up tab toggle)
- When Login selected:
  - `PhoneInputField` (+91 prefix, 10-digit)
  - `PrimaryButton` "Send OTP" — gradient, full-width
- Bottom line: "Secure OTP login | Your data stays private"

**Validation:**
- Mobile must be numeric, exactly 10 digits
- Empty field keeps button disabled
- Inline error below field on invalid entry

**Loading States:**
- Send OTP tapped → button shows spinner, field disabled
- On success → navigate to `/auth/otp` with mobile as argument

**Error States:**
- Network error: `InlineMessageBanner` "No internet. Please check your connection."
- User not registered: clear message "This number is not registered." + "Sign Up instead" link

**Animations:**
- Logo + fields slide-up on mount with staggered delays (100ms between)

---

### 4.3 SIGNUP SCREEN
**File:** `features/auth/screens/signup_screen.dart`
**Spec:** `1-auth-module.txt` Sections 11–12

**Layout:** Same as Login screen but with:
- `AppTextField` for Username (required)
- `PhoneInputField` for Mobile

**Validation:**
- Username: cannot be empty
- Mobile: 10-digit numeric
- Both must pass before Send OTP is enabled

**Error States:**
- User already registered: "An account with this number already exists." + "Login instead" link

---

### 4.4 OTP VERIFICATION SCREEN
**File:** `features/auth/screens/otp_verification_screen.dart`
**Spec:** `1-auth-module.txt` Sections 14–21

**Layout:**
- Heading: "Verify OTP"
- Subtext: "OTP sent to +91 XXXXXXXX" (masked mobile from route arg)
- `OtpInputWidget` — 6 individual boxes, auto-advance on each digit entry
- `PrimaryButton` "Verify OTP" — disabled until all 6 boxes filled
- `OtpResendTimer` — countdown from 30s, "Resend OTP" appears after

**Behavior:**
- Auto-submit when 6th digit entered (optional UX enhancement)
- On correct OTP: create session → navigate to `/app/home` (clear back stack)
- On incorrect OTP: clear boxes, show `InlineMessageBanner` "Invalid OTP. Please try again."
- On resend: reset countdown, show brief "OTP resent successfully" banner

**Error States:**
- OTP expired: "Your OTP has expired. Request a new one."
- Network failure: "Unable to verify right now. Check your connection."

---

### 4.5 HOME SCREEN
**File:** `features/home/screens/home_screen.dart`
**Spec:** `3-home-module.txt`

**Layout (top to bottom):**
- `AppBar` with greeting: "Hello, [name]" + settings icon
- `HeroScoreCard` widget:
  - If score exists: animated score circle showing latest score + grade
  - If no score: "Get your Credit Score" CTA card with glowing border pulse
- Privacy highlight strip: "🔒 On-device processing | Data never leaves your phone"
- `PrivacyHighlightSection` — 3 feature tiles:
  - 🔐 Privacy First
  - 💡 Explainable Score
  - ⚡ Instant Results
- `PrimaryButton` "Check Credit Score" → navigates to `/app/score`

**Navigation Rules:**
- "Check Credit Score" → activates Score tab + navigates to score landing
- Tapping score circle (if exists) → navigates to `/app/score/report`

---

### 4.6 SCORE INTRO SCREEN
**File:** `features/score/screens/score_intro_screen.dart`
**Spec:** `4-score-module (1).txt` Sections 5–19

**Layout (top to bottom):**
- Heading: "Know your financial strength" (large, bold)
- Gauge/meter image asset (score visualization illustration)
- Subtext: "Check your credit score to understand financial behaviour and risk level"
- 3 benefit `InfoCard` widgets:
  - Track your credit health
  - Understand your financial risk
  - Get insights to improve your score
- Two CTA buttons:
  - `SecondaryButton` "Show Me How" → `/app/score/how-it-works`
  - `PrimaryButton` "Check Credit Score" → **credit check → flow start**

**Credit Check Interception (before entering flow):**
1. Check `creditBalanceProvider.canGenerateScore`
2. If `true` → navigate to `/app/score/flow/1`
3. If `false` → show `BuyCreditsPrompt` bottom sheet
   - Message: "You've used your free reports. Buy credits to continue."
   - Button: "Buy Credits" → navigate to Profile tab + buy credits
   - If dismissed and tapped again → show prompt again (hard rule)

---

### 4.7 SHOW ME HOW SCREEN
**File:** `features/score/screens/show_me_how_screen.dart`
**Spec:** `4-score-module (1).txt` Sections 11–16

**Layout:**
- AppBar with back arrow (back → Score intro)
- Heading: "What you'll need"
- Grid of 9 `StepSquareCard` widgets (3×3 or 2-column):
  - Step number + name + icon
  - Tapping opens bottom sheet with detailed instructions for that step

**Step Square Card Content:**
| # | Name | Icon |
|---|---|---|
| 1 | Basic Profile | 👤 |
| 2 | Identity KYC | 🪪 |
| 3 | Bank Verification | 🏦 |
| 4 | Utility Bills | 💡 |
| 5 | Work Proof | 💼 |
| 6 | Gov Schemes | 🏛️ |
| 7 | Insurance | 🛡️ |
| 8 | Tax Records | 📄 |
| 9 | EMI / Loans | 💳 |

---

### 4.8 STEP SCREENS — COMMON STRUCTURE
**Spec:** `4-score-module (1).txt` Sections 20–26
**Layout:** Uses `ScrollableStepLayout` widget for all 9 steps

```
[StepProgressBar — 9 dots, current step pulsing]
[Step Title: "Step 2: Identity KYC"]
[Step subtitle/description]
━━━━━━━━━━━━━━━━ (scrollable content below)
[Step-specific form fields and upload cards]
━━━━━━━━━━━━━━━━
[Fixed Bottom Bar]
  [SecondaryButton "Back"] [PrimaryButton "Continue / Verify"]
```

**Step Progress Bar Rules:**
- Completed step: solid green circle + ✓ checkmark
- Current step: pulsing accent color circle
- Not started: muted outline circle
- Tapping a completed step number navigates back to that step

**Continue Button Rules:**
- Disabled (greyed) until all mandatory fields are filled
- Enabled (gradient accent) when ready
- On tap: shows loading spinner during API verification
- After successful verification: brief green success ripple → auto-advance
- On failure: stay on step, show inline error

---

### 4.8.1 STEP 1 — BASIC PROFILE
**File:** `features/score/flow/step1_personal_screen.dart`

Fields:
- Full Name (text) — mandatory
- Date of Birth (date picker) — mandatory
- Gender (dropdown: Male/Female/Other) — mandatory
- Mobile Number (pre-filled from auth, read-only)
- Work Type (dropdown: Platform Worker/Street Vendor/Freelancer/Driver/Other) — mandatory
- Monthly Income Range (dropdown: <5k/5–10k/10–20k/20k+) — mandatory
- State (dropdown) — mandatory
- District / City (text) — mandatory
- Housing Type (dropdown: Own/Rented/Shared) — mandatory
- Dependents Count (number input) — mandatory
- Primary Language (dropdown: English/Tamil/Hindi) — optional

No API verification call. Just local state save. Continue advances to Step 2.

---

### 4.8.2 STEP 2 — IDENTITY KYC
**File:** `features/score/flow/step2_kyc_screen.dart`

**Document uploads (each uses `DocumentUploadCard` 4-state flow):**
- Aadhaar Front (`image_picker`)
- Aadhaar Back (`image_picker`)
- PAN Card (`image_picker`)
- Selfie (`image_picker` — camera only)

**After each upload:**
- OCR runs via `ocrServiceProvider` (demo fallback if confidence < 0.70)
- Extracted fields auto-fill below card:
  - Aadhaar: Name, DOB, Aadhaar Number
  - PAN: Name, PAN Number
- `VerificationBadge` animates in after auto-fill

**API Verification (on Continue):**
- Calls `verifyAadhaar(aadhaarNumber)` via `apiServiceProvider`
- Calls `verifyPan(panNumber)` via `apiServiceProvider`
- Shows individual per-document verification badges on success
- Selfie → `DemoFaceVerifier.verify()` → always returns matched

---

### 4.8.3 STEP 3 — BANK VERIFICATION
**File:** `features/score/flow/step3_bank_screen.dart`

Fields:
- Bank Name (text)
- IFSC Code (text — uppercase, format validator)
- Account Number (text)
- Confirm Account Number (text — must match)
- Bank Statement PDF (`file_picker` — PDF only)

**PDF upload → OCR/parsing via `ocrServiceProvider`:**
- Demo: returns pre-parsed 127 transactions
- Extracts: balance, EMIs detected, average credit/debit

**API Calls (on Continue):**
- `verifyIfsc(ifsc)` — validates IFSC format and bank
- `verifyAccount(accountNumber, ifsc)` — bank mock verification
- `checkLoans(accountNumber)` — detects existing active EMIs

---

### 4.8.4 STEP 4 — UTILITY BILLS
**File:** `features/score/flow/step4_utility_screen.dart`

**3 categories, 6-month uploads each:**
- Electricity Bills (6 upload cards — months labeled)
- LPG Bills (6 upload cards)
- Mobile Bills (6 upload cards)

**Note:** All are optional individually but at least one category recommended.
OCR extracts: Consumer Number, Amount Due, Due Date, Provider Name.

---

### 4.8.5 STEP 5 — WORK PROOF
**File:** `features/score/flow/step5_work_screen.dart`

**Dynamic form — shows relevant fields based on Step 1 Work Type:**

If Platform Worker (Swiggy/Zomato/Ola/Uber):
- Earnings screenshot upload (last 3 months)
- OCR extracts: trips count, earnings amount

If Driver/Vehicle Owner:
- RC (Registration Certificate) upload — calls `verifyVehicle(vehicleNumber)`
- Driving License upload

If Street Vendor/Freelancer:
- Business registration (if any)
- Client payment proof screenshots

All work types:
- Income consistency evidence (UPI screenshots, optional)

---

### 4.8.6 STEP 6 — GOVERNMENT SCHEMES
**File:** `features/score/flow/step6_gov_schemes_screen.dart`

All fields optional, each has a toggle (has / doesn't have):
- eShram UAN → if toggled: `verifyEshram(uan)`
- PMSYM UAN → if toggled: `verifyPmsym(uan)`
- PM Mudra Loan reference
- SHG membership details
- Jan Dhan account indicator
- PMKVY certificate (upload)

Each verified field shows `VerificationBadge` instantly.

---

### 4.8.7 STEP 7 — INSURANCE
**File:** `features/score/flow/step7_insurance_screen.dart`

3 insurance sections (each optional):
- Health Insurance: Policy Number, Provider → `verifyInsurance(policyNumber, "health")`
- Vehicle Insurance: Policy Number, Provider → `verifyInsurance(policyNumber, "vehicle")`
- Life Insurance: Policy Number, Provider, Sum Assured → `verifyInsurance(policyNumber, "life")`

---

### 4.8.8 STEP 8 — TAX RECORDS
**File:** `features/score/flow/step8_tax_screen.dart`

Fields:
- ITR Filed (toggle: Yes/No)
  - If Yes: Assessment Year (dropdown), ITR Acknowledgement upload → `verifyItr(pan, year)`
- GST Registration (toggle: Yes/No)
  - If Yes: GST Number (text field)

---

### 4.8.9 STEP 9 — EMI / LOANS
**File:** `features/score/flow/step9_emi_loans_screen.dart`

Fields:
- "Do you have active loans?" (toggle)
- If Yes: up to 5 loan cards, each card has:
  - Lender Name (text)
  - Loan Type (dropdown: Home/Vehicle/Personal/Gold/Other)
  - Outstanding Balance (number)
  - Monthly EMI (number)
  - Tenure Remaining (months)
- "Add Another Loan" button (up to 5 max)
- Final CTA: "Generate Score" (large gradient button)

---

### 4.9 SCORE GENERATING SCREEN
**File:** `features/score/screens/score_generating_screen.dart`
**Spec:** `4-score-module (1).txt` Sections 28–28E (newly added)

**Layout:**
- Full dark screen
- GigCredit logo top center (small)
- Pulsing gradient ring (center) — animated with `flutter_animate`
- `ScoreStatusMessage` widget — fades between 6 status messages:
  1. "Analysing income patterns..."
  2. "Checking payment discipline..."
  3. "Evaluating debt and obligations..."
  4. "Measuring savings behaviour..."
  5. "Verifying work and identity signals..."
  6. "Computing your credit score..."
- Linear progress bar below — fills across all 6 messages
- Subtext: "Your data never leaves your device 🔒"

**Behavior:**
- Back navigation: DISABLED (WillPopScope returns false)
- Tab switching: DISABLED
- Each message shows for ~2.5 seconds with crossfade
- Real scoring runs as a Future in background
- If scoring finishes before message 5: wait until message 5 completes
- If scoring fails: emit fallback score after all messages complete
- On final message complete → navigate to `/app/score/report` (replace)

---

### 4.10 SCORE REPORT SCREEN
**File:** `features/report/screens/score_report_screen.dart`
**Spec:** `5-report-module.txt` (all 50 sections)

**Layout (scrollable, sections stacked):**

**Section 1 — Report Header:**
- Title: "Your Credit Report"
- Generated date (formatted: "25 Apr 2026")
- "Generated Successfully" badge

**Section 2 — Score Summary Card:**
- Animated score counter: 0 → actual score (3s, ease-out)
- Score display: `742 / 900`
- Grade badge pill: "Grade B" (color-coded by grade)
- Risk band: "Moderate Risk"
- Subtext: "Based on your verified financial behaviour"
- `confetti` package fires for scores ≥ 720 on mount

**Section 3 — SHAP Factors:**
- "Your Strengths" heading (green)
  - 3 `ShapFactorCard` — green, each shows: label + impact "+12 pts"
- "Areas to Improve" heading (red/amber)
  - 3 `ShapFactorCard` — amber, each shows: label + impact "-9 pts"

**Section 4 — LLM Explanation Card:**
- Card with AI icon
- `AnimatedTextKit` typewriter effect for `llmExplanation` string
- Language selector pills: EN | தமிழ் | हिं (calls `/api/report/generate` again on switch)

**Section 5 — Pillar Breakdown (7 pillars, all mandatory):**
- `PillarBreakdownList` — 7 `PillarContributionBar` widgets
  - Bar fills from 0 → score with staggered 200ms delay each
  - Shows: pillarCode (P1), title, subtitle, score label "78/100"
  - If score = 0: label "Insufficient data" in muted color

**Section 6 — Improvement Suggestions:**
- "How to Improve" heading
- 3 `SuggestionCard` widgets — numbered, with actionable tip

**Section 7 — Action Bar:**
- `PrimaryButton` "Apply for Loan" → activate Loans tab + navigate
- `SecondaryButton` "Download Report PDF" → trigger PDF generation
- Outlined button "Credit Assessment Certificate" → navigate to `/app/score/report/certificate`

---

### 4.11 CERTIFICATE SCREEN
**File:** `features/report/screens/certificate_screen.dart`
**Spec:** `5-report-module.txt` Sections 33–38

**Layout (centered, formal card style):**
```
┌─────────────────────────┐
│     GigCredit           │
│  Score Ownership Proof  │
│                         │
│  Name: Ravi Kumar       │
│  Mobile: +91 xxxxxx4210 │
│                         │
│  Score: 742 / 900       │
│                         │
│  Generated On: 25 Apr   │
│  Proof ID: GC-PROOF-... │
│                         │
│     ✓ VERIFIED          │
└─────────────────────────┘
```

**Rules:**
- All fields populated from `scoreSessionProvider` data
- Mobile shown masked (last 4 digits visible)
- If any field unavailable: show "—" placeholder, not null/undefined
- Back navigation → returns to report screen

---

### 4.12 LOANS SCREEN
**File:** `features/loans/screens/loans_screen.dart`
**Spec:** `6-loans module.txt`, `2-navigation-architecture.txt` Sections 20–26

**State 1 — No Score (Empty/Gated):**
- `EmptyStateView`:
  - Icon: 🏦
  - Message: "Check your score to view loan offers"
  - CTA Button: "Check My Score" → activate Score tab

**State 2 — Offers Available:**
- Header: "You're eligible for loans!"
- 3 `LoanOfferCard` widgets (hardcoded NBFC data):
  - QuickCredit Finance — up to ₹1,00,000 — 14.5% — 12–36 months
  - GigFund NBFC — up to ₹50,000 — 16.0% — 6–24 months
  - WorkerFirst Capital — up to ₹75,000 — 15.0% — 12–24 months
- Each card has "Apply Now" button → `ConsentConfirmationSheet`

**Consent Sheet:**
- Explains: "Only your derived score and risk profile will be shared. Raw data stays private."
- Checkbox: "I understand and consent to this"
- "Submit Application" button (disabled until checkbox ticked)
- On submit → creates application → shows success → notify to check Applications tab

---

### 4.13 APPLICATIONS SCREEN
**File:** `features/applications/screens/applications_screen.dart`
**Spec:** `7 applications module.txt`, `11-error-states-and-empty-states.txt` Section 31

**Empty State:**
- Icon: 📋
- Message: "No applications yet"
- Subtext: "Your submitted loan applications will appear here"
- CTA: "Explore Loan Offers" → activate Loans tab

**List State:**
- `ApplicationCard` for each application:
  - Lender name + loan amount
  - `ApplicationStatusChip` — color-coded status
  - "Track Progress" button

**Detail Screen (`application_detail_screen.dart`):**
- `ApplicationTimeline` widget showing progress stages:
  - Application Submitted ✅
  - Consent Verified ✅
  - Under Review ⟳ (CURRENT)
  - Decision Pending ○ (UPCOMING)

---

### 4.14 PROFILE SCREEN
**File:** `features/profile/screens/profile_screen.dart`
**Spec:** `8 - profile module.txt`

**Layout:**
- `UserInfoCard` — name, mobile, verified badge
- `CreditBalanceCard`:
  - "Free Reports: X remaining"
  - "Credit Balance: X credits"
  - "Buy Credits" button → `/app/profile/buy-credits`
- Section: "My Reports" → taps to `/app/profile/reports`
- Section Separator
- `AccountOptionTile` items:
  - Privacy Settings
  - Delete My Data (shows confirmation dialog)
  - Logout (shows confirmation dialog → clears session → `/auth/login`)

---

### 4.15 BUY CREDITS SCREEN
**File:** `features/credits/screens/buy_credits_screen.dart`
**Spec:** `9 credit-system-and-purchase-flow.txt`

**Layout:**
- Heading: "Buy Report Credits"
- `PurchaseQuantitySelector`:
  - Minimum: 10 credits
  - Step: 10 credits
  - Stepper buttons (+ and −)
  - Shows: "20 credits = ₹158"
- `PurchaseSummaryCard`:
  - Credits selected, Total amount
  - "10 credits = ₹79" price rule displayed
- `PrimaryButton` "Confirm Purchase" → payment flow (mock success)
- On success: update `creditBalanceProvider`, show "Credits added!" banner

---

## SECTION 5: UPLOAD CARD 4-STATE BEHAVIOR (IMPLEMENTATION SPEC)

Based on `4-score-module (1).txt` Sections 45B–45D (newly added in fix)

```dart
enum UploadCardState { empty, processing, extracted, fallback, uploadError }

// State 1: EMPTY
// - DashedBorderContainer
// - CloudUploadIcon (centered)
// - Text: "Tap to upload"

// State 2: PROCESSING (fires immediately after file picked)
// - UploadCardShimmer overlaid on card
// - Rotating mini-indicator top-right corner
// - Text: "Extracting data..."
// - disables re-tap

// State 3: EXTRACTED (OCR confidence >= 0.70)
// - File thumbnail or PDF icon
// - ExtractedDataChip (green, top-right): "Data extracted ✓"
// - Card border: AppColors.verified (green)
// - Below card: auto-filled text fields slide in

// State 4: FALLBACK (OCR failed, demo data used silently)
// - File thumbnail
// - Neutral chip (top-right): "Uploaded. Please verify below."
// - Card border: neutral
// - Below card: input fields highlighted with yellow border for manual verify

// State UPLOAD_ERROR (file rejected - wrong format or too large)
// - Red InlineMessageBanner below card: "Upload failed. Please try a valid file."
// - Card resets to EMPTY state

// Transitions — all use crossfade 300ms:
// EMPTY → PROCESSING (on file picked)
// PROCESSING → EXTRACTED (on OCR success)
// PROCESSING → FALLBACK (on OCR failure)
// EXTRACTED → EMPTY (on re-upload tap)
```

---

## SECTION 6: SEQUENTIAL SCORE MESSAGES (IMPLEMENTATION SPEC)

Based on `4-score-module (1).txt` Sections 28B–28E (newly added in fix)

```dart
// ScoreStatusMessage widget
const List<String> kScoreMessages = [
  'Analysing income patterns...',
  'Checking payment discipline...',
  'Evaluating debt and obligations...',
  'Measuring savings behaviour...',
  'Verifying work and identity signals...',
  'Computing your credit score...',
];

// Duration per message: 2500ms
// Each transition: crossfade 400ms
// Progress bar increments: 100% / 6 = 16.67% per step
// Back navigation: WillPopScope → return false
// Completion: after message 6 fades out → navigate to report
// Fallback: if scoring error → apply ScoreResult(finalScore: 682, grade: 'B') before navigating
```

---

## SECTION 7: ERROR & NOTIFICATION SYSTEM (COMPLETE)

Based on `11-error-states-and-empty-states.txt` (all 45 sections)

### 7.1 Global Error Components

| Component | Use case |
|---|---|
| `InlineMessageBanner` | Field-level errors, OTP errors, upload errors |
| `ErrorStateView` | Full-screen fetch failures with retry |
| `EmptyStateView` | No data yet — Applications, Reports, Loans |
| `ConfirmationDialog` | Logout, data deletion, consent |
| `BuyCreditsPrompt` | Credit block interception bottom sheet |
| `FullScreenFailureView` | Catastrophic failure with back route |

### 7.2 Specific Error Copy (Authoritative)

| Scenario | Message Copy |
|---|---|
| Invalid mobile | "Please enter a valid 10-digit mobile number." |
| User not registered | "This number is not registered. Sign up instead?" |
| User already registered | "An account already exists with this number. Log in instead?" |
| Wrong OTP | "Invalid OTP. Please try again." |
| Didn't get OTP | "Didn't receive OTP? Resend" |
| Upload failed | "Upload failed. Please try again." |
| Score generation failed | "Something went wrong. Retry generating your score." |
| No credits | "You've used your free reports. Buy credits to continue." |
| Loans — no score | "Check your score to view loan offers." |
| No eligible loans | "No matching offers available right now." |
| No applications | "No applications yet. Submitted applications will appear here." |
| No reports history | "No reports yet. Generate your first score." |
| Generic fallback | "Something went wrong. Please try again." |
| Offline (auth) | "No internet. Please check your connection." |
| Credit purchase rule | "Credits must be purchased in multiples of 10. Minimum 10 credits." |

---

## SECTION 8: NOTIFICATION REACTIONS TABLE

Based on `11-error-states-and-empty-states.txt` and `4-score-module (1).txt`

| User Action | Correct Outcome | Wrong Outcome |
|---|---|---|
| Taps "Check Score" with no credits | BuyCreditsPrompt appears, flow blocked | Nothing happens, user enters flow |
| Dismisses prompt, taps again | BuyCreditsPrompt appears again | Flow opens without credits |
| Upload document | UploadCard → Processing shimmer | No feedback, confusion |
| OCR succeeds | Green "Data extracted" chip + auto-fill | Manual fields empty |
| OCR fails silently | Neutral "Uploaded. Please verify below." | Error screen breaks flow |
| File wrong format | Red inline error below card | Nothing happens |
| Continue button on incomplete step | Button stays disabled | Proceeds with missing data |
| Verification API succeeds | VerificationBadge animates in per document | Nothing shown |
| Verification API fails | Inline error, stay on step, retry | App navigates away |
| Score generation error | Runs full animation → fallback score → report | App crashes |
| Report to Loans tap | Loans tab activates in BottomNav | User stays on Report |
| Logout | Session cleared, navigate to Login | Stale data visible after logout |

---

## SECTION 9: DESIGN TOKEN REFERENCE

Based on `PHASE_2_10_DEV_B_UI_UX_DETAILED.md` + `specification folders_new/frontend/theme`

```dart
// Colors (already in app_colors.dart)
primary   = 0xFF1A1A2E   // Deep navy
accent    = 0xFF0F3460   // Electric blue
highlight = 0xFFE94560   // Pink accent
surface   = 0xFF0A0A1A   // Background (darkest)
card      = 0xFF1E1E3A   // Card bg
verified  = 0xFF00E676   // Green checkmark
success   = 0xFF4CAF50
warning   = 0xFFFFC107
error     = 0xFFF44336

// Grade Colors
gradeS = 0xFF00E676   // Green — 800-900
gradeA = 0xFF4CAF50   // Light green — 720-799
gradeB = 0xFF8BC34A   // Yellow-green — 640-719
gradeC = 0xFFFFC107   // Amber — 560-639
gradeD = 0xFFFF9800   // Orange — 480-559
gradeE = 0xFFF44336   // Red — 300-479

// Spacing (already in app_spacing.dart)
xs=4, sm=8, md=16, lg=24, xl=32, xxl=48

// Border Radius
cardRadius   = 16.0
buttonRadius = 12.0
chipRadius   = 20.0
fieldRadius  = 10.0

// Animation Durations
fast     = 200ms   // Micro-interactions
standard = 300ms   // Most transitions
slow     = 600ms   // Score counter, bar fills
dramatic = 3000ms  // Score counter 0→actual
```

---

## SECTION 10: IMPLEMENTATION ORDER (STRICT SEQUENCE)

Follows `DEV_B_AGENT_IMPLEMENTATION_GUIDE.md` Section 6 + this document

```
ALREADY DONE ✅
  Step 1: Flutter project created (flutter create --org com.gigcredit .)
  Step 2: pubspec.yaml with all dependencies
  Step 3: app_colors.dart, app_typography.dart, app_spacing.dart

IMMEDIATE NEXT — FOUNDATION LAYER
  Step 4: app.dart (MaterialApp.router + full dark theme)
  Step 5: app_router.dart (ALL routes defined using GoRouter)
  Step 6: app_shell.dart (BottomNav 5 tabs + IndexedStack)
  Step 7: main.dart (ProviderScope + Hive.initFlutter() + runApp)

SERVICE LAYER (before any screen)
  Step 8: api_service.dart (abstract interface, 13 methods)
  Step 9: mock_api_service.dart (static JSON for all 13 endpoints)
  Step 10: ocr_service.dart (abstract interface)
  Step 11: demo_ocr_service.dart (pre-extracted per doc type)
  Step 12: apiServiceProvider + ocrServiceProvider in state/

SHARED COMPONENT LAYER
  Step 13: primary_button.dart, secondary_button.dart
  Step 14: app_card.dart, app_text_field.dart, phone_input_field.dart
  Step 15: otp_input_widget.dart, otp_resend_timer.dart
  Step 16: document_upload_card.dart (all 4 states)
  Step 17: upload_card_shimmer.dart, extracted_data_chip.dart
  Step 18: verification_badge.dart, status_badge.dart
  Step 19: step_progress_bar.dart
  Step 20: empty_state_view.dart, error_state_view.dart, loading_view.dart
  Step 21: inline_message_banner.dart, confirmation_dialog.dart

SCREEN BUILD ORDER
  Step 22: splash_screen.dart
  Step 23: login_screen.dart + signup_screen.dart
  Step 24: otp_verification_screen.dart
  Step 25: home_screen.dart
  Step 26: score_intro_screen.dart + show_me_how_screen.dart
  Step 27: step1_personal_screen.dart through step9_emi_loans_screen.dart
  Step 28: score_generating_screen.dart (6 sequential messages)
  Step 29: score_report_screen.dart (all 7 pillars, SHAP, LLM, actions)
  Step 30: certificate_screen.dart
  Step 31: loans_screen.dart + loan_detail_screen.dart
  Step 32: applications_screen.dart + application_detail_screen.dart
  Step 33: profile_screen.dart + report_history_screen.dart
  Step 34: buy_credits_screen.dart

MODEL LAYER
  Step 35: verified_profile.dart + all 9 sub-models
  Step 36: score_report_model.dart (all 7 pillars + SHAP + grade)

SCORING ENGINE
  Step 37: feature_engineer.dart (VerifiedProfile → 95 features)
  Step 38: scoring_engine.dart (skeleton — weighted sum until m2cgen arrives)
  Step 39: meta_learner.dart (dot product + sigmoid → 300-900)
  Step 40: confidence_engine.dart
  Step 41: shap_lookup.dart (loads shap_lookup.json)
  Step 42: demo_face_verifier.dart + demo_doc_authenticator.dart

REAL INTEGRATION
  Step 43: hmac_signer.dart
  Step 44: real_api_service.dart
  Step 45: Switch apiServiceProvider to real (one-line change)

FINAL POLISH
  Step 46: PDF export (pdf package)
  Step 47: Page transition animations via flutter_animate
  Step 48: Confetti on score reveal (scores ≥ 720)
  Step 49: Haptic feedback on primary button taps
  Step 50: Shimmer loading on all list/card loading states
  Step 51: App icon + splash screen branding
  Step 52: flutter build apk --release
```

---

## SECTION 11: INTEGRATION GATES CHECKLIST (Dev B Side)

Based on `04_INTEGRATION_CHECKPOINTS_AND_GATES.md`

### G0 Checkpoint (Hour 4) — Dev B Must Have:
- [ ] Flutter project running with all dependencies resolved
- [ ] GoRouter with all routes navigable (placeholder screens)
- [ ] MockApiService returning static JSON for all 13 endpoints
- [ ] DemoOcrService returning pre-extracted data per document type
- [ ] 5-tab bottom navigation shell working
- [ ] Design system tokens applied to all placeholder screens

### G1 Checkpoint (Hour 16) — Dev B Must Have:
- [ ] All 9 step screens built with correct fields
- [ ] Upload cards working through all 4 states with mock OCR
- [ ] Auth flow (Login → OTP → Home) working with MockApiService
- [ ] VerifiedProfile model accumulating data across all steps
- [ ] Score generating screen with sequential messages running

### G2 Checkpoint (Hour 24) — Dev B Must Have:
- [ ] Switched to RealApiService for OTP and KYC steps
- [ ] Verification badges animate in after real API responses
- [ ] HMAC signing working on all requests
- [ ] Score report screen rendering with dummy scoreResult data

### G3 Checkpoint (Hour 36) — Dev B Must Have:
- [ ] m2cgen Dart files copied from `ml_pipeline/output/dart_exports/`
- [ ] FeatureEngineer producing 95 features from VerifiedProfile
- [ ] ScoringEngine running all 7 pillars
- [ ] MetaLearner producing score 300–900
- [ ] ShapLookup producing top 3+/3- factors
- [ ] Parity test passing (golden_inference.json matches)

### G4 Checkpoint (Hour 48) — Dev B Must Have:
- [ ] PDF export working
- [ ] Confetti on score reveal ≥ 720
- [ ] Release APK built and tested on physical device
- [ ] Full demo flow rehearsed 3 times without failure

---

## SECTION 12: PIVOT/RISK TABLE (Dev B Specific)

| Risk | Likelihood | Mitigation |
|---|---|---|
| m2cgen Dart export arrives late | Medium | Use weighted-sum skeleton scorer — demo produces valid score range |
| PaddleOCR native install fails | Medium | DemoOcrService handles all demo docs silently |
| GoRouter 13.x breaking API | Low | Pin exact version in pubspec, test routes immediately |
| `fl_chart` rendering crash on older devices | Low | Wrap in try-catch, fallback to simple ListView of pillar rows |
| `pdfx` PDF text extraction fails | Medium | DemoOcrService returns pre-parsed 127 transactions |
| Score is NaN or out-of-range | Low | Fallback: `ScoreResult(finalScore: 682, grade: 'B', riskBand: 'Medium')` |
| LLM Groq API timeout | Medium | Fallback LLM text hardcoded for demo score (matches grade B explanation) |
| App crashes on low-RAM device | Medium | Run TFLite in single background Isolate — ML computation off main thread |

---

*Document 34 created: 2026-04-25T18:04:53+05:30*
*Based on: complete analysis of all 16 frontend specification files in frontend/ directory*
*Complementary to: PHASE_2_10_DEV_B_UI_UX_DETAILED.md (Document 10), 29_DEV_B_COMPLETE_CHECKLIST.md (Document 29)*
