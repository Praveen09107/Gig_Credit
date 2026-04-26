# ================================================================================
# GIGCREDIT — DATA CONTRACTS AND API SCHEMAS
# Document 05 | Version 2.0 | planning_new
# BOTH DEVS MUST READ AND AGREE ON THIS BEFORE WRITING ANY CODE
# ================================================================================

## 1. PURPOSE

This document defines EVERY data contract between Dev A (backend) and Dev B (frontend).
Both devs code ONLY against these contracts. If a contract needs to change, both devs
must agree and update this document first.

---

## 2. API CONTRACT — VERIFICATION ENDPOINTS

### 2.1 Common Headers (ALL Requests)

```
X-Api-Key: <SERVER_API_KEY>
X-Device-Id: <SHA256 of device fingerprint>
X-Timestamp: <Unix timestamp>
X-Signature: <HMAC-SHA256 signature>
Content-Type: application/json
```

### 2.2 Common Error Response

```json
{
  "error": "error_code",
  "message": "Human-readable description",
  "timestamp": "2026-04-25T10:00:00Z"
}
```

Error codes: `invalid_format`, `not_found`, `invalid_otp`, `otp_expired`,
`too_many_requests`, `unauthorized`, `server_error`

---

### 2.3 POST /auth/otp/send

**Request:**
```json
{ "mobile": "9876543210" }
```

**Response (200):**
```json
{
  "status": "sent",
  "expires_in_seconds": 300,
  "otp": "123456"
}
```
> NOTE: `otp` field included in response for DEMO ONLY. Remove in production.

---

### 2.4 POST /auth/otp/verify

**Request:**
```json
{ "mobile": "9876543210", "otp": "123456" }
```

**Response (200):**
```json
{ "status": "verified", "mobile_verified": true }
```

---

### 2.5 POST /gov/aadhaar/verify

**Request:**
```json
{ "aadhaar": "123456789012" }
```

**Response (200):**
```json
{
  "status": "valid",
  "name": "Ravi Kumar",
  "dob": "1997-06-12",
  "state": "Tamil Nadu"
}
```

**Response (404):**
```json
{ "status": "invalid", "error": "not_found" }
```

---

### 2.6 POST /gov/pan/verify

**Request:**
```json
{ "pan": "ABCDE1234F" }
```

**Response (200):**
```json
{
  "status": "valid",
  "name": "Ravi Kumar",
  "dob": "1997-06-12",
  "pan_active": true,
  "itr_filed": true,
  "itr_years": [2022, 2023, 2024]
}
```

---

### 2.7 POST /bank/ifsc/verify

**Request:**
```json
{ "ifsc": "HDFC0001234" }
```

**Response (200):**
```json
{
  "status": "valid",
  "bank_name": "HDFC Bank",
  "branch_name": "Anna Nagar Chennai",
  "city": "Chennai",
  "state": "Tamil Nadu"
}
```

---

### 2.8 POST /bank/account/verify

**Request:**
```json
{ "account_number": "1234567890", "ifsc": "HDFC0001234" }
```

**Response (200):**
```json
{
  "status": "valid",
  "account_holder": "Ravi Kumar",
  "account_type": "Savings",
  "account_active": true
}
```

---

### 2.9 POST /bank/loan/check

**Request:**
```json
{ "account_number": "1234567890" }
```

**Response (200):**
```json
{
  "has_active_loans": true,
  "loan_count": 2,
  "loans": [
    { "type": "Personal Loan", "emi_amount": 3500, "remaining_months": 18 },
    { "type": "Two-Wheeler Loan", "emi_amount": 1800, "remaining_months": 6 }
  ]
}
```

---

### 2.10 POST /gov/vehicle/rc/verify

**Request:**
```json
{ "vehicle_number": "TN09AB1234" }
```

**Response (200):**
```json
{
  "status": "valid",
  "owner_name": "Ravi Kumar",
  "vehicle_class": "Motorcycle",
  "chassis_number": "ME4JC092XRM123456",
  "engine_number": "JC09E2123456",
  "registration_date": "2021-03-15",
  "rc_expiry": "2036-03-14",
  "fitness_expiry": "2027-03-14"
}
```

---

### 2.11 POST /gov/eshram/verify

**Request:**
```json
{ "uan": "UAN123456789012" }
```

**Response (200):**
```json
{
  "status": "registered",
  "name": "Ravi Kumar",
  "worker_category": "Gig Worker",
  "registration_date": "2022-08-10"
}
```

---

### 2.12 POST /gov/pmsym/verify

**Request:**
```json
{ "uan": "UAN123456789012" }
```

**Response (200):**
```json
{
  "status": "active",
  "months_contributed": 14,
  "last_contribution_date": "2026-03-01"
}
```

---

### 2.13 POST /gov/insurance/policy/verify

**Request:**
```json
{
  "policy_number": "HLT2024112345",
  "policy_type": "health"
}
```

**Response (200 — health):**
```json
{
  "status": "active",
  "policy_holder": "Ravi Kumar",
  "insurer": "Star Health Insurance",
  "sum_insured": 500000,
  "premium_annual": 8500,
  "policy_start": "2024-11-01",
  "policy_expiry": "2025-10-31"
}
```

**Response (200 — vehicle):**
```json
{
  "status": "active",
  "policy_holder": "Ravi Kumar",
  "vehicle_number": "TN09AB1234",
  "insurer": "Bajaj Allianz",
  "policy_expiry": "2026-10-15"
}
```

---

### 2.14 POST /gov/income-tax/itr/verify

**Request:**
```json
{ "pan": "ABCDE1234F", "assessment_year": "2024-25" }
```

**Response (200):**
```json
{
  "status": "filed",
  "assessment_year": "2024-25",
  "itr_form": "ITR-4",
  "gross_income": 360000,
  "tax_paid": 0,
  "filing_date": "2024-07-31"
}
```

---

### 2.15 POST /api/report/generate (LLM Report)

**Request:**
```json
{
  "credit_score": 682,
  "grade": "B",
  "risk_level": "Medium",
  "work_type": "platform_worker",
  "language": "Tamil",
  "pillar_scores": {
    "income_stability": 72,
    "payment_discipline": 68,
    "debt_management": 55,
    "savings_behaviour": 61,
    "work_identity": 78,
    "financial_resilience": 45,
    "social_accountability": 60
  },
  "positive_factors": [
    { "feature_label": "Consistent monthly income", "pillar": "Income Stability", "impact": 15 },
    { "feature_label": "Utility bills paid on time", "pillar": "Payment Discipline", "impact": 12 },
    { "feature_label": "Bank balance growing steadily", "pillar": "Savings Behaviour", "impact": 9 }
  ],
  "negative_factors": [
    { "feature_label": "EMI payments high relative to income", "pillar": "Debt Management", "impact": -18 },
    { "feature_label": "No active health insurance", "pillar": "Financial Resilience", "impact": -10 },
    { "feature_label": "Low monthly savings rate", "pillar": "Savings Behaviour", "impact": -7 }
  ],
  "confidence_level": "High"
}
```

**Response (200):**
```json
{
  "status": "success",
  "language": "Tamil",
  "explanation": "உங்கள் கிரெடிட் ஸ்கோர் 682...",
  "suggestions": [
    "EMI குறைக்க முயற்சி செய்யுங்கள்...",
    "உடல்நல காப்பீடு எடுங்கள்...",
    "மாதாந்திர சேமிப்பை 10% உயர்த்துங்கள்..."
  ],
  "model_used": "llama3-70b-8192",
  "generated_at": "2026-04-25T16:43:00Z"
}
```

**Response (fallback):**
```json
{
  "status": "fallback",
  "language": "English",
  "explanation": "Your credit score is 682 (Grade B, Medium Risk)...",
  "suggestions": ["Reduce EMI burden...", "Get health insurance...", "Increase savings..."]
}
```

---

## 3. VERIFIED PROFILE CONTRACT

This is the central data object built on-device across all 9 steps:

```json
{
  "personal": {
    "full_name": "string",
    "dob": "DD/MM/YYYY",
    "mobile": "string (10 digits)",
    "mobile_verified": true,
    "current_address": "string",
    "permanent_address": "string",
    "state": "string"
  },
  "professional": {
    "work_type": "platform_worker | vendor | tradesperson | freelancer",
    "self_declared_income": 18000,
    "years_in_profession": 5,
    "dependents": 2,
    "vehicle_ownership": true,
    "secondary_income": null
  },
  "identity": {
    "aadhaar_number": "string",
    "aadhaar_verified": true,
    "aadhaar_name": "string",
    "pan_number": "string",
    "pan_verified": true,
    "pan_name": "string",
    "face_match_score": 0.95,
    "itr_filed": true,
    "itr_years": [2022, 2023, 2024]
  },
  "bank": {
    "primary": {
      "bank_name": "string",
      "account_number": "string",
      "ifsc": "string",
      "ifsc_verified": true,
      "account_verified": true,
      "transactions": [],
      "monthly_credits": [18000, 19500, 17800, 20000, 18500, 19000],
      "monthly_debits": [15000, 14500, 16000, 15500, 14000, 15200],
      "avg_monthly_balance": 25000,
      "auto_detected_emis": []
    },
    "secondary": null,
    "upi_data": null,
    "active_loans": []
  },
  "utility": {
    "electricity": { "consumer_number": "string", "bills": [], "on_time_count": 5 },
    "lpg": { "consumer_number": "string", "bills": [], "on_time_count": 6 },
    "mobile": { "mobile_number": "string", "bills": [], "on_time_count": 6 },
    "rent": null,
    "wifi": null
  },
  "work_proof": {
    "vehicle_number": "string",
    "rc_verified": true,
    "dl_verified": true,
    "platform_earnings": [],
    "svanidhi_verified": false,
    "trade_licence_verified": false,
    "freelance_profile_verified": false
  },
  "gov_schemes": {
    "eshram_registered": true,
    "eshram_uan": "string",
    "pmsym_active": true,
    "pmsym_months": 14,
    "mudra_registered": false,
    "shg_member": false
  },
  "insurance": {
    "health": { "active": true, "sum_insured": 500000, "premium": 8500 },
    "vehicle": { "active": true, "policy_expiry": "2026-10-15" },
    "life": { "active": false }
  },
  "tax": {
    "itr_filed": true,
    "assessment_year": "2024-25",
    "gross_income": 360000,
    "gst_registered": false,
    "gst_returns_filed": 0
  },
  "emi_loans": {
    "has_active_loans": true,
    "declared_loans": [
      { "lender": "HDFC Bank", "emi_amount": 3500, "prev_debit": "2026-02-05", "latest_debit": "2026-03-05" },
      { "lender": "Bajaj Finance", "emi_amount": 1800, "prev_debit": "2026-02-07", "latest_debit": "2026-03-07" }
    ],
    "auto_vs_declared_match": true
  },
  "step_status": {
    "step_1": "VERIFIED",
    "step_2": "VERIFIED",
    "step_3": "VERIFIED",
    "step_4": "VERIFIED",
    "step_5": "VERIFIED",
    "step_6": "VERIFIED",
    "step_7": "VERIFIED",
    "step_8": "VERIFIED",
    "step_9": "VERIFIED"
  }
}
```

---

## 4. FEATURE VECTOR CONTRACT

95 features, all Float32, all normalized to [0.0, 1.0]:

| Index  | Pillar | Feature Name                        | Source Step |
|--------|--------|-------------------------------------|------------|
| 0-12   | P1     | Income Stability (13 features)      | Steps 1,3  |
| 13-27  | P2     | Payment Discipline (15 features)    | Steps 3,4  |
| 28-36  | P3     | Debt Management (9 features)        | Steps 3,9  |
| 37-48  | P4     | Savings Behaviour (12 features)     | Step 3     |
| 49-66  | P5     | Work and Identity (18 features)     | Steps 1,2,5|
| 67-77  | P6     | Financial Resilience (11 features)  | Steps 6,7,8|
| 78-94  | P7     | Social Accountability (17 features) | Steps 5,6  |

**Rules:**
- NaN / Infinity → replaced with 0.40 (or pillar-specific fallback)
- All values clamped to [0.0, 1.0]
- Feature order is FIXED — never reorder
- Full feature definitions in `Feature engineering (1).txt`

---

## 5. SCORE OUTPUT CONTRACT

```json
{
  "final_score": 682,
  "grade": "B",
  "risk_band": "Medium",
  "pillar_scores": {
    "p1_income_stability": 0.72,
    "p2_payment_discipline": 0.68,
    "p3_debt_management": 0.55,
    "p4_savings_behaviour": 0.61,
    "p5_work_identity": 0.78,
    "p6_financial_resilience": 0.45,
    "p7_social_accountability": 0.60
  },
  "pillar_confidence": {
    "p1": 0.90,
    "p2": 0.85,
    "p3": 0.80,
    "p4": 0.75,
    "p5": 0.92,
    "p6": 0.60,
    "p7": 0.70
  },
  "meta_learner_input": [0.72, 0.68, 0.55, 0.61, 0.78, 0.45, 0.60, 1, 0, 0, 0, 0.72, 0.68, 0, 0, 0, 0, 0, 0],
  "shap_top_positive": [],
  "shap_top_negative": [],
  "scoring_time_ms": 15,
  "work_type": "platform_worker"
}
```
