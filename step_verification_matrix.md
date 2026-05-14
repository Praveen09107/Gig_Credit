# 📋 GigCredit — Step-by-Step Input & Verification Matrix
**Source:** Direct code inspection of all 9 step screens  
**Date:** 2026-05-02

---

## Step 1 — Personal Info (`step1_personal_screen.dart`)

| # | Input Field | Type | Required | Current Validation | Current Verification | Missing |
|---|---|---|---|---|---|---|
| 1 | Full Name | Text | ✅ | ✅ Regex `[a-zA-Z\s]+`, length 2-50 | ❌ None | Cross-check with OCR names |
| 2 | Date of Birth | Text | ✅ | ⚠️ DD/MM/YYYY split check only | ❌ None | Age calculation, age range 18-65 |
| 3 | Mobile Number | Text | ✅ | ✅ 10 digits, starts with 6-9 | ❌ None | Should match registration phone |
| 4 | Current Address | Text | ✅ | ✅ Min 10, max 200 chars | ❌ None | Cross-check with Aadhaar back address |
| 5 | Permanent Address | Text | Conditional | ✅ Min 10 chars (if different) | ❌ None | — |
| 6 | State of Residence | Dropdown | ✅ | ✅ Non-null selection | ❌ None | — |
| 7 | Primary Work Type | Dropdown | ✅ | ✅ Non-null selection | ❌ None | Determines Step 5 variant |
| 8 | Monthly Income (₹) | Number | ✅ | ✅ Range ₹1,000 - ₹5,00,000 | ❌ None | Cross-check with bank statement avg |
| 9 | Years in Profession | Stepper | ✅ | ✅ Range 0-40 | ❌ None | — |
| 10 | Dependents | Stepper | ✅ | ✅ Range 0-10 | ❌ None | — |
| 11 | Vehicle Ownership | Toggle | ✅ | ✅ Boolean | ❌ None | Activates vehicle insurance in Step 7 ✅ |
| 12 | Secondary Income | Number | ❌ | ❌ No validation | ❌ None | Should have range validation |

**Mock Data Fill:** ✅ Yes (double-tap on name field)  
**Cross-Step Links:** Work Type → Step 5 variant, Vehicle Ownership → Step 7 vehicle insurance  
**Profile Storage:** `PersonalInfo` model via `verifiedProfileProvider.updateStep1()`  

---

## Step 2 — KYC Verification (`step2_kyc_screen.dart`)

| # | Input / Upload | Type | Required | Current Validation | Current Verification | Missing |
|---|---|---|---|---|---|---|
| 1 | Aadhaar Number | Text (12 digits) | ✅ | ✅ Length = 12 | ✅ API call to Render backend → OTP flow | Luhn checksum for Aadhaar |
| 2 | Aadhaar OTP | Text (6 digits) | ✅ | ✅ Exact match against expected | ✅ Simulated UIDAI OTP | — |
| 3 | Aadhaar Front Photo | Image upload | ✅ | — | ✅ PaddleOCR extracts Aadhaar number | Name extraction from Aadhaar |
| 4 | Aadhaar Back Photo | Image upload | ❌ | — | ⚠️ OCR runs but nothing extracted | Address extraction from Aadhaar back |
| 5 | PAN Number | Text (10 chars) | ✅ | ✅ Length = 10 | ✅ API call to Render backend → OTP flow | PAN format regex check |
| 6 | PAN OTP | Text (6 digits) | ✅ | ✅ Exact match against expected | ✅ Simulated NSDL OTP | — |
| 7 | PAN Card Photo | Image upload | ✅ | — | ✅ PaddleOCR extracts PAN number | Name extraction from PAN |
| 8 | Live Selfie | Camera capture | ✅ | — | ❌ **FAKE**: `Random() > 0.1` | Real face comparison needed |

**Cross-Step Validation:** `_runCrossValidation()` is called but `CrossStepValidator.validate()` returns `[]`  
**Mock Data Fill:** ❌ No (but OTP is printed to console for demo)  
**Completion Gate:** ALL of `_aadhaarVerified && _aadhaarFrontExtracted && _panVerified && _panExtracted && _selfieVerified` required  
**Profile Storage:** `KycInfo` model (stores `isVerified`, `backVerified`, `selfieVerified`)  

---

## Step 3 — Bank Information (`step3_bank_screen.dart`)

| # | Input / Upload | Type | Required | Current Validation | Current Verification | Missing |
|---|---|---|---|---|---|---|
| 1 | Bank Name | Text | ✅ | ✅ Non-empty | ⚠️ Auto-filled from IFSC API | — |
| 2 | Account Holder Name | Text | ✅ | ✅ Non-empty | ⚠️ Auto-filled from Account API | Cross-check with Step 1 name |
| 3 | Branch Name | Text | ✅ | ✅ Non-empty | ⚠️ Auto-filled from IFSC API | — |
| 4 | IFSC Code | Text (11 chars) | ✅ | ✅ Length = 11 | ✅ API verification (`verifyIfsc`) | — |
| 5 | Account Number | Text (≤18 digits) | ✅ | ✅ Non-empty + IFSC verified first | ✅ API verification (`verifyAccount`) | — |
| 6 | MICR Code | Text | ❌ | ❌ None | ❌ None | — |
| 7 | UPI Details | Text | ❌ | ❌ None | ❌ None | — |
| 8 | Bank Statement PDF | File upload | ✅ | ⚠️ Account match **bypassed** | ⚠️ PDF text extracted but match skipped | Account number match should be enforced |
| 9 | Secondary Bank | Toggle + fields | ❌ | Same as above (no IFSC/acc verify) | ❌ No API verification for secondary | — |

**Mock Data Fill:** ✅ Yes (double-tap on bank name)  
**Completion Gate:** `_ifscVerified && _accVerified` required  
**Key Issue:** Bank statement OCR checks `rawText.contains(expectedAcc)` but is **commented out** for demo  

---

## Step 4 — Utility Bills (`step4_utility_screen.dart`)

| # | Module | Fields | Current Validation | Current Verification | Missing |
|---|---|---|---|---|---|
| 1 | ⚡ Electricity | Consumer No, Name, Amount + up to 6 bill uploads | ❌ None | ⚠️ Keyword classification only | Consumer number format, amount range, name vs Step 1 |
| 2 | 📶 WiFi/Broadband | Account No, Name, Amount + up to 6 bill uploads | ❌ None | ⚠️ Keyword classification only | Same as above |
| 3 | 🔥 Gas/LPG | BP Number, Name, Amount + up to 6 bill uploads | ❌ None | ⚠️ Keyword classification only | Same as above |
| 4 | 📱 Mobile | Mobile No, Account No, Name, Amount + up to 6 uploads | ❌ None | ⚠️ Keyword classification only | Mobile number vs Step 1 mobile |
| 5 | 🌐 Internet | Account No, Name, Amount + up to 6 uploads | ❌ None | ⚠️ Keyword classification only | Same as above |
| 6 | 🏠 Rent | Tenant, Landlord, Address, Amount + up to 6 uploads | ❌ None | ⚠️ Keyword classification only | Tenant name vs Step 1 name, address vs Step 1 |

**Mock Data Fill:** ❌ No  
**All modules are optional.** Step can be submitted with zero modules toggled.  
**Key Issue:** `isDisabled: false` — button always enabled regardless of module completion  

---

## Step 5 — Work Proof (`step5_work_screen.dart`)

**Dynamic based on Step 1 work type selection:**

### Platform Worker
| # | Input / Upload | Required | Validation | Verification |
|---|---|---|---|---|
| 1 | Vehicle Registration Number | ✅ | ❌ None | ❌ None |
| 2 | RC Book Photo | ✅ | — | ⚠️ Keyword: REGISTRATION, VEHICLE, CHASSIS |
| 3 | DL Front Photo | ✅ | — | ⚠️ Keyword: DRIVING, LICENCE |
| 4 | DL Back Photo | ✅ | — | ⚠️ Keyword: DRIVING, LICENCE |
| 5 | Vehicle Insurance | ✅ | — | ❌ No classification |
| 6 | 3× Earnings Screenshots | ✅ | — | ❌ No classification |

### Vendor
| # | Input / Upload | Required | Validation | Verification |
|---|---|---|---|---|
| 1 | SVANidhi Application ID | ✅ | ❌ None | ❌ None |
| 2 | SVANidhi Approval Letter | ✅ | — | ❌ No classification |
| 3 | Municipal Trade Licence | ✅ | — | ❌ No classification |

### Tradesperson
| # | Input / Upload | Required | Validation | Verification |
|---|---|---|---|---|
| 1 | Skill Certificate ID | ✅ | ❌ None | ❌ None |
| 2 | NSDC Certificate Photo | ✅ | — | ❌ No classification |
| 3 | Work Order Letter | ✅ | — | ❌ No classification |

### Freelancer
| # | Input / Upload | Required | Validation | Verification |
|---|---|---|---|---|
| 1 | Platform Profile Screenshot | ✅ | — | ❌ No classification |
| 2 | Up to 5 Client Invoices | 1 req | — | ❌ No classification |

**Mock Data Fill:** ✅ Yes (double-tap on invisible 10px area)  
**Key Issue:** `isDisabled: false` — **always submittable regardless of uploads**. No validation at all.  

---

## Step 6 — Government Schemes (`step6_gov_schemes_screen.dart`)

| # | Scheme | ID Field | Doc Upload | Validation | Verification |
|---|---|---|---|---|---|
| 1 | PM SVANidhi | Application ID | Approval Letter | ❌ None | ❌ None |
| 2 | eShram | UAN (12-digit) | eShram Card | ❌ No digit validation | ❌ None |
| 3 | PM-SYM Pension | Pension Account | Pension Card | ❌ None | ❌ None |
| 4 | PMJJBY | URN | Certificate | ❌ None | ❌ None |
| 5 | PMMY/Mudra | Loan Account | Sanction Letter | ❌ None | ❌ None |
| 6 | PPF | Account Number | Passbook | ❌ None | ❌ None |
| 7 | Udyam/MSME | Registration No | Certificate | ❌ None | ❌ None |

**All optional.** Skip button exists. `isDisabled: false`.  
**Mock Data Fill:** ❌ No  
**Key Issue:** No ID format validation for any scheme (UAN is 12 digits, Udyam is `UDYAM-XX-00-0000000`)  
**Profile Storage:** `GovSchemesInfo(isVerified: true)` — **stores no actual data**, just a boolean  

---

## Step 7 — Insurance (`step7_insurance_screen.dart`)

| # | Insurance Type | Fields | Validation | Verification |
|---|---|---|---|---|
| 1 | 🏥 Health | Policy Number + Holder Name + Document | ❌ None | ❌ None |
| 2 | 🚗 Vehicle (conditional) | Policy Number + Holder Name + Document | ❌ None | ❌ None |
| 3 | 🛡️ Life | Policy Number + Holder Name + Document | ❌ None | ❌ None |

**Vehicle insurance only shown if `personalInfo.vehicleOwnership == true`** ✅ (correct cross-step behavior)  
**All optional.** Skip button exists.  
**Mock Data Fill:** ❌ No  
**Key Issue:** Holder Name never compared to Step 1 name. Policy number format never validated.  
**Profile Storage:** `InsuranceInfo(isVerified: true)` — **stores no actual data**  

---

## Step 8 — Tax Records (`step8_tax_screen.dart`)

| # | Module | Fields | Validation | Verification | Missing |
|---|---|---|---|---|---|
| 1 | ITR | PAN, Name, Assessment Year, Annual Income + ITR-V Upload + Form 26AS | ❌ None | ❌ None | **PAN should match Step 2 PAN** |
| 2 | GST | GSTIN (15-char), Legal Name, Turnover + GST Doc | ❌ None | ❌ None | GSTIN format: `[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}` |

**All optional.** Skip button exists.  
**Mock Data Fill:** ❌ No  
**Key Issue:** PAN entered in Step 8 is a **separate field** from Step 2 PAN — never compared  
**Profile Storage:** `TaxInfo(isVerified: true)` — **stores no actual data**  

---

## Step 9 — EMI & Loans (`step9_emi_loans_screen.dart`)

| # | Field | Per Loan | Required | Validation | Verification |
|---|---|---|---|---|---|
| 1 | Has Active Loans? | Toggle | ✅ | ✅ Boolean | — |
| 2 | Lender Name | Text | ✅ | ❌ None | ❌ None |
| 3 | Monthly EMI Amount | Number | ✅ | ❌ None | ❌ None |
| 4 | Previous Debit Date | Date picker | ✅ | ✅ Date picker bounds (2018-now) | ❌ None |
| 5 | Latest Debit Date | Date picker | ✅ | ✅ Date picker bounds (2018-now) | ❌ None |

**Up to 5 loan entries.** "No active loans" path shows positive feedback.  
**Mock Data Fill:** ❌ No  
**Key Issue:** EMI amount has no range validation. Could enter ₹0 or ₹999,999,999.  
**Missing:** Latest date should be ≥ Previous date. EMI amount should be reasonable (₹100 - ₹500,000).  
**Profile Storage:** `EmiLoansInfo(isVerified: true)` — **stores no EMI data for scoring**  

---

## Summary: Data Flow to Scoring Engine

| Step | Data Actually Reaches Scoring? | How? |
|---|---|---|
| Step 1 | ⚠️ Partial | `personalInfo.workType` used for confidence. `selfDeclaredIncome` available but not mapped |
| Step 2 | ⚠️ Binary only | `kycInfo.isVerified` → `aadhaar_verified = 1.0` and `pan_verified = 1.0` |
| Step 3 | ⚠️ Binary only | `bankInfo.isVerified` → `avg_monthly_income_norm = 0.42` (HARDCODED!) |
| Step 4 | ❌ No | `utilityInfo.isVerified` → used nowhere in feature extraction |
| Step 5 | ❌ No | `workInfo.isVerified` → used nowhere in feature extraction |
| Step 6 | ❌ No | `govSchemesInfo.isVerified` → used nowhere in feature extraction |
| Step 7 | ⚠️ Binary only | `insuranceInfo.isVerified` → `health_insurance_active = 1.0` |
| Step 8 | ⚠️ Binary only | `taxInfo.isVerified` → `itr_filed_binary = 1.0` |
| Step 9 | ❌ No | EMI amounts **not stored** in `EmiLoansInfo`. Not available to feature engineer |

> [!IMPORTANT]
> **The fundamental problem:** Steps 4-9 data models store only `isVerified: true`. They don't store the actual field values (policy numbers, EMI amounts, scheme IDs). So the feature engineer has no way to compute meaningful features from these steps. The `VerifiedProfile` effectively loses all user input after Steps 1-3.
