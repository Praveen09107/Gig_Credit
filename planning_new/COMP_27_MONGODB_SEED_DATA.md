# ================================================================================
# GIGCREDIT — MONGODB SEED DATA SPECIFICATION
# Document 27 | planning_new
# Owner: Dev A
# ================================================================================

## 1. PURPOSE

MongoDB serves as the "simulated government and bank verification database."
It contains pre-seeded records for the demo user that match the demo input documents.

---

## 2. COLLECTION SCHEMAS AND SEED DATA

### 2.1 otp_db
```json
{
  "mobile": "9876543210",
  "otp": "123456",
  "created_at": "2026-04-25T10:00:00Z",
  "expires_at": "2026-04-25T10:05:00Z",
  "verified": false
}
```
> Note: OTP is dynamically generated and stored. Seed is just initial state.

### 2.2 aadhaar_db
```json
{
  "aadhaar": "<FROM_DEMO_AADHAAR_CARD>",
  "name": "<FROM_DEMO_AADHAAR_CARD>",
  "dob": "<FROM_DEMO_AADHAAR_CARD_YYYY-MM-DD>",
  "state": "Tamil Nadu",
  "pin": "<FROM_DEMO_AADHAAR_BACK>",
  "status": "active"
}
```
> **ACTION**: Dev A must open the demo Aadhaar card image and extract the real values.

### 2.3 pan_db
```json
{
  "pan": "<FROM_DEMO_PAN_CARD>",
  "name": "<MUST_MATCH_AADHAAR_NAME>",
  "dob": "<MUST_MATCH_AADHAAR_DOB>",
  "pan_active": true,
  "itr_filed": true,
  "itr_years": [2022, 2023, 2024]
}
```

### 2.4 ifsc_db
```json
{
  "ifsc": "<FROM_DEMO_BANK_STATEMENT>",
  "bank_name": "<FROM_DEMO_BANK_STATEMENT>",
  "branch_name": "<FROM_DEMO_BANK_STATEMENT>",
  "city": "Chennai",
  "state": "Tamil Nadu"
}
```

### 2.5 bank_accounts_db
```json
{
  "account_number": "<FROM_DEMO_BANK_STATEMENT>",
  "ifsc": "<MATCHING_IFSC>",
  "account_holder": "<MATCHING_AADHAAR_NAME>",
  "account_type": "Savings",
  "account_active": true
}
```

### 2.6 loan_accounts_db
```json
{
  "account_number": "<MATCHING>",
  "has_active_loans": true,
  "loans": [
    {
      "type": "Personal Loan",
      "emi_amount": 3500,
      "remaining_months": 18
    },
    {
      "type": "Two-Wheeler Loan",
      "emi_amount": 1800,
      "remaining_months": 6
    }
  ]
}
```

### 2.7 vehicle_rc_db
```json
{
  "vehicle_number": "<FROM_DEMO_RC>",
  "owner_name": "<MATCHING_AADHAAR_NAME>",
  "vehicle_class": "Motorcycle",
  "chassis_number": "<FROM_DEMO_RC>",
  "engine_number": "<FROM_DEMO_RC>",
  "registration_date": "2021-03-15",
  "rc_expiry": "2036-03-14",
  "fitness_expiry": "2027-03-14"
}
```

### 2.8 eshram_db
```json
{
  "uan": "UAN123456789012",
  "name": "<MATCHING_AADHAAR_NAME>",
  "worker_category": "Gig Worker",
  "registration_date": "2022-08-10",
  "status": "registered"
}
```

### 2.9 pmsym_db
```json
{
  "uan": "UAN123456789012",
  "status": "active",
  "months_contributed": 14,
  "last_contribution_date": "2026-03-01"
}
```

### 2.10 insurance_db (3 records)
```json
[
  {
    "policy_number": "<FROM_DEMO_HEALTH_INSURANCE>",
    "policy_type": "health",
    "policy_holder": "<MATCHING>",
    "insurer": "Star Health Insurance",
    "sum_insured": 500000,
    "premium_annual": 8500,
    "policy_start": "2024-11-01",
    "policy_expiry": "2025-10-31"
  },
  {
    "policy_number": "<FROM_DEMO_LIFE_INSURANCE>",
    "policy_type": "life",
    "policy_holder": "<MATCHING>",
    "insurer": "LIC",
    "sum_insured": 1000000,
    "premium_annual": 12000,
    "policy_start": "2023-01-01",
    "policy_expiry": "2043-01-01"
  },
  {
    "policy_number": "<FROM_DEMO_VEHICLE_INSURANCE>",
    "policy_type": "vehicle",
    "policy_holder": "<MATCHING>",
    "vehicle_number": "<MATCHING_RC>",
    "insurer": "Bajaj Allianz",
    "policy_expiry": "2026-10-15"
  }
]
```

### 2.11 itr_db
```json
{
  "pan": "<MATCHING_PAN>",
  "assessment_year": "2024-25",
  "itr_form": "ITR-4",
  "gross_income": 360000,
  "tax_paid": 0,
  "filing_date": "2024-07-31",
  "status": "filed"
}
```

---

## 3. SEEDING SCRIPT

```python
# backend/app/db/seed_data.py

async def seed_database():
    """Seed MongoDB with demo verification data."""
    
    collections = {
        'aadhaar': [DEMO_AADHAAR],
        'pan': [DEMO_PAN],
        'ifsc': [DEMO_IFSC],
        'bank_accounts': [DEMO_BANK_ACCOUNT],
        'loan_accounts': [DEMO_LOAN_ACCOUNT],
        'vehicle_rc': [DEMO_VEHICLE_RC],
        'eshram': [DEMO_ESHRAM],
        'pmsym': [DEMO_PMSYM],
        'insurance': DEMO_INSURANCE_LIST,  # 3 records
        'itr': [DEMO_ITR],
    }
    
    for coll_name, records in collections.items():
        coll = db[coll_name]
        await coll.delete_many({})  # Clear existing
        if records:
            await coll.insert_many(records)
        print(f"  ✅ Seeded {coll_name}: {len(records)} records")
    
    print("\n✅ All collections seeded successfully!")

# Run: python -m app.db.seed_data
```

---

## 4. DATA CONSISTENCY RULES

> **CRITICAL**: ALL seed data must be internally consistent:

- Aadhaar name == PAN name == Bank holder name (exact or very close)
- Aadhaar DOB == PAN DOB
- Bank IFSC == IFSC in ifsc_db
- Bank account == account in bank_accounts_db
- Vehicle number in RC == vehicle number in vehicle insurance
- Policy holder names in insurance == Aadhaar name
- PAN in itr_db == PAN in pan_db

If ANY of these mismatches, cross-validation on the app side will flag warnings.
