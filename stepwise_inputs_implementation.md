# GigCredit — Step-wise Inputs: Current Implementation
**Source:** Direct code inspection of all 9 step screens  
**Date:** 2026-05-02

---

## STEP 1 — Personal Info
**File:** `step1_personal_screen.dart` (472 lines)  
**Model:** `PersonalInfo`  
**Mock fill:** Double-tap on Full Name field → fills all fields with Ravi Kumar demo data

### Controllers & State Variables
```dart
TextEditingController _nameCtrl          // Full Name
TextEditingController _dobCtrl           // Date of Birth
TextEditingController _mobileCtrl        // Mobile Number
TextEditingController _currentAddrCtrl   // Current Address
TextEditingController _permAddrCtrl      // Permanent Address
TextEditingController _incomeCtrl        // Monthly Income
TextEditingController _secondaryIncomeCtrl  // Secondary Income (optional)

String _selectedState = 'Tamil Nadu'     // Dropdown — 36 states/UTs
String _selectedWorkType = 'platform_worker'  // Dropdown — 4 types
int _yearsInProfession = 2               // Stepper 0–40
int _dependents = 1                      // Stepper 0–10
bool _vehicleOwnership = true            // Toggle
bool _sameAddress = false                // Checkbox (copies current→permanent)
```

### All Fields with Validation

| # | Label | Input Type | Validation | Required |
|---|---|---|---|---|
| 1 | Full Name (as on Aadhaar) | Text | `[a-zA-Z\s]+`, 2–50 chars | ✅ |
| 2 | Date of Birth (DD/MM/YYYY) | DateTime keyboard | `split('/')` → 3 parts check | ✅ |
| 3 | Mobile Number | Phone (+91 prefix) | 10 digits, starts with `[6-9]` | ✅ |
| 4 | Current Address | MultiLine Text | 10–200 chars | ✅ |
| 5 | Permanent Address | MultiLine Text | 10+ chars (hidden if `_sameAddress=true`) | Conditional |
| 6 | State of Residence | Dropdown | Must select (36 Indian states) | ✅ |
| 7 | Primary Work Type | Dropdown | `platform_worker/vendor/tradesperson/freelancer` | ✅ |
| 8 | Monthly Income (₹) | Number (₹ prefix) | ₹1,000–₹5,00,000 | ✅ |
| 9 | Years in Profession | Stepper | 0–40 | ✅ |
| 10 | Number of Dependents | Stepper | 0–10 | ✅ |
| 11 | Do you own a vehicle? | Toggle Switch | Boolean | ✅ |
| 12 | Secondary Income (₹/month) | Number (₹ prefix) | No validation | ❌ Optional |

### Form Validation Gate (`_isFormValid`)
```dart
if (_nameCtrl.text.trim().length < 2) return false;
if (_dobCtrl.text.isEmpty) return false;
if (_mobileCtrl.text.length != 10) return false;
if (_currentAddrCtrl.text.trim().length < 10) return false;
if (!_sameAddress && _permAddrCtrl.text.trim().length < 10) return false;
if (_incomeCtrl.text.isEmpty) return false;
```
Button: `isDisabled: !_isFormValid && !isVerified`

### Submit Logic
```dart
verifiedProfileProvider.updateStep1(PersonalInfo(
  isVerified: true,
  fullName, dateOfBirth, mobileNumber,
  currentAddress, permanentAddress,
  stateOfResidence, workType,
  selfDeclaredIncome: double.parse(incomeCtrl),
  yearsInProfession, dependents,
  vehicleOwnership, secondaryIncome,
));
stepStatusProvider.setStatus(1, StepStatus.verified);
→ push to /app/score/flow/2
```

### Mock Data Values
```
Name: Ravi Kumar | DOB: 15/06/1995 | Mobile: 9876543210
Address: 23, 4th Cross Street, Anna Nagar, Chennai
State: Tamil Nadu | WorkType: platform_worker
Income: ₹25,000 | Secondary: ₹5,000
Years: 4 | Dependents: 2 | Vehicle: true
```

---

## STEP 2 — KYC Verification
**File:** `step2_kyc_screen.dart` (665 lines)  
**Model:** `KycInfo`

### Section A — Aadhaar

| # | Field/Action | Type | Validation | Status |
|---|---|---|---|---|
| 1 | Aadhaar Number | Text (12 digits) | Length = 12 | ✅ |
| 2 | Verify Aadhaar button | API call | `POST /gov/aadhaar/verify` → OTP | ✅ |
| 3 | OTP Dialog | 6-digit input | Exact match returned OTP | ✅ |
| 4 | Aadhaar Front Upload | Image | `RealOcrService` → keyword: AADHAAR/UIDAI | ✅ |
| 5 | Aadhaar Back Upload | Image | OCR runs → sets `_aadhaarBackExtracted` | ⚠️ no data extracted |

**API response fields used:** `name`, `dob`, `state`, `otp`  
**On success:** `_aadhaarVerified = true`, field auto-fills from API response

### Section B — PAN

| # | Field/Action | Type | Validation | Status |
|---|---|---|---|---|
| 6 | PAN Number | Text (10 chars, CAPS) | Length = 10 | ✅ |
| 7 | Verify PAN button | API call | `POST /gov/pan/verify` → OTP | ✅ |
| 8 | OTP Dialog | 6-digit input | Exact match | ✅ |
| 9 | PAN Card Upload | Image | Regex `[A-Z]{5}\d{4}[A-Z]` extraction | ✅ |

**API response fields used:** `name`, `dob`, `pan_active`, `itr_filed`, `otp`

### Section C — Live Selfie

| # | Field/Action | Current Implementation | Status |
|---|---|---|---|
| 10 | Capture Selfie | Camera via `DocumentUploadCard(useCamera: true)` | ✅ |
| 11 | Face Match | `DemoFaceVerifier.verify(aadhaarPath, panPath, selfiePath)` | ❌ `Random() > 0.1` |

**Face match result:** `isMatch = Random().nextDouble() > 0.1` — 90% random pass, 10% random fail

### Cross-Step Validation
```dart
_runCrossValidation() {
  CrossStepValidator.validate(ocrResults)  // Returns [] always — STUB
}
```

### Completion Gate
```dart
_aadhaarVerified && _aadhaarFrontExtracted &&
_panVerified && _panExtracted && _selfieVerified
```

### Submit Logic
```dart
verifiedProfileProvider.updateStep2(KycInfo(
  isVerified: true,
  backVerified: _aadhaarBackExtracted,
  selfieVerified: _selfieVerified,
));
→ push to /app/score/flow/3
```

---

## STEP 3 — Bank Information
**File:** `step3_bank_screen.dart` (504 lines)  
**Model:** `BankInfo`  
**Mock fill:** Double-tap on Bank Name field

### Primary Bank Fields

| # | Field | Type | Validation | Verification |
|---|---|---|---|---|
| 1 | Bank Name | Text | Non-empty | Auto-filled from IFSC API |
| 2 | Account Holder Name | Text | Non-empty | Auto-filled from Account API |
| 3 | Branch Name | Text | Non-empty | Auto-filled from IFSC API |
| 4 | IFSC Code | Text (11 chars) | Length = 11 | `POST /bank/ifsc/verify` → `_ifscVerified = true` |
| 5 | Account Number | Text (≤18) | Non-empty, IFSC must verify first | `POST /bank/account/verify` → `_accVerified = true` |
| 6 | MICR Code | Text | Optional, no validation | None |
| 7 | UPI ID | Text | Optional, no validation | None |

### Bank Statement Upload

| # | Field | DocType | Current Implementation |
|---|---|---|---|
| 8 | Bank Statement (PDF/Image) | `bank_statement` | Syncfusion PDF text extraction + keyword check |

**Account match logic (bypassed):**
```dart
// Code exists: rawText.contains(expectedAccountNumber)
// But surrounded by: "// We bypass the strict check for the demo"
// So _pdfUploaded = true regardless of match
```

### Secondary Bank (Optional Toggle)
Same fields as primary bank but **no API verification calls** for IFSC/account.

### Submit Gate
```dart
_isFormValid = bankName + holderName + branch + ifsc + account all non-empty
              AND _pdfUploaded == true
              AND _ifscVerified == true
              AND _accVerified == true
```

### Submit Logic
```dart
verifiedProfileProvider.updateStep3(BankInfo(isVerified: true));
// NOTE: No field values stored in BankInfo model
→ push to /app/score/flow/4
```

---

## STEP 4 — Utility Bills
**File:** `step4_utility_screen.dart` (356 lines)  
**Model:** `UtilityInfo`  
**All modules optional. No field validation. Button always enabled.**

### Module Structure (SwitchListTile for each)
Each module: **Toggle ON/OFF → fields expand → up to 6 consecutive bill uploads**

| Module | Toggle Variable | Fields | DocType | OCR Classification |
|---|---|---|---|---|
| ⚡ Electricity | `_hasElectricity` | Consumer No, Name, Amount | `utility_electricity` | BILL, INVOICE, AMOUNT |
| 📶 WiFi/Broadband | `_hasWater` *(bug: wrong var name)* | Account No, Name, Amount | `utility_wifi` | BILL, INVOICE, AMOUNT |
| 🔥 Gas/LPG | `_hasGas` | BP Number, Name, Amount | `utility_gas` | BILL, INVOICE, AMOUNT |
| 📱 Mobile/Phone | `_hasMobile` | Mobile No, Account No, Name, Amount | `utility_mobile` | BILL, INVOICE, AMOUNT |
| 🌐 Internet | `_hasInternet` | Account No, Name, Amount | `utility_internet` | BILL, INVOICE, AMOUNT |
| 🏠 Rent | `_hasRent` | Tenant Name, Landlord Name, Address, Amount | `utility_rent` | BILL, INVOICE, AMOUNT |

### Upload Counter Logic
```dart
// Each module starts at 1 upload slot
// onExtracted: if (count < 6) count++
// This shows a new upload card for next consecutive month
int _elecUploadCount = 1;   // Grows to max 6
int _waterUploadCount = 1;
// ... same for all 6 modules
```

### Submit Logic
```dart
verifiedProfileProvider.updateStep4(UtilityInfo(isVerified: true));
// NOTE: No field values stored — only boolean
→ push to /app/score/flow/5
```

---

## STEP 5 — Work Proof
**File:** `step5_work_screen.dart` (345 lines)  
**Model:** `WorkInfo`  
**Dynamic: content changes by `personalInfo.workType` from Step 1**  
**Mock fill:** Double-tap on hidden 10×10px transparent area

### Variant A — Platform Worker (`workType == 'platform_worker'`)

| # | Field/Upload | Type | OCR DocType | Validation |
|---|---|---|---|---|
| 1 | Vehicle Registration Number | Text | — | None |
| 2 | RC Book Photo | Image upload | `work_rc` | Keywords: REGISTRATION, VEHICLE, CHASSIS |
| 3 | DL Front Photo | Image upload | `work_dl_front` | Keywords: DRIVING, LICENCE, TRANSPORT |
| 4 | DL Back Photo | Image upload | `work_dl_back` | Keywords: DRIVING, LICENCE |
| 5 | Vehicle Insurance Certificate | Image upload | `insurance_vehicle` | No classification |
| 6 | Earnings Screenshot 1 | Image upload | `work_payout` | No classification |
| 7 | Earnings Screenshot 2 | Image upload | `work_payout` | No classification |
| 8 | Earnings Screenshot 3 | Image upload | `work_payout` | No classification |

### Variant B — Street Vendor (`workType == 'vendor'`)

| # | Field/Upload | Type | Validation |
|---|---|---|---|
| 1 | PM SVANidhi Application ID | Text | None |
| 2 | SVANidhi Approval Letter Photo | Image | No classification |
| 3 | Municipal Trade Licence Photo | Image | No classification |

### Variant C — Tradesperson (`workType == 'tradesperson'`)

| # | Field/Upload | Type | Validation |
|---|---|---|---|
| 1 | NSDC Skill Certificate ID | Text | None |
| 2 | Skill Certificate Photo | Image | No classification |
| 3 | Work Order / Agreement Letter | Image | No classification |

### Variant D — Freelancer (`workType == 'freelancer'`)

| # | Field/Upload | Type | Validation |
|---|---|---|---|
| 1 | Platform Profile Screenshot | Image | No classification |
| 2–6 | Client Invoice 1 (Required) | Image | No classification |
| 3–6 | Client Invoices 2–5 (Optional) | Image | No classification |

### Submit Logic
```dart
// isDisabled: false — ALWAYS submittable
verifiedProfileProvider.updateStep5(WorkInfo(isVerified: true));
→ push to /app/score/flow/6
```

---

## STEP 6 — Government Schemes
**File:** `step6_gov_schemes_screen.dart` (214 lines)  
**Model:** `GovSchemesInfo`  
**All optional. Skip button available. Button always enabled.**

### 7 Optional Scheme Modules

| # | Scheme | Toggle Var | ID Field (Controller) | Doc Upload DocType | Upload Flag |
|---|---|---|---|---|---|
| 1 | 🛒 PM SVANidhi | `_hasSvanidhi` | SVANidhi Application ID (`_svanidhiIdCtrl`) | `gov_svanidhi` | `_svanidhiUploaded` |
| 2 | 👷 eShram | `_hasEshram` | UAN 12-digit (`_eshramUanCtrl`, `maxLength:12`) | `gov_eshram` | `_eshramUploaded` |
| 3 | 🏦 PM-SYM | `_hasPmsym` | Pension Account Number (`_pmsymAccCtrl`) | `gov_pmsym` | `_pmsymUploaded` |
| 4 | 🛡️ PMJJBY | `_hasPmjjby` | URN (`_pmjjbyUrnCtrl`) | `gov_pmjjby` | `_pmjjbyUploaded` |
| 5 | 💰 PMMY/Mudra | `_hasMudra` | Mudra Loan Account (`_mudraAccCtrl`) | `gov_mudra` | `_mudraUploaded` |
| 6 | 📗 PPF | `_hasPpf` | PPF Account Number (`_ppfAccCtrl`) | `gov_ppf` | `_ppfUploaded` |
| 7 | 🏭 Udyam/MSME | `_hasUdyam` | Udyam Registration No (`_udyamRegCtrl`) | `gov_udyam` | `_udyamUploaded` |

**No validation on any ID field.**  
**No OCR classification** for these docTypes (no keyword rules defined in `RealOcrService`).

### Submit / Skip Logic
```dart
// Skip:
stepStatusProvider.setStatus(6, StepStatus.verified);
→ push to /app/score/flow/7

// Submit:
verifiedProfileProvider.updateStep6(GovSchemesInfo(isVerified: true));
// NOTE: No scheme data stored in model
→ push to /app/score/flow/7
```

---

## STEP 7 — Insurance
**File:** `step7_insurance_screen.dart` (200 lines)  
**Model:** `InsuranceInfo`  
**All optional. Skip button available. Button always enabled.**

### 3 Insurance Modules

| # | Module | Toggle Var | Fields | DocType | Condition |
|---|---|---|---|---|---|
| 1 | 🏥 Health | `_hasHealth` | Policy Number (`_healthPolicyCtrl`), Holder Name (`_healthHolderCtrl`), Document | `insurance_health` | Always shown |
| 2 | 🚗 Vehicle | `_hasVehicle` | Policy Number (`_vehiclePolicyCtrl`), Holder Name (`_vehicleHolderCtrl`), Document | `insurance_vehicle` | **Only if `personalInfo.vehicleOwnership == true`** |
| 3 | 🛡️ Life | `_hasLife` | Policy Number (`_lifePolicyCtrl`), Holder Name (`_lifeHolderCtrl`), Document | `insurance_life` | Always shown |

**Cross-step dependency:**
```dart
if (ref.watch(verifiedProfileProvider).personalInfo.vehicleOwnership)
  // Show vehicle insurance module
```

**No validation on policy number or holder name.**  
**No OCR classification** for insurance docTypes.

### Submit / Skip Logic
```dart
verifiedProfileProvider.updateStep7(InsuranceInfo(isVerified: true));
// NOTE: No policy data stored in model
→ push to /app/score/flow/8
```

---

## STEP 8 — Tax Records
**File:** `step8_tax_screen.dart` (202 lines)  
**Model:** `TaxInfo`  
**All optional. Skip button available. Button always enabled.**

### Module A — ITR (Toggle: `_hasItr`)

| # | Field | Controller | Type | Validation |
|---|---|---|---|---|
| 1 | PAN Number (as per ITR) | `_itrPanCtrl` | Text CAPS, maxLength:10 | None (**should match Step 2 PAN — not checked**) |
| 2 | Name as per ITR | `_itrNameCtrl` | Text | None |
| 3 | Assessment Year | `_assessmentYear` | Dropdown | `2022-23/2023-24/2024-25/2025-26` |
| 4 | Annual Income (₹) | `_itrIncomeCtrl` | Number | None |
| 5 | ITR Acknowledgement Upload | `_itrUploaded` | PDF/Image | DocType: `tax_itr` |
| 6 | Form 26AS Upload | `_form26asUploaded` | PDF/Image | DocType: `tax_26as` (optional, `isRequired: false`) |

### Module B — GST (Toggle: `_hasGst`)

| # | Field | Controller | Type | Validation |
|---|---|---|---|---|
| 1 | GSTIN | `_gstinCtrl` | Text CAPS, maxLength:15 | None (**format not validated**) |
| 2 | Legal Name as per GST | `_gstLegalNameCtrl` | Text | None |
| 3 | Annual Turnover (₹) | `_gstTurnoverCtrl` | Number | None |
| 4 | GST Document Upload | `_gstUploaded` | PDF/Image | DocType: `tax_gst` |

### Submit / Skip Logic
```dart
verifiedProfileProvider.updateStep8(TaxInfo(isVerified: true));
// NOTE: No tax data stored in model
→ push to /app/score/flow/9
```

---

## STEP 9 — EMI & Loans
**File:** `step9_emi_loans_screen.dart` (234 lines)  
**Model:** `EmiLoansInfo`  
**Button always enabled. Submits directly to ScoreGenerating.**

### Top-Level Toggle
```dart
bool _hasActiveLoans = false  // SwitchListTile
```
- **false** → Shows green "No active loans" card. Can submit immediately.
- **true** → Shows loan entry cards below.

### Loan Entry Model (`_LoanEntry` class)
Up to 5 entries. Each entry has:

| # | Field | Controller | Type | Validation |
|---|---|---|---|---|
| 1 | Lender Name | `lenderCtrl` | Text | None (hint: SBI/HDFC/Bajaj/IIFL/Other) |
| 2 | Monthly EMI Amount (₹) | `emiCtrl` | Number keyboard | None |
| 3 | Previous Debit Date | `prevDateCtrl` | Date picker (tap to open) | Range: Jan 2018 → today |
| 4 | Latest Debit Date | `latestDateCtrl` | Date picker (tap to open) | Range: Jan 2018 → today |

**Add loan:** `TextButton` appears if `_loanEntries.length < 5`  
**Remove loan:** Delete icon on each card if `_loanEntries.length > 1`  
**Date format stored:** `DD/MM/YYYY`

### Submit Logic
```dart
// Goes directly to ScoreGenerating — no API call
verifiedProfileProvider.updateStep9(EmiLoansInfo(isVerified: true));
// NOTE: EMI amounts NOT stored — EmiLoansInfo has no amount fields
stepStatusProvider.setStatus(9, StepStatus.verified);
→ push to /app/score/generating
```

---

## SUMMARY: What Data Reaches Scoring Engine

| Step | Fields Collected | Fields Stored in Model | Fields Reaching FeatureEngineer |
|---|---|---|---|
| 1 | 12 fields | All 12 in `PersonalInfo` | `workType` (for confidence), `selfDeclaredIncome` (available but not mapped) |
| 2 | Aadhaar+PAN+Selfie | `isVerified`, `backVerified`, `selfieVerified` | `aadhaar_verified → 1.0`, `pan_verified → 1.0` |
| 3 | 7 fields + PDF | `isVerified: true` only | `avg_monthly_income_norm → 0.42` (HARDCODED) |
| 4 | 6 modules × 3-4 fields + 6 uploads each | `isVerified: true` only | ❌ Nothing |
| 5 | 4–8 fields/uploads (by workType) | `isVerified: true` only | ❌ Nothing |
| 6 | 7 IDs + 7 uploads | `isVerified: true` only | ❌ Nothing |
| 7 | 3 modules × 2 fields + 1 upload | `isVerified: true` only | `health_insurance_active → 1.0` (binary only) |
| 8 | ITR: 4 fields + 2 uploads, GST: 3 fields + 1 upload | `isVerified: true` only | `itr_filed_binary → 1.0` (binary only) |
| 9 | Up to 5 loans × 4 fields each | `isVerified: true` only | ❌ Nothing (EMI amounts not stored) |

> **Root cause:** Steps 4–9 `VerifiedProfile` sub-models store only `isVerified: true`.  
> The `FeatureEngineer` has no access to utility amounts, work documents, scheme IDs,  
> insurance policies, tax PAN, or EMI values. 105 of 115 features default to `0.5`.

---

## COMPLETE FIELD COUNT

| Step | Mandatory | Optional | Doc Uploads | Total Inputs |
|---|---|---|---|---|
| Step 1 | 11 | 1 | 0 | 12 |
| Step 2 | 3 text + 4 uploads + 1 OTP×2 | 0 | 5 | 15 |
| Step 3 | 5 text + 1 PDF | 3 | 1–2 | 9–10 |
| Step 4 | 0 (all optional modules) | 6×3-4 fields | Up to 36 | 0–60 |
| Step 5 | Varies by workType (3–8) | — | 3–8 | 3–16 |
| Step 6 | 0 (all optional) | 7 IDs | 7 | 0–14 |
| Step 7 | 0 (all optional) | 2-3×2 fields | 2–3 | 0–9 |
| Step 8 | 0 (all optional) | 7 fields | 1–4 | 0–11 |
| Step 9 | 0 (toggle only) | Up to 5×4 | 0 | 1–21 |
| **TOTAL** | **~19–27** | **~60+** | **~55+** | **~65–158** |
