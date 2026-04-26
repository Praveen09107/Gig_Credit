# ================================================================================
# GIGCREDIT — PHASE 2: DEV A DETAILED BACKEND SPECIFICATION
# Document 09 | Hours 4–12 | planning_new
# ================================================================================

## PURPOSE
Granular specification for every backend file Dev A must create in Phase 2.

---

## 1. FILE-BY-FILE IMPLEMENTATION ORDER

### Priority Order:
1. `config.py` + `connection.py` (infrastructure)
2. `seed_data.py` (demo data)
3. `otp_routes.py` (Step 1 — first API Dev B needs)
4. `gov_verification.py` (Steps 2, 5, 6, 7, 8)
5. `bank_verification.py` (Step 3)
6. `hmac_validator.py` (security middleware)
7. `report_routes.py` + `llm_service.py` (Step 10 — LLM)
8. `error_handlers.py` (global error handling)

---

## 2. SEED DATA SPECIFICATION

The seed data must contain records for the EXACT demo inputs. Dev A must:

1. Open each demo input image in `specification folders_new/Inputs/inputs hardcopies/`
2. Read the Aadhaar number, PAN number, etc. from the images
3. Create matching MongoDB records

### Collections to Seed:

#### aadhaar_db (1 record)
```python
{
    "aadhaar": "<read from demo Aadhaar card>",
    "name": "<read from demo Aadhaar card>",
    "dob": "<read from demo Aadhaar card>",
    "state": "<read from demo Aadhaar card>",
    "pin": "<read from demo Aadhaar back>",
    "status": "active"
}
```

#### pan_db (1 record)
```python
{
    "pan": "<read from demo PAN card>",
    "name": "<should match Aadhaar name>",
    "dob": "<should match Aadhaar DOB>",
    "pan_active": True,
    "itr_filed": True,
    "itr_years": [2022, 2023, 2024]
}
```

#### ifsc_db (1-2 records)
```python
{
    "ifsc": "<from demo bank statement>",
    "bank_name": "<from demo bank statement>",
    "branch_name": "<from demo bank statement>",
    "city": "Chennai",
    "state": "Tamil Nadu"
}
```

#### bank_accounts_db (1 record)
```python
{
    "account_number": "<from demo bank statement>",
    "ifsc": "<matching IFSC>",
    "account_holder": "<matching Aadhaar name>",
    "account_type": "Savings",
    "account_active": True
}
```

#### loan_accounts_db (1 record)
```python
{
    "account_number": "<matching>",
    "has_active_loans": True,
    "loans": [
        {"type": "Personal Loan", "emi_amount": 3500, "remaining_months": 18},
        {"type": "Two-Wheeler Loan", "emi_amount": 1800, "remaining_months": 6}
    ]
}
```

#### vehicle_rc_db (1 record — for Platform Worker demo)
```python
{
    "vehicle_number": "<from demo RC>",
    "owner_name": "<matching Aadhaar name>",
    "vehicle_class": "Motorcycle",
    "chassis_number": "<from demo RC>",
    "engine_number": "<from demo RC>",
    "registration_date": "2021-03-15",
    "rc_expiry": "2036-03-14",
    "fitness_expiry": "2027-03-14"
}
```

#### eshram_db (1 record)
```python
{
    "uan": "UAN123456789012",
    "name": "<matching>",
    "worker_category": "Gig Worker",
    "registration_date": "2022-08-10",
    "status": "registered"
}
```

#### pmsym_db (1 record)
```python
{
    "uan": "UAN123456789012",
    "status": "active",
    "months_contributed": 14,
    "last_contribution_date": "2026-03-01"
}
```

#### insurance_db (3 records)
```python
# Health Insurance
{
    "policy_number": "<from demo health insurance>",
    "policy_type": "health",
    "policy_holder": "<matching>",
    "insurer": "Star Health Insurance",
    "sum_insured": 500000,
    "premium_annual": 8500,
    "policy_start": "2024-11-01",
    "policy_expiry": "2025-10-31"
}
# Life Insurance
{
    "policy_number": "<from demo life insurance>",
    "policy_type": "life",
    "policy_holder": "<matching>",
    "insurer": "LIC",
    "sum_insured": 1000000,
    "premium_annual": 12000,
    "policy_start": "2023-01-01",
    "policy_expiry": "2043-01-01"
}
# Vehicle Insurance
{
    "policy_number": "<from demo vehicle insurance>",
    "policy_type": "vehicle",
    "policy_holder": "<matching>",
    "vehicle_number": "<matching RC>",
    "insurer": "Bajaj Allianz",
    "policy_expiry": "2026-10-15"
}
```

#### itr_db (1 record)
```python
{
    "pan": "<matching PAN>",
    "assessment_year": "2024-25",
    "itr_form": "ITR-4",
    "gross_income": 360000,
    "tax_paid": 0,
    "filing_date": "2024-07-31",
    "status": "filed"
}
```

### Seeding Script
```python
# backend/app/db/seed_data.py
async def seed_all():
    """Call this on first run or with --seed flag"""
    # Drop existing demo data
    for collection in [aadhaar_db, pan_db, ...]:
        await collection.delete_many({})
    
    # Insert demo records
    await aadhaar_db.insert_one(DEMO_AADHAAR)
    await pan_db.insert_one(DEMO_PAN)
    # ... all collections
    
    print("✅ Database seeded with demo data")
```

---

## 3. ENDPOINT IMPLEMENTATION PATTERN

Every verification endpoint follows this exact pattern:

```python
@router.post("/gov/aadhaar/verify")
async def verify_aadhaar(request: AadhaarVerifyRequest):
    # 1. Validate input format
    if not re.match(r'^\d{12}$', request.aadhaar):
        raise HTTPException(400, detail={"error": "invalid_format", "message": "Aadhaar must be 12 digits"})
    
    # 2. Query database
    record = await aadhaar_db.find_one({"aadhaar": request.aadhaar})
    
    # 3. Handle not found
    if not record:
        raise HTTPException(404, detail={"status": "invalid", "error": "not_found"})
    
    # 4. Return matching fields (NEVER return the raw record — select specific fields)
    return {
        "status": "valid",
        "name": record["name"],
        "dob": record["dob"],
        "state": record["state"]
    }
```

---

## 4. LLM SERVICE IMPLEMENTATION

```python
# backend/app/services/llm_service.py
from groq import Groq

class LLMService:
    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
    
    async def generate_report(self, payload: ReportRequest) -> dict:
        prompt = self._build_prompt(payload)
        
        try:
            response = self.client.chat.completions.create(
                model="llama3-70b-8192",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.4,
                max_tokens=600,
                response_format={"type": "json_object"}
            )
            result = json.loads(response.choices[0].message.content)
            return {
                "status": "success",
                "language": payload.language,
                "explanation": result["explanation"],
                "suggestions": result["suggestions"],
                "model_used": "llama3-70b-8192",
                "generated_at": datetime.utcnow().isoformat()
            }
        except Exception as e:
            # Fallback template
            return self._fallback_response(payload)
    
    def _fallback_response(self, payload):
        return {
            "status": "fallback",
            "language": "English",
            "explanation": f"Your credit score is {payload.credit_score} ({payload.grade})...",
            "suggestions": [
                "Reduce your EMI burden by paying off high-interest loans first.",
                "Get a health insurance policy to improve financial resilience.",
                "Save at least 10% of monthly income via RD or SIP."
            ]
        }
```

---

## 5. DEPLOYMENT TO RENDER

At the end of Phase 2 (or early Phase 3), Dev A should deploy:

1. Create `Dockerfile`:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install -r requirements.txt
COPY backend/ .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

2. Push to GitHub
3. Create Render Web Service pointing to the repo
4. Set environment variables on Render
5. Verify `/health` endpoint is accessible remotely
6. Share the Render URL with Dev B
