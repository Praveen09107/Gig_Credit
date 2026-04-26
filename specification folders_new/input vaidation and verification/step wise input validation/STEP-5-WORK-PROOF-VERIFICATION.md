# GigCredit — Step-5: Work Proof Verification
## Validation & Verification Specification | Version 1.0

---

## Purpose

Verify the user's occupation, work history, and work-specific income sources. This step fully reconfigures itself based on the Work Type selected in Step-1. Each of the 4 layouts has different APIs, documents, OCR fields, and validation logic. Verified work data populates the P1 (Income Stability) and P5 (Work Identity) pillars of the credit scoring engine.

**Step-5 is OPTIONAL at the step level.** The user may skip Step-5 entirely and proceed to Step-6. However, if any input is provided in this step, it must pass all validation and verification checks. Invalid partial inputs are rejected and not stored in the global profile.

---

## Section 0 — Layout Routing (From Step-1)

The layout rendered in Step-5 is determined exclusively by `verified_profile.work_type` set during Step-1.

| Step-1 Work Type | Step-5 Layout |
|---|---|
| Platform Worker | Layout 5A |
| Vendor / Seller | Layout 5B |
| Skilled Tradesperson | Layout 5C |
| Freelancer | Layout 5D |

Only one layout is shown. The other three are never rendered.

---

## Section 1 — Key Rules (Apply to All 4 Layouts)

```
RULE 1 — Step-5 is fully optional.
  User may skip with zero inputs → Step-5 Status = SKIPPED
  verified_profile.work = null
  Step-6 unlocked regardless.

RULE 2 — Partial inputs must still pass.
  If ANY input is provided:
    → It must pass individual + cross-internal + global checks
    → Failing inputs are rejected and flagged
    → User is shown errors for each failing field

RULE 3 — Vehicle owner name mismatch is non-blocking.
  RC owner name may differ from Step-1 identity.
  (Drivers frequently use family-owned vehicles.)
  If mismatch → vehicle_owner_mismatch = true (soft flag, logged)
  Does NOT block step completion.

RULE 4 — Platform payout vs bank credit tolerance.
  Platform earnings visible in screenshots must approximately
  match bank credits in Step-3 canonical CSV.
  Tolerance: ±30% (accounts for platform fees, deductions, splits)
  Date tolerance: ±7 days

RULE 5 — Skip tracking.
  step5_skipped = true is stored in global state.
  Scoring engine applies a lower P1/P5 score weight
  when work proof is not provided.
```

---

## Section 2 — UI Gate Rules (All Layouts)

```
GATE 1 — Document uploads LOCKED until:
  Layout 5A: Vehicle number format valid
             + POST /api/gov/vehicle-rc-check → Active
             + POST /api/gov/vehicle-insurance-check → Active
  Layout 5B: SVANidhi Application ID format valid
             + POST /api/gov/svanidhi-verify → Disbursed
  Layout 5C: Skill Certificate ID format valid
             + POST /api/gov/skill-verify → Valid
  Layout 5D: No API gate — all upload slots available immediately

GATE 2 — Continue / Submit Button ENABLED only when:
  Case A (Skip): User has provided zero inputs → button enabled immediately
  Case B (Work submitted): All mandatory fields for that layout pass
    individual validation + cross-internal + global validation

GATE 3 — Optional fields NEVER block Continue.
  Only mandatory fields gate the Continue button.
  Optional uploads are processed if provided but
  their failure only affects ML scoring, not step completion.
```

---

## Section 3 — Layout 5A: Platform Worker

Rendered when `verified_profile.work_type = "platform_worker"`.

Accepted platforms: Swiggy, Zomato, Ola, Uber, Dunzo, Porter, Blinkit, Rapido

---

### 3.1 Inputs — Layout 5A

| # | Field | Type | Mandatory |
|---|---|---|---|
| 1 | Vehicle Registration Number | Text input | Required |
| 2 | RC Book Front Page | JPG / PNG | Required |
| 3 | Driving Licence Front Side | JPG / PNG | Required |
| 4 | Driving Licence Back Side | JPG / PNG | Required |
| 5 | Vehicle Insurance Certificate | JPG / PNG / PDF | Required |
| 6 | Platform Earning Screenshot — Most Recent Month | Screenshot JPG/PNG | Required |
| 7 | Platform Earning Screenshot — 2 Months Ago | Screenshot JPG/PNG | Required |
| 8 | Platform Earning Screenshot — 3 Months Ago | Screenshot JPG/PNG | Required |
| 9 | Second Platform App Screenshot (if on 2 apps) | Screenshot JPG/PNG | Optional |
| 10 | Third Platform App Screenshot (if on 3 apps) | Screenshot JPG/PNG | Optional |

---

### 3.2 API 1 — RC Verification

- **Method:** `POST`
- **Endpoint:** `/api/gov/vehicle-rc-check`
- **MongoDB:** `vehicle_rc_db`
- **Trigger:** User enters vehicle registration number → taps "Verify RC" (Gate 1, part 1)

**Request Body:**
```json
{
  "vehicle_number": "TN09AB1234"
}
```

**Backend Logic:**
- Lookup vehicle number in `vehicle_rc_db`
- If not found → return 404
- If found → return owner name, status, vehicle type, validity

**Response (Success):**
```json
{
  "vehicle_found" : true,
  "owner_name"    : "G LATA",
  "rc_status"     : "Active",
  "vehicle_type"  : "Motorcycle",
  "valid_till"    : "2028-07-02"
}
```

**On-Device Action on Success:**
- Store `rc_owner_name`, `vehicle_number`, `vehicle_type`, `rc_valid_till`
- Set `rc_api_verified = true`
- Proceed to API 2 automatically

**Error Responses:**
- `404` → "Vehicle registration number not found."
- `400` → "RC is expired or cancelled."

---

### 3.3 API 2 — Vehicle Insurance Verification

- **Method:** `POST`
- **Endpoint:** `/api/gov/vehicle-insurance-check`
- **MongoDB:** `vehicle_insurance_db`
- **Trigger:** Runs automatically after API 1 succeeds (same vehicle number)

**Request Body:**
```json
{
  "vehicle_number": "TN09AB1234"
}
```

**Response (Success):**
```json
{
  "insurance_found"   : true,
  "policy_number"     : "SJ413354",
  "insurance_company" : "Bharti AXA",
  "insurance_status"  : "Active",
  "expiry"            : "2026-07-31"
}
```

**On-Device Action on Success:**
- Store `policy_number`, `insurance_company`, `insurance_expiry`
- Set `insurance_api_verified = true`
- **UNLOCK Gate 1:** All document upload slots enabled

**Error Responses:**
- `404` → "No active insurance found for this vehicle."
- `400` → "Insurance policy is expired."

---

### 3.4 OCR Extracts — Layout 5A

**From RC Book Front Page:**

| Field | Example | Used For |
|---|---|---|
| Registration Number | TN09AB1234 | Cross-check vs API vehicle number |
| Owner Name | G LATA | API cross-check, mismatch flag |
| Registration Date | 07-07-2023 | Tenure calculation |
| Registration Validity | 07-07-2038 | Active status check |
| Vehicle Class | Motorcycle / MCWG | DL class match |
| Chassis Number | MD2DHEAZZREM58012 | Fraud detection |
| Engine Number | HREE4M40123 | Fraud detection |

**From Driving Licence Front:**

| Field | Example | Used For |
|---|---|---|
| Licence Number | TN0120120012345 | DL format check |
| Name | RAVI KUMAR | Step-2 Aadhaar name match |
| Date of Birth | 12-06-1997 | Step-2 DOB match |
| Photo | Face image | (not used for matching at this stage) |

**From Driving Licence Back:**

| Field | Example | Used For |
|---|---|---|
| Vehicle Classes Authorised | MCWG, LMV | RC vehicle class cross-check |
| Validity Date (Non-Transport) | 11-05-2026 | Active licence check |

**From Vehicle Insurance Certificate:**

| Field | Example | Used For |
|---|---|---|
| Policy Number | SJ413354 | API cross-check |
| Vehicle Number | TN09AB1234 | RC vehicle number cross-check |
| Owner Name | G LATA | Consistency with RC |
| Insurance Company | Bharti AXA | API cross-check |
| Policy Start Date | 01-08-2025 | Coverage period check |
| Policy Expiry Date | 31-07-2026 | Active status check |

**From Platform Earning Screenshot (per screenshot):**

| Field | Example | Used For |
|---|---|---|
| Platform Name | Swiggy | Provider identity |
| Monthly Earnings Total (₹) | ₹18,450 | Bank credit cross-match |
| Number of Trips / Deliveries | 142 | Work activity metric |
| Platform Rating | 4.3 / 5.0 | P5 ML feature |
| Account Holder Name | Ravi Kumar | Step-1 name match |
| Member Since Date | Jun 2023 | Tenure calculation |
| Platform Badge / Level | Gold Partner | P5 ML feature |

---

### 3.5 Individual Validation — Layout 5A

| Check | Rule | Blocking |
|---|---|---|
| RC vehicle number (OCR) vs API | Must match exactly | HARD FAIL |
| RC status | Must be "Active" | HARD FAIL |
| Insurance vehicle number (OCR) vs RC vehicle number | Must match exactly | HARD FAIL |
| Insurance policy number (OCR) vs API | Must match | HARD FAIL |
| Insurance status | Must be "Active" | HARD FAIL |
| DL vehicle class (OCR) vs RC vehicle class (OCR) | Must be compatible | HARD FAIL |
| DL name (OCR) vs Aadhaar name (Step-2) | Fuzzy match ≥ 85% | HARD FAIL |
| DL DOB (OCR) vs Step-2 DOB | Must match | HARD FAIL |
| RC owner name (OCR) vs Aadhaar name (Step-2) | Fuzzy ≥ 85% → PASS; else `vehicle_owner_mismatch = true` | Soft flag only |
| Platform account name (OCR) vs Step-1 name | Fuzzy ≥ 85% | HARD FAIL |
| Platform screenshot monthly earnings vs bank credit (same month) | Within ±30% tolerance | Soft flag |

**Error Messages:**
- "Vehicle number on RC does not match your entered registration number."
- "Driving licence name does not match your verified Aadhaar name."
- "Insurance policy is expired or inactive."
- "Platform account name does not match your registered name."

**Soft Flag Messages (non-blocking, shown as warnings):**
- "RC is registered to a different person. This is recorded but will not block your application."
- "Platform earnings could not be matched to your bank credits. This may affect your credit score."

---

### 3.6 Cross-Internal Validation — Layout 5A

| Check | Rule | Blocking |
|---|---|---|
| Vehicle number consistency | Identical across RC, Insurance Certificate, and all payout screenshots (if visible) | HARD FAIL |
| All 3 screenshots from same platform account | Account name must be consistent | HARD FAIL |
| Bank account in payout screenshot vs Step-3 | If visible, must match `verified_profile.bank.primary.account_number` | HARD FAIL |
| Insurance owner name vs RC owner name | Fuzzy ≥ 85% | HARD FAIL |

---

### 3.7 Global Validation — Layout 5A

| Check | Rule | Blocking |
|---|---|---|
| Platform payout credit in bank CSV | Screenshot earnings matched in Step-3 canonical CSV ±30%, ±7 days | Soft flag |
| DL name vs Step-2 Aadhaar name | Confirmed here at global level | HARD FAIL |

- Match found → `platform_income_verified = true`
- No match → `platform_income_verified = false` (soft flag, reduces P1 score)

---

## Section 4 — Layout 5B: Vendor / Seller

Rendered when `verified_profile.work_type = "vendor_seller"`.

---

### 4.1 Inputs — Layout 5B

| # | Field | Type | Mandatory |
|---|---|---|---|
| 1 | PM SVANidhi Application ID | Text input | Required |
| 2 | SVANidhi Approval Letter | JPG / PNG / PDF | Required |
| 3 | Municipal Trade Licence | JPG / PNG / PDF | Required |
| 4 | Bank No-Due Certificate | JPG / PNG / PDF | Optional |
| 5 | Vendor Association Membership | JPG / PNG | Optional |
| 6 | Market Allotment Letter | JPG / PNG / PDF | Optional |
| 7 | GST Registration Certificate | PDF | Optional |

---

### 4.2 API — SVANidhi Verification

- **Method:** `POST`
- **Endpoint:** `/api/gov/svanidhi-verify`
- **MongoDB:** `svanidhi_db`
- **Trigger:** User enters SVANidhi Application ID → taps "Verify SVANidhi ID" (Gate 1)

**Request Body:**
```json
{
  "application_id": "SVN12345678"
}
```

**Response (Success):**
```json
{
  "application_id"    : "SVN12345678",
  "loan_status"       : "Disbursed",
  "loan_amount"       : 10000,
  "bank"              : "State Bank of India",
  "beneficiary_name"  : "Ravi Kumar",
  "next_loan_eligible": 20000
}
```

**On-Device Action on Success:**
- Store `svanidhi_beneficiary_name`, `loan_amount`, `loan_status`, `next_loan_eligible`
- Set `svanidhi_api_verified = true`
- **UNLOCK Gate 1:** All document upload slots enabled

**Error Responses:**
- `404` → "SVANidhi Application ID not found."
- `400` → "Application is pending or rejected."

---

### 4.3 OCR Extracts — Layout 5B

**From SVANidhi Approval Letter:**

| Field | Example | Used For |
|---|---|---|
| Application ID | SVN12345678 | API cross-check |
| Approval Date | 15-03-2024 | Vendor tenure calculation |
| Loan Amount Sanctioned | ₹10,000 | Bank credit cross-match |
| Beneficiary Name | Ravi Kumar | API + Aadhaar match |
| Issuing Bank / MFI Name | State Bank of India | Bank consistency |

**From Municipal Trade Licence:**

| Field | Example | Used For |
|---|---|---|
| Licence Number | TN/CHN/TL/2024/04521 | Uniqueness check |
| Validity Date | 31-03-2026 | Active licence check |
| Business Type | Street Vendor — Fruits | Occupation confirmation |
| Issuing Municipality | Greater Chennai Corporation | Address jurisdiction check |
| Registered Business Address | Anna Nagar, Chennai | Step-1 address cross-match |
| Licence Holder Name | Ravi Kumar | Aadhaar name match |

**From Bank No-Due Certificate (Optional):**

| Field | Example | Used For |
|---|---|---|
| Loan Agreement Number | LN2024031500456 | Cross-check with SVANidhi letter |
| Borrower Name | Ravi Kumar | Identity consistency |
| Certificate Date | 01-04-2025 | Recency check |
| Issuing Bank | State Bank of India | Consistency check |
| Loan Status | Closed / Active | Repayment behaviour signal |

**From Vendor Association Membership (Optional):**

| Field | Used For |
|---|---|
| Member Name | Identity soft-check |
| Association Name | Vendor network confirmation |
| Membership Valid Until | Active membership check |

---

### 4.4 Individual Validation — Layout 5B

| Check | Rule | Blocking |
|---|---|---|
| Application ID (OCR) vs API | Must match | HARD FAIL |
| Beneficiary name (OCR) vs API | Fuzzy ≥ 85% | HARD FAIL |
| Beneficiary name (OCR) vs Aadhaar name (Step-2) | Fuzzy ≥ 85% | HARD FAIL |
| Trade Licence holder name vs Aadhaar name | Fuzzy ≥ 85% | HARD FAIL |
| Trade Licence validity | Must not be expired | Soft flag |

**Error Messages:**
- "SVANidhi Application ID on document does not match entered ID."
- "Beneficiary name does not match your verified Aadhaar name."
- "Trade licence holder name does not match your identity."

---

### 4.5 Cross-Internal Validation — Layout 5B

| Check | Rule | Blocking |
|---|---|---|
| Beneficiary name consistency | SVANidhi letter vs Trade Licence | HARD FAIL |
| Application ID consistency | Across all SVANidhi document sections | HARD FAIL |
| No-Due Cert loan number vs Approval Letter | Must match (if No-Due uploaded) | HARD FAIL |

---

### 4.6 Global Validation — Layout 5B

| Check | Rule | Blocking |
|---|---|---|
| SVANidhi loan disbursement in bank credits | ±30% of loan amount, date of disbursement ±7 days | Soft flag |
| Monthly SVANidhi repayment debits in bank CSV | Repayment transactions tagged or keyword-matched | Soft flag |
| Trade Licence address vs Step-1 address | Partial match at city level | Soft flag |

---

## Section 5 — Layout 5C: Skilled Tradesperson

Rendered when `verified_profile.work_type = "skilled_tradesperson"`.

---

### 5.1 Inputs — Layout 5C

| # | Field | Type | Mandatory |
|---|---|---|---|
| 1 | Skill Certificate ID | Text input | Required |
| 2 | NSDC / NSQF Skill Certificate | JPG / PNG / PDF | Required |
| 3 | Work Order Letter | JPG / PNG / PDF | Required |
| 4 | Experience Certificate from Employer | JPG / PNG / PDF | Optional |
| 5–7 | Additional NSDC Skill Certificates (up to 3) | JPG / PNG / PDF | Optional |
| 8 | GST Registration Certificate | PDF | Optional |

---

### 5.2 API — Skill Certificate Verification

- **Method:** `POST`
- **Endpoint:** `/api/gov/skill-verify`
- **MongoDB:** `skill_certificate_db`
- **Trigger:** User enters Certificate ID → taps "Verify Certificate" (Gate 1)

**Request Body:**
```json
{
  "certificate_id": "NSDC-2023-457892"
}
```

**Response (Success):**
```json
{
  "candidate_name"     : "Ravi Kumar",
  "job_role"           : "Electrician",
  "nsqf_level"         : "Level 4",
  "training_institute" : "Don Bosco Tech",
  "certificate_status" : "Valid"
}
```

**On-Device Action on Success:**
- Store `candidate_name`, `job_role`, `nsqf_level`, `training_institute`
- Set `skill_api_verified = true`
- **UNLOCK Gate 1:** All document upload slots enabled

**Error Responses:**
- `404` → "Skill Certificate ID not found in NSDC database."
- `400` → "Certificate has been cancelled or is invalid."

---

### 5.3 OCR Extracts — Layout 5C

**From NSDC / NSQF Skill Certificate:**

| Field | Example | Used For |
|---|---|---|
| Candidate Name | RAVI KUMAR | API + Aadhaar match |
| Certificate ID | NSDC-2023-457892 | API cross-check |
| Job Role | Electrician | Occupation confirmation |
| NSQF Level | Level 4 | API cross-check, ML feature |
| Training Institute | Don Bosco Tech | API cross-check |
| Duration | 6 months | Training depth signal |
| Grade | A | Performance signal |
| Enrollment Number | DB/CHN/2023/1234 | Uniqueness check |
| Course Period | Jan 2023 – Jun 2023 | Tenure calculation |
| Date of Issue | 15-07-2023 | Certificate recency |
| Issuing Body | NSDC / Sector Skill Council | Accreditation check |

**From Work Order Letter:**

| Field | Example | Used For |
|---|---|---|
| Client / Contractor Name | Chennai Metro Rail Ltd | Work proof identity |
| Type of Work Performed | Electrical wiring installation | Occupation match |
| Work Value (₹) | ₹45,000 | Bank credit cross-match |
| Completion Date | 30-11-2025 | Bank credit date match |
| Authorised Signature | Present | Document authenticity |

---

### 5.4 Individual Validation — Layout 5C

| Check | Rule | Blocking |
|---|---|---|
| Certificate ID (OCR) vs API | Must match | HARD FAIL |
| Candidate name (OCR) vs API | Fuzzy ≥ 85% | HARD FAIL |
| Candidate name (OCR) vs Aadhaar name (Step-2) | Fuzzy ≥ 85% | HARD FAIL |
| NSQF Level (OCR) vs API | Must match | HARD FAIL |
| Certificate status | Must be "Valid" | HARD FAIL |

**Error Messages:**
- "Certificate ID does not match your entered ID."
- "Candidate name on certificate does not match your Aadhaar name."
- "Skill certificate is cancelled or invalid."

---

### 5.5 Cross-Internal Validation — Layout 5C

| Check | Rule | Blocking |
|---|---|---|
| Certificate ID consistency | Consistent across all certificate sections | HARD FAIL |
| Multiple certificates — unique IDs | Each additional NSDC certificate must have a different Certificate ID | HARD FAIL |
| Job role consistency | If multiple certificates uploaded, job roles should be related (not contradictory) | Soft flag |

---

### 5.6 Global Validation — Layout 5C

| Check | Rule | Blocking |
|---|---|---|
| Work order payment in bank credits | Work value ±30%, completion date ±7 days in Step-3 canonical CSV | Soft flag |
| Candidate name vs Step-2 Aadhaar name | Confirmed at global level | HARD FAIL |
| Training institute jurisdiction vs Step-1 address | State-level plausibility check | Soft flag |

---

## Section 6 — Layout 5D: Freelancer

Rendered when `verified_profile.work_type = "freelancer"`.

Accepted platforms: Upwork, Fiverr, Toptal, Freelancer.com, PeoplePerHour, Contra

No server-side API. Validated entirely via OCR + Step-2 global identity + bank transaction match.

---

### 6.1 Inputs — Layout 5D

| # | Field | Type | Mandatory |
|---|---|---|---|
| 1 | Freelance Platform Profile Screenshot — Primary | Screenshot JPG/PNG | Required |
| 2 | Second Platform Profile Screenshot (optional 2nd app) | Screenshot JPG/PNG | Optional |
| 3 | Client Invoice Sample 1 | JPG / PNG / PDF | Required (min 1) |
| 4–7 | Client Invoice Samples 2–5 | JPG / PNG / PDF | Optional |
| 8 | Portfolio / Project Completion Proof | JPG / PNG / PDF | Optional |
| 9 | GST Registration Certificate | PDF | Optional |

---

### 6.2 OCR Extracts — Layout 5D

**From Platform Profile Screenshot:**

| Field | Example | Used For |
|---|---|---|
| Account Holder Name | Ravi Kumar | Step-1 name match |
| Platform Rating | 4.8 / 5.0 | P5 ML feature |
| Total Lifetime Earnings (₹) | $12,450 | Earnings scale reference |
| Member Since Date | March 2022 | Tenure calculation |
| Badge / Level | Top Rated | P5 ML feature |

**From Client Invoice:**

| Field | Example | Used For |
|---|---|---|
| Client Name | TechFlow Pvt Ltd | Client verification |
| Service Description | UI/UX Design | Occupation match |
| Invoice Amount (₹ or $) | ₹35,000 | Bank credit cross-match |
| Invoice Date | 05-11-2025 | Bank credit date match |
| Payment Due Date | 15-11-2025 | Payment timing check |
| Payment Status | Paid | Completed work proof |
| GST Number (if applicable) | 33AAAAA0000A1Z5 | Optional identity anchor |

---

### 6.3 Individual Validation — Layout 5D

| Check | Rule | Blocking |
|---|---|---|
| Platform account name (OCR) vs Step-1 name | Fuzzy ≥ 85% | HARD FAIL |
| Invoice amount | Must be > 0 | HARD FAIL |
| Invoice date | Must be a valid date | HARD FAIL |
| Payment status | Must be "Paid" or equivalent | Soft flag |
| All screenshots from same account | Account name consistent across all screenshots | HARD FAIL |

**Error Messages:**
- "Platform account name does not match your registered name."
- "Invoice amount is invalid."

---

### 6.4 Cross-Internal Validation — Layout 5D

| Check | Rule | Blocking |
|---|---|---|
| Same platform account across all screenshots | Account name consistent | HARD FAIL |
| Invoice dates not all identical | If all invoices share exact same date → fraud flag | HARD FAIL |
| Platform account name across all invoices | Consistent service provider name | HARD FAIL |

**Error Messages:**
- "All invoices appear to have the same date. Please upload genuine client invoices."

---

### 6.5 Global Validation — Layout 5D

| Check | Rule | Blocking |
|---|---|---|
| Invoice payments in bank credits | Invoice amount ±30%, invoice date ±7 days in Step-3 canonical CSV | Soft flag |
| Platform account name vs Step-1 name | Confirmed at global level | HARD FAIL |
| Foreign currency conversion (if applicable) | Invoice in USD/GBP converted at approximate rate for bank match | Soft flag |

---

## Section 7 — Global Profile Update

Triggered when ALL mandatory fields for the selected layout pass all validation layers, or when the user explicitly skips Step-5.

```json
// Example: Layout 5A (Platform Worker)
verified_profile.work = {
  "work_type"               : "platform_worker",
  "layout"                  : "5A",
  "vehicle_number"          : "TN09AB1234",
  "vehicle_type"            : "Motorcycle",
  "rc_verified"             : true,
  "insurance_verified"      : true,
  "insurance_expiry"        : "2026-07-31",
  "vehicle_owner_mismatch"  : false,
  "platform_name"           : "Swiggy",
  "platform_tenure_months"  : 18,
  "platform_rating"         : 4.3,
  "trips_per_month"         : 142,
  "platform_income_verified": true,
  "monthly_earnings_inr"    : 18450,
  "work_verified"           : true,
  "step5_skipped"           : false
}
```

```json
// Example: Layout 5B (Vendor / Seller)
verified_profile.work = {
  "work_type"          : "vendor_seller",
  "layout"             : "5B",
  "svanidhi_verified"  : true,
  "loan_amount"        : 10000,
  "loan_status"        : "Disbursed",
  "next_loan_eligible" : 20000,
  "trade_licence"      : true,
  "trade_licence_valid": true,
  "work_verified"      : true,
  "step5_skipped"      : false
}
```

```json
// Example: Layout 5C (Skilled Tradesperson)
verified_profile.work = {
  "work_type"       : "skilled_tradesperson",
  "layout"          : "5C",
  "job_role"        : "Electrician",
  "nsqf_level"      : "Level 4",
  "nsdc_verified"   : true,
  "work_order"      : true,
  "work_value_inr"  : 45000,
  "work_verified"   : true,
  "step5_skipped"   : false
}
```

```json
// Example: Layout 5D (Freelancer)
verified_profile.work = {
  "work_type"              : "freelancer",
  "layout"                 : "5D",
  "platform"               : "Upwork",
  "platform_rating"        : 4.8,
  "platform_tenure_months" : 36,
  "invoice_count"          : 3,
  "invoice_total_inr"      : 95000,
  "invoice_verified"       : true,
  "work_verified"          : true,
  "step5_skipped"          : false
}
```

```json
// Example: Step skipped entirely
verified_profile.work = null
verified_profile.step5_skipped = true
```

---

## Section 8 — ML Features Produced

### Layout 5A — Platform Worker

| Feature | Description | Pillar |
|---|---|---|
| `dl_valid_binary` | DL is active and not expired | P5 |
| `rc_active_binary` | RC is active | P5 |
| `insurance_active_binary` | Vehicle insurance active | P5 |
| `platform_tenure_months` | Months on platform since join date | P1 |
| `platform_earnings_norm` | Monthly earnings normalized | P1 |
| `trips_per_month` | Delivery / trip count last 3 months avg | P1 |
| `bank_to_platform_ratio` | Bank credit vs platform stated earnings | P1 |
| `platform_income_verified` | Bank credit matched to screenshot (binary) | P1 |
| `platform_rating_norm` | Rating score normalized 0–1 | P5 |
| `vehicle_owner_mismatch` | RC owner ≠ Aadhaar name (binary) | P5 |

### Layout 5B — Vendor / Seller

| Feature | Description | Pillar |
|---|---|---|
| `svanidhi_verified_binary` | SVANidhi loan disbursed | P3 |
| `svanidhi_loan_norm` | Loan amount normalized | P3 |
| `next_loan_eligible_norm` | Upgrade eligibility normalized | P3 |
| `trade_licence_verified_binary` | Trade licence valid | P5 |
| `svanidhi_repayment_rate` | Monthly repayments found in bank CSV | P1 |
| `vendor_tenure_norm` | Estimated vendor tenure from approval date | P1 |

### Layout 5C — Skilled Tradesperson

| Feature | Description | Pillar |
|---|---|---|
| `nsdc_certified_binary` | Certificate valid | P5 |
| `nsqf_level_norm` | NSQF level normalized (1–8 → 0–1) | P5 |
| `work_order_verified_binary` | Work order document provided | P1 |
| `work_order_value_norm` | Work order amount normalized | P1 |
| `multi_skill_bonus` | > 1 NSDC certificate (binary) | P5 |
| `work_income_bank_match` | Work order value matched in bank | P1 |

### Layout 5D — Freelancer

| Feature | Description | Pillar |
|---|---|---|
| `client_invoice_verified_binary` | At least 1 invoice matched in bank | P1 |
| `invoice_total_norm` | Total invoiced amount normalized | P1 |
| `invoice_count` | Number of client invoices uploaded | P1 |
| `platform_rating_norm` | Freelance rating normalized 0–1 | P5 |
| `freelance_tenure_months` | Months on platform since join | P1 |
| `multi_platform_bonus` | Active on > 1 platform (binary) | P5 |

---

## Section 9 — Technical Flow (Final)

```
User opens Step-5
  ↓
System reads verified_profile.work_type from Step-1
  ↓
Renders correct layout (5A / 5B / 5C / 5D)
  ↓
[SKIP PATH]
User taps "Skip this step"
  → step5_skipped = true
  → verified_profile.work = null
  → Step-5 Status = SKIPPED
  → Continue button enabled
  → Navigate to Step-6
  ↓
[SUBMIT PATH]
--- LAYOUT 5A ---
User enters vehicle registration number
  → POST /api/gov/vehicle-rc-check
  [Fail] → Show error, uploads locked
  [Pass] → rc_api_verified = true
  → POST /api/gov/vehicle-insurance-check (auto-triggered)
  [Fail] → Show error, uploads locked
  [Pass] → insurance_api_verified = true
  ↓
*** GATE 1 OPENS — all upload slots enabled ***
  ↓
User uploads RC Book, DL Front, DL Back, Insurance Certificate
  → Per-document OCR extraction
  → Individual validation for each document
  → Cross-check between documents (vehicle number, owner name, DL class)
  ↓
User uploads 3 platform earning screenshots
  → Per-screenshot OCR: earnings, trips, rating, account name, tenure
  → Account name vs Step-1 name (HARD FAIL if mismatch)
  → Optional 2nd and 3rd platform screenshots processed if uploaded
  ↓
Cross-internal validation:
  → Vehicle number consistent across RC, insurance, screenshots
  → All 3 screenshots from same platform account
  ↓
Global validation:
  → Platform earnings vs Step-3 bank credits (±30%, ±7 days)
  → DL name confirmed vs Step-2 Aadhaar name (global level)
  ↓
All pass → work_verified = true for 5A

--- LAYOUT 5B ---
User enters SVANidhi Application ID
  → POST /api/gov/svanidhi-verify
  [Fail] → Show error, uploads locked
  [Pass] → svanidhi_api_verified = true
  ↓
*** GATE 1 OPENS ***
User uploads SVANidhi Letter, Trade Licence
  → OCR extraction + individual validation
  → Beneficiary name vs API vs Aadhaar name
  → Trade licence holder name vs Aadhaar name
  → Optional: No-Due Certificate, Association, Market Letter, GST
  ↓
Cross-internal + Global validation
All pass → work_verified = true for 5B

--- LAYOUT 5C ---
User enters Skill Certificate ID
  → POST /api/gov/skill-verify
  [Fail] → Show error, uploads locked
  [Pass] → skill_api_verified = true
  ↓
*** GATE 1 OPENS ***
User uploads NSDC Certificate, Work Order Letter
  → OCR extraction + individual validation
  → Candidate name vs API vs Aadhaar name
  → NSQF level vs API response
  → Optional: Experience cert, additional NSDC certs, GST
  ↓
Cross-internal + Global validation
All pass → work_verified = true for 5C

--- LAYOUT 5D ---
All upload slots available immediately (no API gate)
  ↓
User uploads Platform Profile Screenshot + Client Invoice(s)
  → OCR: account name, rating, tenure, earnings (from screenshot)
  → OCR: client, amount, date, status (from invoices)
  → Platform account name vs Step-1 name (HARD FAIL if mismatch)
  → Invoice date uniqueness check (HARD FAIL if all identical)
  → Optional: 2nd platform, portfolio, GST
  ↓
Cross-internal + Global validation:
  → Invoice amounts vs Step-3 bank credits (±30%, ±7 days)
All pass → work_verified = true for 5D

--- COMMON FINAL PATH ---
  ↓
All HARD FAILs cleared
All soft flags recorded
  ↓
*** GATE 2 OPENS — Continue button enabled ***
  ↓
Update verified_profile.work with all extracted data
  ↓
Mark Step-5 Status = VERIFIED
  ↓
Enable navigation to Step-6
```

---

## Section 10 — Output of Step-5

| Output | Value |
|---|---|
| Step-5 Status | `VERIFIED` or `SKIPPED` |
| `verified_profile.work` | Populated per layout (or null if skipped) |
| `step5_skipped` | `true` if user skipped, `false` if submitted |
| P1 ML features | Income stability features extracted |
| P5 ML features | Work identity features extracted |
| Step-6 Status | `UNLOCKED` |

### Cross-Step Dependencies Resolved by Step-5

- **Step-9 (Scoring):** All 5A/5B/5C/5D ML features used directly in P1 and P5 pillar computation
- **Step-7 (Insurance):** `vehicle_number`, `insurance_expiry`, `rc_verified` → used to pre-fill vehicle insurance validation in Step-7

---

*GigCredit Validation & Verification Specification — Step-5 Work Proof Verification*
*Version 1.0 | April 2026*
