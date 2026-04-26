# GigCredit — Step-3: Bank Account Verification
## Validation & Verification Specification | Version 1.0

---

## Purpose

Verify the user's bank account(s) via IFSC lookup and penny drop simulation, validate uploaded bank statements via OCR, normalize all transactions into a canonical CSV used by Steps 4–9 for timestamp + amount matching, and update the global profile with bank and income features.

**Maximum accounts:** 1 Primary + 1 Secondary (2 total). UPI/GPay statement is optional and appended to the same canonical transaction table.

---

## Section 1 — Inputs (Authoritative List — 11 Fields)

| # | Field Name | Type | Mandatory |
|---|---|---|---|
| 1 | Bank Name | Text / Dropdown | Required |
| 2 | Account Holder Name | Text | Required |
| 3 | Bank Branch Name | Text | Required |
| 4 | IFSC Code | Alphanumeric string | Required |
| 5 | MICR Code | Numeric string | Required |
| 6 | Account Number | Numeric string | Required |
| 7 | Bank Statement Upload | PDF / JPG / PNG | Required |
| 8 | Secondary Bank Name | Text / Dropdown | Optional |
| 9 | Secondary Account Number | Numeric string | Optional |
| 10 | Secondary IFSC Code | Alphanumeric | Optional |
| 11 | UPI / GPay Statement Upload | PDF / JPG / PNG | Optional |

> **No validation or verification logic references any field outside this list.**

---

## Section 2 — UI Gate Rules (Developer Mandatory)

The Step-3 screen enforces a strict sequential unlock model. UI elements are **LOCKED** by default and unlock only when the preceding gate condition is met.

```
GATE 1 — "Verify IFSC" button ENABLED only when:
  - IFSC Code passes on-device format check (Field 4)

GATE 2 — "Verify Account" button ENABLED only when:
  - ifsc_verified = true (API 1 success)
  - Account Number passes on-device format check (Field 6)

GATE 3 — Bank Statement Upload ENABLED only when:
  - ifsc_verified = true
  - account_verified = true (API 2 penny drop success)

GATE 4 — "Add Secondary Bank" button ENABLED only when:
  - Primary account_verified = true
  - Primary statement_validated = true
  - Primary cross-internal validation passed

GATE 5 — Continue / Submit Button ENABLED only when:
  - Primary account_verified = true
  - Primary statement_validated = true
  - Primary cross-internal checks 6.1–6.5 passed
  - Global validation check 9.1 passed
```

---

## Section 3 — Individual Validation (On-Device)

Runs locally on the device, field by field, before any API call is made.

---

### Field 1 — Bank Name

- **Type:** Text or dropdown
- **Rules:**
  - Non-empty
  - If free text: only letters and spaces, length ≥ 3
- **Error:** "Please enter a valid bank name."

---

### Field 2 — Account Holder Name

- **Type:** Text
- **Rules:**
  - Only alphabetic characters and spaces
  - Trimmed length ≥ 2
  - No digits, no special characters
- **Error:** "Account holder name must contain only letters and spaces."

---

### Field 3 — Bank Branch Name

- **Type:** Text
- **Rules:**
  - Non-empty, trimmed length ≥ 3
  - Only letters, numbers, spaces
- **Error:** "Please enter a valid branch name."

---

### Field 4 — IFSC Code

- **Type:** Alphanumeric string
- **Rules:**
  - Exactly 11 characters
  - Pattern: `[A-Z]{4}0[A-Z0-9]{6}` (first 4 = bank code, 5th char = `0`, last 6 = branch code)
  - App must auto-uppercase the input
- **Valid Example:** `HDFC0001234`
- **Error Messages:**
  - "IFSC must be exactly 11 characters."
  - "Invalid IFSC format. Example: HDFC0001234."

---

### Field 5 — MICR Code

- **Type:** Numeric string
- **Rules:**
  - Exactly 9 digits
  - No letters, no spaces
- **Error:** "MICR code must be exactly 9 digits."

---

### Field 6 — Account Number

- **Type:** Numeric string
- **Rules:**
  - Between 9 and 18 digits (Indian bank account range)
  - No letters, no spaces, no dashes
- **Error Messages:**
  - "Account number must be between 9 and 18 digits."
  - "Account number can only contain digits."

---

### Field 7 — Bank Statement Upload

- **Type:** PDF, JPG, or PNG
- **Rules:**
  - Accepted formats: PDF, JPG, PNG only
  - File size ≤ 10MB
  - Must not be blank / completely dark / all-white (basic brightness check on-device)
- **Error Messages:**
  - "File too large. Maximum size is 10MB."
  - "Invalid file format. Please upload PDF, JPG, or PNG."
  - "Document image appears blank. Please retake."

---

### Fields 8, 9, 10 — Secondary Bank Fields (Optional)

Same individual rules as Fields 1, 6, and 4 respectively.
Validated only if user chooses to add a secondary account.

---

### Field 11 — UPI / GPay Statement Upload (Optional)

- **Type:** PDF, JPG, or PNG
- **Rules:** Same as Field 7 (10MB cap, PDF/JPG/PNG only, not blank)
- Validated only if user uploads.

---

## Section 4 — Server-Side Verification APIs

### MongoDB Collections Used

| Collection | Purpose |
|---|---|
| `ifsc_db` | RBI IFSC dataset |
| `bank_accounts_db` | Bank account records (penny drop simulation) |

---

### API 1 — IFSC Verification

- **Method:** `POST`
- **Endpoint:** `/verify-ifsc`
- **MongoDB:** `ifsc_db`
- **Trigger:** IFSC passes on-device check → user taps "Verify IFSC" (Gate 1)

**Request Body:**
```json
{
  "ifsc": "HDFC0001234"
}
```

**Backend Logic:**
- Validate IFSC format (server-side)
- Lookup IFSC in `ifsc_db`
- If not found → return error
- If found → return bank and branch details

**Response (Success):**
```json
{
  "ifsc_valid"  : true,
  "bank_name"   : "HDFC Bank",
  "branch_name" : "Anna Nagar",
  "city"        : "Chennai",
  "state"       : "Tamil Nadu",
  "micr"        : "600240012"
}
```

**On-Device Action on Success:**
- Auto-fill `bank_name` and `branch_name` from API response
- If API `bank_name` differs from user-entered → show soft warning: "Bank name updated from IFSC lookup."
- If API `micr` differs from user-entered → show soft warning: "MICR updated from IFSC lookup."
- Set `ifsc_verified = true`
- **UNLOCK Gate 2:** Account Number Verify button enabled

**Error Responses:**
- `404` → "IFSC code not found in RBI database."

---

### API 2 — Bank Account Verification (Penny Drop Simulation)

- **Method:** `POST`
- **Endpoint:** `/verify-bank-account`
- **MongoDB:** `bank_accounts_db`
- **Trigger:** `ifsc_verified = true` + account number entered + user taps "Verify Account" (Gate 2)

**Request Body:**
```json
{
  "account_number" : "1234567890",
  "ifsc"           : "HDFC0001234",
  "name"           : "Ravi Kumar"
}
```

> **Note:** `name` is taken from the already-verified `aadhaar_name` stored in `verified_profile.identity`. The user does NOT re-enter their name.

**Backend Logic:**
- Lookup `account_number` + `ifsc` combination in `bank_accounts_db`
- If not found → return `account_exists: false`
- If found:
  - Compare `name` from request vs `account_holder_name` in DB (fuzzy match ≥ 85%)
  - Check account status = "Active"

**Response (Success):**
```json
{
  "account_exists"       : true,
  "is_active"            : true,
  "account_holder_name"  : "Ravi Kumar",
  "bank_name"            : "HDFC Bank",
  "name_match"           : true
}
```

**On-Device Action on Success:**
- Set `account_verified = true`
- Store `verified_account_holder_name` in local session state
- **UNLOCK Gate 3:** Bank Statement upload enabled

**Error Responses:**
- `404` → "Bank account not found."
- `400` → "Account holder name does not match records."
- `400` → "Account is inactive or closed."

---

## Section 5 — OCR Extraction from Bank Statement

Triggered after bank statement is uploaded (Gate 3 passed). All extraction happens in a **single processing pass**.

### 5.1 Fields Extracted by OCR

| Field | Example |
|---|---|
| Bank Name | HDFC Bank |
| Account Holder Name | Ravi Kumar |
| Account Number | 1234567890 |
| IFSC Code | HDFC0001234 |
| MICR Code | 600240012 |
| Statement From Date | 01-Aug-2025 |
| Statement To Date | 31-Jan-2026 |
| Transaction Table | All transaction rows |

### 5.2 Statement Period Validation

Run immediately after OCR extraction:

```
duration   = statement_to_date − statement_from_date

Condition 1: duration >= 6 months                          → PASS
Condition 2: current_date − statement_to_date <= 30 days   → PASS

Both conditions must pass. If either fails → HARD FAIL.
```

**Error Messages:**
- "Statement must cover at least 6 months of transactions."
- "Statement is outdated. Please upload a statement ending within the last 30 days."

---

## Section 6 — Cross-Internal Validation (Within Step-3)

Runs after OCR extraction and statement period validation pass. Compares OCR-extracted statement fields against verified bank API data stored in local session state. **No additional API call required.**

### Check 6.1 — Bank Name: Statement vs IFSC API

- OCR `bank_name` vs `ifsc_db` `bank_name`
- Exact match (case-insensitive) → PASS
- Mismatch → **HARD FAIL**
- **Blocking:** YES
- **Error:** "Bank name on statement does not match verified IFSC data."

### Check 6.2 — Account Holder Name: Statement vs Penny Drop API

- OCR `account_holder_name` vs `verified_account_holder_name` from penny drop
- Fuzzy match ≥ 85% → PASS
- Below threshold → **HARD FAIL**
- **Blocking:** YES
- **Error:** "Account holder name on statement does not match bank records."

### Check 6.3 — IFSC Code: Statement vs User Input

- OCR `ifsc` vs user-entered and API-verified IFSC
- Exact match → PASS
- Mismatch → **HARD FAIL**
- **Blocking:** YES
- **Error:** "IFSC code on statement does not match verified IFSC."

### Check 6.4 — Account Number: Statement vs User Input

- OCR `account_number` vs user-entered account number
- Exact match → PASS
- Mismatch → **HARD FAIL**
- **Blocking:** YES
- **Error:** "Account number on statement does not match entered account number."

### Check 6.5 — MICR Code: Statement vs IFSC API

- OCR `micr` vs MICR returned by IFSC API
- Exact match → PASS
- Mismatch → **Soft flag** `micr_mismatch = true` (non-blocking, logged for review)
- **Blocking:** NO

---

## Section 7 — Transaction Normalization (Canonical CSV)

After all cross-internal checks pass, OCR-extracted transactions are normalized into a **canonical transaction table** stored locally. This table is the **single source of truth** used by Steps 4–9 for all timestamp + amount matching.

### 7.1 Canonical Transaction Schema (Per Row)

| Column | Type | Description |
|---|---|---|
| `account_id` | string | Internal UUID for this bank account |
| `account_number` | string | Masked account number |
| `bank_name` | string | Verified bank name |
| `ifsc` | string | Verified IFSC |
| `statement_start_date` | date | Statement from date |
| `statement_end_date` | date | Statement to date |
| `transaction_id` | string | Synthetic unique ID per row |
| `txn_date` | date | Posting date (YYYY-MM-DD) |
| `value_date` | date | Value date if available |
| `amount` | float | Absolute transaction amount |
| `direction` | string | `CREDIT` or `DEBIT` |
| `merchant_raw` | string | Raw description from statement |
| `channel` | string | NEFT / UPI / CARD / CASH / AUTO_DEBIT |
| `category` | string | Normalized category label |
| `source` | string | PRIMARY_BANK / SECONDARY_BANK / UPI_STATEMENT |

### 7.2 Category Labels

| Label | Description |
|---|---|
| `INCOME_PLATFORM` | Swiggy, Zomato, Ola, Uber payouts |
| `INCOME_SALARY` | Regular salary credits |
| `INCOME_TRANSFER` | Generic bank transfers in |
| `UTILITY_EB` | Electricity bill payments |
| `UTILITY_MOBILE` | Mobile recharge / bill |
| `UTILITY_GAS` | LPG / gas bill |
| `UTILITY_WATER` | Water bill |
| `TELECOM_BROADBAND` | WiFi / fiber bill |
| `INSURANCE_HEALTH` | Health insurance premium |
| `INSURANCE_LIFE` | Life insurance premium |
| `INSURANCE_VEHICLE` | Vehicle insurance premium |
| `LOAN_EMI` | Loan repayment / EMI |
| `RENT` | Rent payments |
| `SCHEME_PMSYM` | PM-SYM contribution |
| `SCHEME_PMJJBY` | PMJJBY premium |
| `SCHEME_PPF` | PPF deposit |
| `CASH_WITHDRAWAL` | ATM / cash out |
| `OTHER_DEBIT` | Unclassified debit |
| `OTHER_CREDIT` | Unclassified credit |

### 7.3 Downstream Matching Logic (Used by Steps 4–9)

When an external bill or document is uploaded in later steps:

```
MATCH CRITERIA — all three must align:

1. Date proximity:
   abs(txn_date − bill_payment_date) <= 3 days

2. Amount proximity:
   abs(txn_amount − bill_amount) <= 5 INR
   OR within 2% of bill_amount (whichever is larger)

3. Category / Merchant:
   category matches expected bill type
   OR merchant_raw contains provider keyword tokens
   (e.g. "TNEB", "BSNL", "JIO", "LIC", "STAR HEALTH")

UNIQUENESS RULE:
  Each transaction_id can satisfy at most ONE bill match.
  Maintain an "assigned_transaction_ids" set to prevent one
  transaction from validating multiple bills.

RESULT:
  Match found    → bank_matched = true for that bill
  No match found → bank_matched = false (not payment proof)
```

---

## Section 8 — UPI / GPay Statement Validation (Optional)

Triggered only if user uploads Field 11.

### OCR Extracts:
- Mobile number linked to UPI ID
- UPI ID string
- Transaction timestamps and amounts

### Validation:
- **UPI mobile number vs Step-1 mobile** (`verified_profile.mobile`):
  - Exact match → `upi_mobile_match = true` → PASS
  - Mismatch → soft flag `upi_mobile_mismatch = true` (non-blocking, logged)
- UPI transactions normalized and appended to canonical transaction table with `source = "UPI_STATEMENT"`

---

## Section 9 — Global Validation (Cross-Step)

Runs after all cross-internal checks pass.

### Check 9.1 — Account Holder Name vs Step-2 Aadhaar Name

- `verified_account_holder_name` (from penny drop API) vs `verified_profile.identity.aadhaar_name`
- Fuzzy match ≥ 85% → PASS
- Below threshold → **HARD FAIL**
- **Blocking:** YES
- **Error:** "Bank account holder name does not match your verified identity name."

---

## Section 10 — Secondary Bank Account

The secondary bank account follows the **identical process** as the primary bank account for all inputs, gates, APIs, OCR extraction, cross-internal checks, and global validation.

### Additional Check (Secondary Only)

After secondary account holder name is verified via penny drop:

- `secondary_account_holder_name` vs `primary_account_holder_name`
- Fuzzy match ≥ 85% → PASS
- Below threshold → **HARD FAIL**
- **Error:** "Secondary account holder name does not match primary account holder name. Both accounts must belong to the same person."

### Differences vs Primary

| Dimension | Primary | Secondary |
|---|---|---|
| Mandatory | Required | Optional |
| Unlock condition | Step opens | Primary fully verified + statement validated |
| Max accounts | 1 | 1 (max 2 total) |
| CSV source tag | `PRIMARY_BANK` | `SECONDARY_BANK` |
| Additional name check | None | Must match primary account holder name |

---

## Section 11 — Global Profile Update

Triggered when ALL of the following are true:
- `account_verified = true`
- `statement_validated = true`
- Cross-internal checks 6.1–6.5 passed
- Global check 9.1 passed

```json
verified_profile.bank = {
  "primary": {
    "bank_name"           : "HDFC Bank",
    "account_number"      : "XXXXXX7890",
    "ifsc"                : "HDFC0001234",
    "micr"                : "600240012",
    "account_holder_name" : "Ravi Kumar",
    "account_verified"    : true,
    "statement_from"      : "2025-08-01",
    "statement_to"        : "2026-01-31",
    "statement_validated" : true
  },
  "secondary": {
    // same structure if added, else null
  },
  "upi": {
    "upi_id"           : "ravi@upi",
    "upi_mobile_match" : true
  },
  "bank_verified"         : true,
  "canonical_txn_table"   : "stored_locally_as_csv"
}
```

### ML Features Produced (Stored in Global State)

| Pillar | Feature Count | Examples |
|---|---|---|
| P1 — Income Stability | 26 features | Monthly income avg, platform credit consistency, income volatility |
| P2 — Payment Discipline | 15 features | On-time EMI rate, utility payment regularity, bounce frequency |
| P3 — Debt Management | 9 features | EMI-to-income ratio, total outstanding debt load |
| P4 — Savings Behaviour | 10 features | Month-end balance, savings rate, cash withdrawal frequency |

**RULE:** All later steps read bank data from `verified_profile.bank` only. They do NOT re-query bank APIs. All bill matching uses the canonical transaction CSV only.

---

## Section 12 — Technical Flow (Final)

```
User opens Step-3
  ↓
User enters bank details (Fields 1–6)
  → On-device individual validation for each field
  [Any fail] → Show field error, keep IFSC verify button disabled
  ↓
User taps "Verify IFSC" (Gate 1)
  → POST /verify-ifsc
  → Auto-fill bank name, branch name, MICR from API response
  [404] → "IFSC not found in RBI database"
  [Success] → ifsc_verified = true
  ↓
*** GATE 2 OPENS — "Verify Account" button enabled ***
  ↓
User taps "Verify Account"
  → POST /verify-bank-account (sends aadhaar_name as name field)
  [404] → "Bank account not found"
  [400] → "Name / Account inactive"
  [Success] → account_verified = true, store verified_account_holder_name
  ↓
*** GATE 3 OPENS — Bank Statement Upload enabled ***
  ↓
User uploads Bank Statement (Field 7)
  → On-device: file format + size check
  [Fail] → Show upload error
  ↓
OCR extraction (single pass)
  → Extract bank name, account holder, account number, IFSC,
    MICR, statement dates, full transaction table
  ↓
Statement period validation
  → duration >= 6 months AND to_date within 30 days
  [Fail] → Show error, request new statement
  ↓
Cross-internal validation (Checks 6.1–6.5)
  [Any HARD FAIL] → Show specific error, block Continue
  ↓
Normalize transactions → canonical transaction CSV stored locally
  statement_validated = true
  ↓
[OPTIONAL] User uploads UPI / GPay Statement (Field 11)
  → OCR + mobile number cross-check vs Step-1 verified mobile
  → Append to canonical CSV with source = "UPI_STATEMENT"
  ↓
[OPTIONAL] User taps "Add Secondary Bank"
  (Gate 4 opens — primary fully verified)
  → Identical IFSC + penny drop + OCR + statement flow
  → Additional check: secondary name vs primary name
  → Append secondary transactions to canonical CSV
  ↓
Global validation
  → Check 9.1: verified_account_holder_name vs aadhaar_name
  [Fail] → HARD FAIL, block Continue
  ↓
All checks pass
  ↓
*** GATE 5 OPENS — Continue button enabled ***
  ↓
Update verified_profile.bank
  ↓
Mark Step-3 Status = VERIFIED
  ↓
Enable navigation to Step-4
```

---

## Section 13 — Output of Step-3

| Output | Value |
|---|---|
| Step-3 Status | `VERIFIED` |
| `verified_profile.bank` | Initialized and stored |
| `canonical_txn_table` | Stored locally (used by Steps 4–9) |
| P1 ML features | 26 income features extracted |
| P2 ML features | 15 payment discipline features extracted |
| P3 ML features | 9 debt management features extracted |
| P4 ML features | 10 savings behaviour features extracted |
| Step-4 Status | `UNLOCKED` |

### Cross-Step Dependencies Resolved by Step-3

- **Step-4:** Utility bill amount + date matched against canonical transaction CSV
- **Step-5:** Insurance premium matched against canonical transaction CSV
- **Step-6:** Scheme contribution matched against canonical transaction CSV
- **Step-7:** Rent payment matched against canonical transaction CSV
- **Step-8:** ITR income cross-checked against bank income credits (P1 features)
- **Step-9:** P1, P2, P3, P4 ML features used in final credit score computation

---

*GigCredit Validation & Verification Specification — Step-3 Bank Account Verification*
*Version 1.0 | April 2026*
