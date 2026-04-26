# GigCredit — Step-4: Utility Bill Verification
## Validation & Verification Specification | Version 1.0

---

## Purpose

Evaluate payment discipline and financial consistency through 6 months of recurring household bill payments. Bills are cross-referenced against the Step-3 canonical transaction CSV to confirm actual payment — not just possession of a bill. Verified utility data populates the P2 (Payment Discipline) pillar of the credit scoring engine.

**Design decisions locked in this step:**
- EB consumer name is **NOT validated** — house owner's name may appear on the EB account. Consumer number is the identity anchor.
- LPG bank transaction matching is **OPTIONAL** — LPG refills are frequently paid in cash. A match is a bonus signal, not a mandatory requirement.
- Mobile bill number must match Step-1 registered mobile — **HARD FAIL** if mismatch.
- Rent section is **conditional** — shown only if the user is detected as a renter.

---

## Section 1 — Inputs (Authoritative List — 30 Fields)

| # | Field Name | Type | Mandatory |
|---|---|---|---|
| 1–6 | Electricity Bills (Month 1 to Month 6) | JPG / PNG / PDF | Required |
| 7–12 | LPG / Gas Bills (Month 1 to Month 6) | JPG / PNG / PDF | Required |
| 13–18 | Mobile Recharge Bills (Month 1 to Month 6) | JPG / PNG / PDF | Required |
| 19 | Rent Proof — Option A: Rental Agreement | PDF / Image | Conditional |
| 20 | Rent Proof — Option B: 6 Monthly Rent Receipts | JPG / PNG / PDF (6 slots) | Conditional |
| 21 | Rent Proof — Option C: Auto-Detected from Bank | Automatic (no upload) | Conditional |
| 22–27 | WiFi / Broadband Bills (up to 6) | JPG / PNG / PDF | Optional |
| 28–30 | OTT Subscription Receipts (any count) | Screenshot / PDF | Optional |

> **Only ONE of Options A, B, or C is required for rent. Option C requires no upload.**

> **No validation or verification logic references any field outside this list.**

---

## Section 2 — UI Gate Rules (Developer Mandatory)

```
GATE 1 — EB Upload Slots ENABLED only when:
  - User enters EB service number
  - POST /api/gov/eb-verify returns connection_status = "Active"

GATE 2 — LPG Upload Slots ENABLED only when:
  - User enters LPG consumer number + selects provider
  - POST /api/gov/lpg-verify returns connection_status = "Active"

GATE 3 — Mobile Upload Slots ENABLED immediately:
  - No API verification for mobile bills
  - All 6 slots shown on screen by default

GATE 4 — Rent Section SHOWN only when:
  - verified_profile.current_address ≠ verified_profile.permanent_address (Step-1)
  - OR canonical_txn_table contains RENT / HOUSE RENT / HRA / LANDLORD keywords
  Option C is PRE-SELECTED if bank keywords are detected.
  User sees: "We found rent payments in your bank statement.
              No upload needed — your rent history is already confirmed."

GATE 5 — Continue / Submit Button ENABLED only when:
  - electricity_verified = true
  - lpg_verified = true
  - mobile_verified = true
  - rent_verified = true  (only if rent section is shown)
  - All cross-internal checks 9.1–9.3 passed
  - All global checks 10.1–10.4 passed
  (WiFi and OTT do not block Continue)
```

---

## Section 3 — Utility 1: Electricity (EB)

### 3.1 API Verification

- **Method:** `POST`
- **Endpoint:** `/api/gov/eb-verify`
- **MongoDB:** `eb_db`
- **Trigger:** User enters EB service number → taps "Verify EB Connection" (Gate 1)

**Request Body:**
```json
{
  "service_number": "0119400742"
}
```

**Backend Logic:**
- Lookup service number in `eb_db`
- If not found → return error
- If found → return connection status

**Response (Success):**
```json
{
  "valid"             : true,
  "service_number"    : "0119400742",
  "connection_status" : "Active"
}
```

**On-Device Action on Success:**
- Store `eb_service_number` in local session state
- Set `eb_api_verified = true`
- **UNLOCK Gate 1:** All 6 EB bill upload slots enabled

**Error Responses:**
- `404` → "Electricity service number not found in database."
- `400` → "Connection is inactive or disconnected."

---

### 3.2 OCR Extracts Per EB Bill

| Field | Example | Used For |
|---|---|---|
| Service / Consumer Number (S.C. Number) | 0119400742 | Consistency check across all 6 bills |
| Receipt Number / Payment Reference | PGIBP2801862359 | Proof of payment |
| Payment Date | 05-11-2025 | Monthly pattern check, recency |
| Bill Amount | 905.00 | Amount consistency across 6 months |
| Payment Mode | BHARAT BILL PAYMENT SYSTEM | Digital payment detection |

> **Consumer Name is intentionally NOT extracted or validated.**
> House owner's name appears on EB accounts for rented homes.
> Consumer number is the sole identity anchor for electricity.

---

### 3.3 Individual Validation Per EB Bill

| Check | Rule | Blocking |
|---|---|---|
| Service number (OCR) vs API | Must match exactly | HARD FAIL |
| Connection status | Must be "Active" | HARD FAIL |
| Payment date | Must be a valid date | HARD FAIL |
| Bill amount | Must be > 0 INR | HARD FAIL |
| Consumer Name | NOT VALIDATED (intentional) | — |

**Error Messages:**
- "Service number on bill does not match your verified EB connection."
- "Electricity connection is not active."
- "Invalid payment date detected on bill."

---

### 3.4 Bank Transaction Matching — EB (Mandatory)

Uses canonical transaction CSV from Step-3.

```
MATCH CRITERIA (all three must align):
  1. abs(txn_date − bill_payment_date) <= 3 days
  2. abs(txn_amount − bill_amount) <= 5 INR  OR  within 2% of bill_amount
  3. category = "UTILITY_EB"
     OR merchant_raw contains: "TNEB", "BESCOM", "MSEDCL", "KSEB",
        "BBPS", "ELECTRICITY"

RESULT:
  Match found → bank_matched = true (bonus P2 signal)
  No match    → bank_matched = false (soft flag, non-blocking per bill)
```

---

### 3.5 Cross-Internal Validation — EB (After All 6 Bills)

| Check | Rule | Blocking |
|---|---|---|
| Service number consistency | Identical across all 6 bills | HARD FAIL |
| Distinct months | All 6 bills represent 6 different months | HARD FAIL |
| Monthly payment cadence | Gap between consecutive bills ≤ 45 days | Soft flag |

**Error Messages:**
- "All electricity bills must belong to the same consumer number."
- "Duplicate month detected in electricity bills. Please upload one bill per month."

---

## Section 4 — Utility 2: LPG / Gas

### 4.1 API Verification

- **Method:** `POST`
- **Endpoint:** `/api/gov/lpg-verify`
- **MongoDB:** `lpg_db`
- **Trigger:** User enters consumer number + selects provider → taps "Verify LPG Connection" (Gate 2)

**Request Body:**
```json
{
  "consumer_number" : "45678912",
  "provider"        : "Indane"
}
```

**Accepted Providers:** Indane (Indian Oil), HP Gas (Hindustan Petroleum), Bharat Gas

**Response (Success):**
```json
{
  "valid"             : true,
  "consumer_name"     : "Ravi Kumar",
  "provider"          : "Indane",
  "connection_status" : "Active"
}
```

**On-Device Action on Success:**
- Store `lpg_consumer_number`, `lpg_consumer_name`, `lpg_provider` in local session
- Set `lpg_api_verified = true`
- **UNLOCK Gate 2:** All 6 LPG bill upload slots enabled

**Error Responses:**
- `404` → "LPG consumer number not found."
- `400` → "Connection is inactive."

---

### 4.2 OCR Extracts Per LPG Bill

| Field | Example | Used For |
|---|---|---|
| Consumer Number | 45678912 | Consistency check across all 6 invoices |
| Consumer Name | Ravi Kumar | API cross-check (fuzzy match) |
| Provider Name / Logo | Indane | Provider identity match |
| Order / Delivery Date | 15-11-2025 | Monthly pattern check |
| Amount Paid | 850.00 | Amount consistency |
| Order Status | Delivered | Delivery confirmation |

---

### 4.3 Individual Validation Per LPG Bill

| Check | Rule | Blocking |
|---|---|---|
| Consumer number (OCR) vs API | Must match exactly | HARD FAIL |
| Consumer name (OCR) vs API | Fuzzy match ≥ 85% | HARD FAIL |
| Provider (OCR) vs API | Must match | HARD FAIL |
| Connection status | Must be "Active" | HARD FAIL |

**Error Messages:**
- "Consumer number on LPG invoice does not match your verified connection."
- "Consumer name on LPG invoice does not match records."

---

### 4.4 Bank Transaction Matching — LPG (OPTIONAL — Not Mandatory)

```
LPG refills are frequently paid in cash.
Bank transaction matching is a BONUS SIGNAL only.

MATCH CRITERIA (same as EB):
  1. abs(txn_date − order_date) <= 3 days
  2. abs(txn_amount − lpg_amount) <= 5 INR  OR  within 2%
  3. category = "UTILITY_GAS"
     OR merchant_raw contains: "INDANE", "HP GAS", "BHARAT GAS", "LPG"

RESULT:
  Match found → bank_matched = true (bonus P2 signal)
  No match    → bank_matched = false (ZERO PENALTY — non-blocking)
```

---

### 4.5 Cross-Internal Validation — LPG (After All 6 Bills)

| Check | Rule | Blocking |
|---|---|---|
| Consumer number consistency | Identical across all 6 invoices | HARD FAIL |
| Distinct months | All 6 invoices represent 6 different months | HARD FAIL |

**Error Messages:**
- "All LPG invoices must belong to the same consumer number."
- "Duplicate month detected in LPG invoices."

---

## Section 5 — Utility 3: Mobile Recharge Bills

### 5.1 No API Verification

Mobile bills have no server-side API. Validated entirely via OCR + Step-1 global match + bank transaction matching.

**Accepted Providers:** Jio, Airtel, Vi (Vodafone Idea), BSNL, MTNL

---

### 5.2 OCR Extracts Per Mobile Bill

| Field | Example | Used For |
|---|---|---|
| Mobile Number | 9876543210 | Consistency check + Step-1 global match |
| Provider Name | Jio | Provider identity |
| Statement / Bill Date | 21 Dec 2025 | Monthly pattern check |
| Statement Period (from / to) | 20 Nov 2025 – 19 Dec 2025 | Coverage period |
| Due Date | 31 Dec 2025 | Payment timing check |
| Total Amount Payable | 1,706.28 | Amount consistency |
| Plan Type | Infinity 549 | Active subscription proof |

---

### 5.3 Individual Validation Per Mobile Bill

| Check | Rule | Blocking |
|---|---|---|
| Mobile number format | Exactly 10 digits, starts with 6–9 | HARD FAIL |
| Mobile number vs Step-1 mobile | Must match exactly | HARD FAIL |
| Bill date | Must be a valid date | HARD FAIL |
| Amount | Must be > 0 INR | HARD FAIL |

> **IMPORTANT — Global Identity Lock:**
> Mobile number on every bill is compared against `verified_profile.mobile` (Step-1).
> Any mismatch → HARD FAIL immediately. This catches fake user switching.

**Error Messages:**
- "Mobile number on bill does not match your registered mobile number."
- "Invalid mobile number format detected on bill."

---

### 5.4 Bank Transaction Matching — Mobile (Mandatory)

```
MATCH CRITERIA:
  1. abs(txn_date − bill_due_date) <= 3 days
  2. abs(txn_amount − bill_amount) <= 5 INR  OR  within 2%
  3. category = "UTILITY_MOBILE"
     OR merchant_raw contains: "JIO", "AIRTEL", "VODAFONE", "VI", "BSNL",
        "RECHARGE", "TELECOM"

RESULT:
  Match found → bank_matched = true
  No match    → bank_matched = false (soft flag, tracked for P2 scoring)
```

---

### 5.5 Cross-Internal Validation — Mobile (After All 6 Bills)

| Check | Rule | Blocking |
|---|---|---|
| Mobile number consistency | Identical across all 6 bills | HARD FAIL |
| Distinct months | All 6 bills represent 6 different months | HARD FAIL |
| Monthly cadence | Gap between consecutive bills ≤ 45 days | Soft flag |

**Error Messages:**
- "All mobile bills must belong to the same mobile number."
- "Duplicate month detected in mobile bills."

---

## Section 6 — Rent Module (Conditional)

### 6.1 Display Condition

Rent section is shown only when:
- `verified_profile.current_address ≠ verified_profile.permanent_address` (from Step-1 global state)
- **OR** canonical transaction CSV contains transactions tagged `RENT` / `HOUSE RENT` / `HRA` / `LANDLORD`

If **neither** condition is true → rent section is hidden entirely. No penalty.

---

### Option A — Rental Agreement

**OCR Extracts:**

| Field | Used For |
|---|---|
| Tenant Name | Cross-check vs Step-1 name |
| Landlord Name | Rent proof identity |
| Property Address | Cross-check vs Step-1 current address |
| Lease Start Date | Recency check |
| Lease End Date | Coverage period |
| Monthly Rent Amount | Rent amount anchor |
| Stamp Paper Value | Document authenticity |
| State / Jurisdiction | Jurisdiction (Tamil Nadu or relevant state visible) |
| Notary / Stamp Number | Document registration |

**Validation:**
- Tenant name vs `verified_profile.name` → fuzzy match ≥ 85% → PASS, else HARD FAIL
- Property address vs `verified_profile.current_address` → partial match at city level
- Lease period must cover at least 1 month within the last 6 months
- Stamp paper value must be readable

---

### Option B — 6 Monthly Rent Receipts

**OCR Extracts Per Receipt:**

| Field | Used For |
|---|---|
| Tenant Name | Cross-check vs Step-1 name |
| Landlord Name | Consistency across 6 receipts |
| Receipt Number | Uniqueness check |
| Date | Monthly pattern check |
| Rent Amount | Consistency across 6 receipts |
| Rental Period (from / to) | Monthly coverage confirmation |
| Property Address | Cross-check vs Step-1 address |
| Payment Method | Digital vs cash detection |

**Validation Per Receipt:**
- Tenant name vs `verified_profile.name` → fuzzy ≥ 85% → PASS
- Receipt number must be unique across all 6 receipts
- Property address must be consistent across all receipts
- Landlord name must be consistent across all receipts
- Rent amount consistency (±10% tolerance for minor variations)
- Dates must show a monthly pattern

---

### Option C — Auto-Detection from Bank (No Upload Required)

- Pre-selected if canonical CSV contains `RENT` category transactions
- System confirmation shown: *"We found rent payments in your bank statement. No upload needed — your rent history is already confirmed."*
- Requires 6 `RENT`-tagged transactions in canonical CSV (one per month)
- If fewer than 6 RENT transactions found → Option C not pre-selected → user must use A or B

---

## Section 7 — Optional: WiFi / Broadband Bills

**No API Verification.**
**Accepted Providers:** Jio Fiber, ACT Fibernet, Airtel Xstream Fiber, Hathway, BSNL Broadband

### OCR Extracts Per Bill

| Field | Example | Used For |
|---|---|---|
| Account ID / Customer Number | 969366 | Consistency across all bills |
| Customer Name | Presilla Thomas | Soft identity check |
| Invoice Date / Billing Cycle | 01-04-2025 | Monthly pattern |
| Due Date | 13-04-2025 | Payment timing |
| Total Amount Due | 803.37 | Amount consistency |
| Plan / Tariff | Flash 2 LITE Monthly | Active subscription proof |
| Provider | Hathway | Provider identity |

### Validation
- Account ID must be identical across all uploaded bills → HARD FAIL if mismatch
- Customer name vs Step-1 name → soft flag if mismatch (non-blocking, logged)
- Payment matched against canonical CSV (category `TELECOM_BROADBAND`)
- Does NOT block Continue if validation fails (optional utility)

---

## Section 8 — Optional: OTT Subscription Receipts

**No API Verification.**
**Accepted Platforms:** Netflix, Amazon Prime, Disney+ Hotstar, SonyLIV, ZEE5, JioCinema

### OCR Extracts Per Receipt

| Field | Used For |
|---|---|
| Platform Name | Platform identity |
| Payment Date | Monthly pattern |
| Amount | Amount consistency |
| Subscription Type | Monthly vs annual detection |
| Account Email (masked) | Soft identity reference |

### Validation
- Each receipt must represent a distinct platform
- Payment matched against canonical CSV (merchant keyword match)
- Monthly subscriptions contribute to P2 scoring; annual plans flagged separately
- Does NOT block Continue if validation fails (optional utility)

---

## Section 9 — Cross-Internal Validation (Across All Utilities)

Runs after all mandatory utilities individually pass.

### Check 9.1 — Same 6-Month Rolling Window

- EB, LPG, and Mobile bill months should overlap within the same rolling 6-month window
- If utilities cover significantly different time periods → soft flag `utility_period_mismatch = true`
- **Blocking:** NO (soft flag, logged for P2 scoring)

### Check 9.2 — Payment Cadence Consistency

- Bills must show a consistent monthly payment cadence across all utilities
- Gaps > 45 days between consecutive bills of the same utility → `payment_gap_detected = true`
- **Blocking:** NO (soft flag, reduces P2 score)

### Check 9.3 — Bank Match Rate Computation

- Compute:
  ```
  utility_bank_match_rate =
    (EB matched + LPG matched + Mobile matched) / total mandatory bills
  ```
- Stored in global state
- Used as a direct P2 pillar feature
- **Blocking:** NO (metric stored, not a gate)

---

## Section 10 — Global Validation (Cross-Step)

### Check 10.1 — Mobile Number: Bills vs Step-1 (Global Identity Lock)

- Mobile number on every bill vs `verified_profile.mobile` (Step-1)
- Already enforced at individual bill level (Section 5.3)
- Confirmed here at global level: `mobile_bills_match_step1 = true`
- **Blocking:** YES (HARD FAIL at individual level already enforced)

### Check 10.2 — LPG Consumer Name vs Step-2 Aadhaar Name

- `lpg_consumer_name` (from API) vs `verified_profile.identity.aadhaar_name`
- Fuzzy match ≥ 85% → PASS
- Below threshold → soft flag `lpg_name_mismatch = true`
- **Blocking:** NO (non-blocking — LPG may be registered under spouse/family member name)

### Check 10.3 — Rent Tenant Name vs Step-1 Name

- Only runs if rent section is shown and Option A or B is used
- Tenant name (OCR) vs `verified_profile.name` → fuzzy ≥ 85% → PASS
- Below threshold → **HARD FAIL**
- **Blocking:** YES
- **Error:** "Tenant name on rent document does not match your profile name."

### Check 10.4 — EB / Utility Service Address vs Step-1 Current Address

- OCR-extracted service address on EB bill vs `verified_profile.current_address`
- Partial match at city level → PASS
- Complete mismatch (different city / state) → soft flag `utility_address_mismatch = true`
- **Blocking:** NO (non-blocking — logged for P2 scoring, catches document substitution)
- **Purpose:** Detects fake user switching where bills from a different city are uploaded

> **Why this matters:** If Step-1 address is Chennai but uploaded EB bills show a Hyderabad service address, this flag triggers and is logged as a fraud signal, even though it does not hard-block the step.

---

## Section 11 — Global Profile Update

Triggered when ALL of the following are true:
- `electricity_verified = true`
- `lpg_verified = true`
- `mobile_verified = true`
- `rent_verified = true` (only if rent section was shown)
- Cross-internal checks 9.1–9.3 computed
- Global checks 10.1–10.4 evaluated

```json
verified_profile.utility = {
  "electricity": {
    "service_number"   : "0119400742",
    "verified"         : true,
    "bank_match_count" : 5,
    "bills_count"      : 6
  },
  "lpg": {
    "consumer_number"  : "45678912",
    "provider"         : "Indane",
    "consumer_name"    : "Ravi Kumar",
    "verified"         : true,
    "bank_match_count" : 3,
    "bills_count"      : 6
  },
  "mobile": {
    "mobile_number"    : "9876543210",
    "provider"         : "Jio",
    "verified"         : true,
    "bank_match_count" : 6,
    "bills_count"      : 6
  },
  "rent": {
    "verified"         : true,
    "option_used"      : "B",
    "monthly_rent"     : 8000
  },
  "wifi": {
    "verified"         : true,
    "bank_match_count" : 6,
    "provider"         : "Jio Fiber"
  },
  "ott": {
    "verified"         : true,
    "platforms"        : ["Netflix", "Amazon Prime"]
  },
  "utility_bank_match_rate"    : 0.92,
  "utility_period_mismatch"    : false,
  "payment_gap_detected"       : false,
  "utility_address_mismatch"   : false,
  "lpg_name_mismatch"          : false,
  "utility_verified"           : true
}
```

### ML Features Produced (P2 Pillar)

| Feature | Description |
|---|---|
| `utility_on_time_ratio` | Bills paid on or before due date vs total bills |
| `utility_bank_match_rate` | % of mandatory bills matched in canonical bank CSV |
| `utility_payment_gap_flag` | Gap > 45 days detected in payment cadence |
| `provider_type_encoded` | Postpaid (1) vs prepaid (0) for mobile |
| `rent_verified_binary` | Rent confirmed (1) or not shown (0) |
| `wifi_verified_binary` | Broadband bill validated (1) or not uploaded (0) |
| `ott_verified_binary` | OTT subscription validated (1) or not uploaded (0) |

---

## Section 12 — Fake User Switching Detection (Full Chain)

This step contributes to the multi-step identity lock that prevents document substitution across steps. The full detection chain:

```
STEP 1  → Sets anchor: name, DOB, mobile, address
STEP 2  → Aadhaar/PAN name + DOB must match Step-1    → HARD FAIL if not
STEP 3  → Bank account holder must match Aadhaar name  → HARD FAIL if not
STEP 4  → Mobile bills must match Step-1 mobile        → HARD FAIL if not
          Rent tenant name must match Step-1 name       → HARD FAIL if not
          EB address mismatch vs Step-1 address         → Soft fraud flag
STEP 5  → Work doc name must match Aadhaar name        → HARD FAIL if not
STEP 6  → Scheme holder name must match Aadhaar name   → HARD FAIL if not
STEP 7  → Insurance holder name must match Aadhaar     → HARD FAIL if not
STEP 8  → ITR name must match PAN name (Step-2)        → HARD FAIL if not
```

**Example Attack Caught at Step-4:**
```
Step 1 registered mobile:  9876543210 (Person A)
Step 4 uploaded mobile bill: 9123456789 (Person B)

→ Individual Validation Check (Section 5.3):
  OCR mobile number "9123456789"
  vs verified_profile.mobile "9876543210"
  → HARD FAIL
  → Error: "Mobile number on bill does not match your registered mobile number."
  → Step-4 BLOCKED for mobile utility. User cannot proceed.
```

---

## Section 13 — Technical Flow (Final)

```
User opens Step-4
  ↓
[ELECTRICITY]
User enters EB service number → taps "Verify EB Connection"
  → POST /api/gov/eb-verify
  [Not found / inactive] → Show error, keep slots locked
  [Active] → eb_api_verified = true
  ↓
*** GATE 1 OPENS — 6 EB bill upload slots enabled ***
  ↓
User uploads 6 EB bills (Month 6 latest → Month 1 oldest)
  → Per-bill OCR extraction
  → Individual validation (service number, payment date, amount)
  → Bank transaction match vs canonical CSV
  [Fail] → Flag that slot, show error
  ↓
After all 6 EB bills uploaded and individually validated:
  → Cross-internal check: service number identical across all 6
  → Distinct months check
  → electricity_verified = true
  ↓
[LPG / GAS]
User enters consumer number + selects provider → taps "Verify LPG Connection"
  → POST /api/gov/lpg-verify
  [Not found / inactive] → Show error
  [Active] → lpg_api_verified = true
  ↓
*** GATE 2 OPENS — 6 LPG bill upload slots enabled ***
  ↓
User uploads 6 LPG bills
  → Per-bill OCR extraction
  → Individual validation (consumer number, name, provider)
  → Optional bank match (non-blocking)
  ↓
After all 6 LPG bills:
  → Cross-internal: consumer number consistency
  → lpg_verified = true
  ↓
[MOBILE]
6 mobile bill upload slots shown by default (no API gate)
  ↓
User uploads 6 mobile bills
  → Per-bill OCR extraction
  → Individual validation:
      mobile number format check
      mobile number vs verified_profile.mobile (HARD FAIL if mismatch)
      date and amount check
  → Bank transaction match vs canonical CSV
  ↓
After all 6 mobile bills:
  → Cross-internal: mobile number consistency across all 6
  → mobile_verified = true
  ↓
[RENT — Conditional]
  If current_address ≠ permanent_address OR bank RENT keywords detected:
    → Rent section shown
    If bank keywords found → Option C pre-selected (no upload needed)
    Else → User chooses Option A or Option B
      Option A: Upload rental agreement
        → OCR: tenant name, landlord, address, dates, stamp
        → Tenant name vs Step-1 name (fuzzy ≥ 85%)
      Option B: Upload 6 rent receipts
        → Per-receipt OCR: tenant, landlord, receipt no, date, amount
        → Uniqueness, consistency, address, cadence checks
      → rent_verified = true
  If neither condition → Rent section hidden, rent_verified = true by default
  ↓
[OPTIONAL — WiFi / Broadband]
  User uploads up to 6 broadband bills
    → OCR: account ID, customer, date, amount, plan
    → Account ID consistency check
    → Bank match vs canonical CSV
  ↓
[OPTIONAL — OTT Subscriptions]
  User uploads any OTT receipts
    → OCR: platform, date, amount, type
    → Bank match vs canonical CSV
  ↓
Cross-internal validation (Checks 9.1–9.3)
  → Utility period overlap check (soft flag)
  → Payment cadence check (soft flag)
  → utility_bank_match_rate computed
  ↓
Global validation (Checks 10.1–10.4)
  → 10.1 Mobile vs Step-1 (already enforced, confirmed)
  → 10.2 LPG name vs Aadhaar name (soft flag)
  → 10.3 Rent tenant name vs Step-1 name (HARD FAIL if fails)
  → 10.4 EB service address vs Step-1 address (soft fraud flag)
  [Any HARD FAIL] → Show specific error, block Continue
  ↓
All checks pass
  ↓
*** GATE 5 OPENS — Continue button enabled ***
  ↓
Update verified_profile.utility
  ↓
Mark Step-4 Status = VERIFIED
  ↓
Enable navigation to Step-5
```

---

## Section 14 — Output of Step-4

| Output | Value |
|---|---|
| Step-4 Status | `VERIFIED` |
| `verified_profile.utility` | Initialized and stored |
| `utility_bank_match_rate` | Float (0.0 – 1.0) |
| P2 ML features | 7 payment discipline features extracted |
| Step-5 Status | `UNLOCKED` |

### Cross-Step Dependencies Resolved by Step-4

- **Step-9 (Scoring):** `utility_on_time_ratio`, `utility_bank_match_rate`, `utility_payment_gap_flag`, `rent_verified_binary`, `wifi_verified_binary`, `ott_verified_binary` → used directly in P2 pillar computation

---

*GigCredit Validation & Verification Specification — Step-4 Utility Bill Verification*
*Version 1.0 | April 2026*
