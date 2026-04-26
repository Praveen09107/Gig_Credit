# ================================================================================
# GIGCREDIT — DEV A AGENT IMPLEMENTATION GUIDE
# FOR: GPT 5.3 Codex (or any AI coding agent)
# ROLE: Backend Developer + ML Engineer + AI Integration
# ================================================================================

## ⚠️ READ THIS ENTIRE DOCUMENT BEFORE WRITING ANY CODE

You are Dev A on a 2-person hackathon team building **GigCredit** — a privacy-first
alternative credit scoring app for Indian gig workers. You own the **backend server**,
**ML training pipeline**, and **AI report generation**. Your teammate (Dev B) owns the
Flutter frontend app. You two work on COMPLETELY SEPARATE codebases that communicate
only through defined API contracts.

---

## 1. WHAT IS GIGCREDIT?

GigCredit helps gig workers (delivery drivers, vendors, freelancers, tradespeople)
who have NO traditional credit score (no CIBIL) to generate an alternative credit
score using real financial behavior data like bank statements, utility bills, work
proof, and government scheme registrations.

**How it works:**
1. User enters personal info + uploads documents on the Flutter app (Dev B's work)
2. App extracts data via OCR and sends identity numbers to YOUR backend for verification
3. YOUR backend checks the numbers against a MongoDB database and returns valid/invalid
4. App computes a credit score ON-DEVICE using ML models YOU export to Dart
5. App sends the score + SHAP factors to YOUR backend's LLM endpoint
6. YOUR backend calls Groq (LLaMA 3 70B) to generate a plain-language explanation
7. App displays the score, explanation, and loan offers to the user

**This is a DEMO for a hackathon.** The MongoDB "verification database" contains
pre-seeded demo data. The app processes pre-defined demo input documents. The judges
should believe it works for real — and most of the pipeline IS real.

---

## 2. WHAT YOU OWN (Your Directories)

```
YOU OWN AND WRITE CODE IN:
├── backend/          ← FastAPI server (Python)
├── ml_pipeline/      ← ML training + model export (Python)
├── contracts/        ← Shared API schemas (JSON — you CREATE, Dev B READS)
├── demo_data/        ← Demo inputs + expected outputs (shared)
├── scripts/          ← Utility scripts (shared)

YOU NEVER TOUCH:
├── app/              ← Flutter app (Dev B's territory)
```

**CRITICAL RULE**: Never create, edit, or delete any file inside `app/`. That is
Dev B's exclusive domain. If you need Dev B to change something, update the contract
or leave instructions in `contracts/decisions.md`.

---

## 3. YOUR TECH STACK

| Component | Technology | Version |
|-----------|-----------|---------|
| Web Framework | FastAPI | Latest |
| Database | MongoDB (via Motor async driver) | Atlas free tier |
| LLM API | Groq (llama3-70b-8192) | Latest |
| ML Training | XGBoost, scikit-learn | Latest |
| Model Export | m2cgen (Python → Dart) | Latest |
| SHAP | shap (TreeExplainer) | Latest |
| Deployment | Render (free tier) | — |
| Python | 3.11+ | — |

---

## 4. IMPLEMENTATION ORDER (Follow This Exactly)

### STEP 1: Create backend/requirements.txt
```
fastapi>=0.104.0
uvicorn>=0.24.0
motor>=3.3.0
pymongo>=4.6.0
python-dotenv>=1.0.0
pydantic>=2.5.0
pydantic-settings>=2.1.0
httpx>=0.25.0
groq>=0.4.0
python-jose>=3.3.0
passlib>=1.7.4
slowapi>=0.1.9
pytest>=7.4.0
pytest-asyncio>=0.21.0
```

### STEP 2: Create backend/app/config.py
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGODB_URI: str = "mongodb://localhost:27017"
    DB_NAME: str = "gigcredit"
    GROQ_API_KEY: str = ""
    HMAC_SECRET: str = "gigcredit-demo-hmac-secret-2026"
    SERVER_API_KEY: str = "gigcredit-demo-api-key-2026"
    ENABLE_HMAC: bool = False
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### STEP 3: Create backend/app/db/connection.py
```python
from motor.motor_asyncio import AsyncIOMotorClient
from app.config import settings

client = None
db = None

async def connect_db():
    global client, db
    client = AsyncIOMotorClient(settings.MONGODB_URI)
    db = client[settings.DB_NAME]

async def close_db():
    global client
    if client:
        client.close()

def get_db():
    return db
```

### STEP 4: Create backend/app/main.py
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.db.connection import connect_db, close_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()

app = FastAPI(title="GigCredit API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "gigcredit-api", "version": "1.0.0"}

# Import and include routers AFTER creating them
# from app.api import otp_routes, gov_verification, bank_verification, report_routes
# app.include_router(otp_routes.router, prefix="/auth", tags=["auth"])
# app.include_router(gov_verification.router, prefix="/gov", tags=["government"])
# app.include_router(bank_verification.router, prefix="/bank", tags=["bank"])
# app.include_router(report_routes.router, prefix="/api", tags=["report"])
```

### STEP 5: Create ALL 13 API Endpoints

You must implement these EXACT endpoints with these EXACT request/response shapes.
Dev B's app is coded against these contracts. ANY deviation will break integration.

#### 5.1 POST /auth/otp/send
```
Request:  { "mobile": "9876543210" }
Response: { "status": "sent", "expires_in_seconds": 300, "otp": "123456" }
```
Note: For demo, OTP is always "123456" and returned in the response body.

#### 5.2 POST /auth/otp/verify
```
Request:  { "mobile": "9876543210", "otp": "123456" }
Response: { "status": "verified", "mobile_verified": true }
```

#### 5.3 POST /gov/aadhaar/verify
```
Request:  { "aadhaar": "123456789012" }
Response: { "status": "valid", "name": "...", "dob": "YYYY-MM-DD", "state": "..." }
Error 404: { "status": "invalid", "error": "not_found" }
Error 400: { "error": "invalid_format", "message": "Aadhaar must be 12 digits" }
```

#### 5.4 POST /gov/pan/verify
```
Request:  { "pan": "ABCDE1234F" }
Response: { "status": "valid", "name": "...", "dob": "...", "pan_active": true, "itr_filed": true, "itr_years": [2022,2023,2024] }
```

#### 5.5 POST /bank/ifsc/verify
```
Request:  { "ifsc": "HDFC0001234" }
Response: { "status": "valid", "bank_name": "...", "branch_name": "...", "city": "...", "state": "..." }
```

#### 5.6 POST /bank/account/verify
```
Request:  { "account_number": "1234567890", "ifsc": "HDFC0001234" }
Response: { "status": "valid", "account_holder": "...", "account_type": "Savings", "account_active": true }
```

#### 5.7 POST /bank/loan/check
```
Request:  { "account_number": "1234567890" }
Response: { "has_active_loans": true, "loan_count": 2, "loans": [{"type": "Personal Loan", "emi_amount": 3500, "remaining_months": 18}, ...] }
```

#### 5.8 POST /gov/vehicle/rc/verify
```
Request:  { "vehicle_number": "TN09AB1234" }
Response: { "status": "valid", "owner_name": "...", "vehicle_class": "Motorcycle", "chassis_number": "...", "engine_number": "...", "registration_date": "...", "rc_expiry": "...", "fitness_expiry": "..." }
```

#### 5.9 POST /gov/eshram/verify
```
Request:  { "uan": "UAN123456789012" }
Response: { "status": "registered", "name": "...", "worker_category": "Gig Worker", "registration_date": "..." }
```

#### 5.10 POST /gov/pmsym/verify
```
Request:  { "uan": "UAN123456789012" }
Response: { "status": "active", "months_contributed": 14, "last_contribution_date": "..." }
```

#### 5.11 POST /gov/insurance/policy/verify
```
Request:  { "policy_number": "HLT2024112345", "policy_type": "health" }
Response (health): { "status": "active", "policy_holder": "...", "insurer": "Star Health Insurance", "sum_insured": 500000, "premium_annual": 8500, "policy_start": "...", "policy_expiry": "..." }
Response (vehicle): { "status": "active", "policy_holder": "...", "vehicle_number": "...", "insurer": "Bajaj Allianz", "policy_expiry": "..." }
```

#### 5.12 POST /gov/income-tax/itr/verify
```
Request:  { "pan": "ABCDE1234F", "assessment_year": "2024-25" }
Response: { "status": "filed", "assessment_year": "2024-25", "itr_form": "ITR-4", "gross_income": 360000, "tax_paid": 0, "filing_date": "..." }
```

#### 5.13 POST /api/report/generate (LLM Report)
```
Request: {
  "credit_score": 682, "grade": "B", "risk_level": "Medium",
  "work_type": "platform_worker", "language": "Tamil",
  "pillar_scores": { "income_stability": 72, ... },
  "positive_factors": [{ "feature_label": "...", "pillar": "...", "impact": 15 }, ...],
  "negative_factors": [{ "feature_label": "...", "pillar": "...", "impact": -18 }, ...],
  "confidence_level": "High"
}
Response: {
  "status": "success", "language": "Tamil",
  "explanation": "உங்கள் கிரெடிட் ஸ்கோர் 682...",
  "suggestions": ["suggestion 1", "suggestion 2", "suggestion 3"],
  "model_used": "llama3-70b-8192", "generated_at": "..."
}
Fallback Response: {
  "status": "fallback", "language": "English",
  "explanation": "Your credit score is 682...",
  "suggestions": ["...", "...", "..."]
}
```

### STEP 6: Seed MongoDB with Demo Data

Create `backend/app/db/seed_data.py`. You MUST open the demo input images in
`specification folders_new/Inputs/inputs hardcopies/` to extract the REAL identity
numbers from the demo documents (Aadhaar number, PAN number, etc.) and seed those
exact values into MongoDB.

If you cannot read the images, use these placeholder values and document them in
`contracts/decisions.md` so Dev B knows what to enter during the demo:

```python
DEMO_AADHAAR = {"aadhaar": "765432101234", "name": "Praveen Kumar", "dob": "2006-11-16", "state": "Tamil Nadu", "status": "active"}
DEMO_PAN = {"pan": "ABCDE1234F", "name": "Praveen Kumar", "dob": "2006-11-16", "pan_active": True, "itr_filed": True, "itr_years": [2022, 2023, 2024]}
# ... seed ALL 11 collections (see planning_new/COMP_27_MONGODB_SEED_DATA.md)
```

**CRITICAL**: All names MUST match across collections. Aadhaar name = PAN name =
Bank holder name = Insurance policy holder name. If they don't match, cross-validation
on the app side will flag warnings.

### STEP 7: Implement LLM Service

Create `backend/app/services/llm_service.py`:
- Call Groq API with llama3-70b-8192
- Use temperature=0.4, max_tokens=600
- Request JSON response format
- Parse the JSON and return explanation + suggestions
- If Groq fails (timeout, rate limit, bad API key): return a fallback template
- Supported languages: English, Tamil, Hindi, Telugu, Kannada

The prompt template should ask the LLM to:
1. Explain the credit score in simple, understandable language
2. Mention the user's top strengths
3. Mention areas to improve
4. Give 3 specific, actionable improvement suggestions
5. Write in the requested language

### STEP 8: Deploy to Render

1. Create `backend/Dockerfile`:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

2. Push to GitHub
3. Create Render Web Service → connect to repo
4. Set environment variables (MONGODB_URI, GROQ_API_KEY, HMAC_SECRET, SERVER_API_KEY)
5. Verify: `curl https://YOUR-URL.onrender.com/health`
6. Share the URL with Dev B (write it in `contracts/decisions.md`)

### STEP 9: ML Pipeline — Train Scoring Models

Create `ml_pipeline/requirements.txt`:
```
numpy>=1.24
pandas>=2.0
scikit-learn>=1.3
xgboost>=2.0
shap>=0.42
m2cgen>=0.10
```

**Pipeline steps:**

1. **Generate synthetic data** (`ml_pipeline/data/generator/synthetic_generator.py`):
   - 15,000 profiles (or 5,000 if time is short)
   - 4 work types: platform_worker, vendor, tradesperson, freelancer
   - 95 features per profile (see planning_new/COMP_18_FEATURE_ENGINEERING_95_FEATURES.md)
   - Features must be correlated realistically
   - Target: composite credit quality 0.0-1.0

2. **Train pillar models** (`ml_pipeline/training/train_pillars.py`):
   - P1 Income Stability: XGBoost on features 0-12 (13 features)
   - P2 Payment Discipline: XGBoost on features 13-27 (15 features)
   - P3 Debt Management: XGBoost on features 28-36 (9 features)
   - P4 Savings Behaviour: XGBoost on features 37-48 (12 features)
   - P6 Financial Resilience: RandomForest on features 67-77 (11 features)

3. **Write scorecard functions** for P5 and P7 (deterministic, not ML):
   - P5 Work and Identity: Weighted sum of features 49-66
   - P7 Social Accountability: Weighted sum of features 78-94
   - Write these directly as Dart functions

4. **Train meta-learner** (`ml_pipeline/training/train_meta_learner.py`):
   - Logistic Regression
   - Input: 19 features = [7 pillar scores, 4 work-type one-hot, 8 interaction terms]
   - Output: probability → score = round(probability × 600) + 300

5. **Export to Dart** via m2cgen (`ml_pipeline/export/export_m2cgen.py`):
   - `m2cgen.export_to_dart(model, function_name='scoreP1')` for each model
   - Output goes to `ml_pipeline/output/dart_exports/`

6. **Generate configs**:
   - `ml_pipeline/output/json_configs/meta_coefficients.json` — LR weights + intercept
   - `ml_pipeline/output/json_configs/shap_lookup.json` — binned SHAP values for all 95 features
   - `ml_pipeline/output/json_configs/feature_means.json` — fallback values per feature

7. **Generate golden test** (`ml_pipeline/output/golden/golden_inference.json`):
   - 5 test profiles with known feature vectors
   - For each: Python pillar scores, meta-learner input, logit, probability, final score
   - Dev B will run these through Dart scorers and compare — must match within 1e-5

### STEP 10: Commit Handoff Artifacts

After ML pipeline completes, the `ml_pipeline/output/` folder should contain:
```
ml_pipeline/output/
├── dart_exports/
│   ├── p1_scorer.dart          ← XGBoost → Dart (m2cgen)
│   ├── p2_scorer.dart          ← XGBoost → Dart (m2cgen)
│   ├── p3_scorer.dart          ← XGBoost → Dart (m2cgen)
│   ├── p4_scorer.dart          ← XGBoost → Dart (m2cgen)
│   ├── p6_scorer.dart          ← RandomForest → Dart (m2cgen)
│   ├── scorecard_p5.dart       ← Hand-written Dart scorecard
│   ├── scorecard_p7.dart       ← Hand-written Dart scorecard
│   └── scoring_constants.dart  ← Meta-learner LR coefficients as Dart constants
├── json_configs/
│   ├── shap_lookup.json        ← Binned SHAP values for 95 features
│   ├── meta_coefficients.json  ← {"weights": [...], "intercept": ...}
│   └── feature_means.json      ← Fallback values per feature
└── golden/
    └── golden_inference.json   ← 5 test cases for parity validation
```

Commit all of these. Dev B will copy them into the Flutter app.

---

## 5. INPUT VALIDATION RULES

Apply these regex validations in your endpoints:

| Field | Regex | Example |
|-------|-------|---------|
| Aadhaar | `^\d{12}$` (cannot start with 0 or 1) | 765432101234 |
| PAN | `^[A-Z]{5}[0-9]{4}[A-Z]$` | ABCDE1234F |
| IFSC | `^[A-Z]{4}0[A-Z0-9]{6}$` | HDFC0001234 |
| Account | `^\d{9,18}$` | 1234567890123 |
| Mobile | `^[6-9]\d{9}$` | 9876543210 |
| Vehicle | `^[A-Z]{2}\d{2}[A-Z]{1,3}\d{1,4}$` | TN09AB1234 |
| UAN | Must start with "UAN", 15 chars total | UAN123456789012 |

---

## 6. ENDPOINT IMPLEMENTATION PATTERN

Every verification endpoint follows this EXACT pattern:

```python
from fastapi import APIRouter, HTTPException
from app.db.connection import get_db
import re

router = APIRouter()

@router.post("/aadhaar/verify")
async def verify_aadhaar(request: AadhaarVerifyRequest):
    # 1. Validate format
    if not re.match(r'^\d{12}$', request.aadhaar):
        raise HTTPException(400, detail={"error": "invalid_format", "message": "Aadhaar must be 12 digits"})
    
    # 2. Query MongoDB
    db = get_db()
    record = await db.aadhaar.find_one({"aadhaar": request.aadhaar})
    
    # 3. Not found
    if not record:
        raise HTTPException(404, detail={"status": "invalid", "error": "not_found"})
    
    # 4. Return ONLY the fields defined in the contract
    return {
        "status": "valid",
        "name": record["name"],
        "dob": record["dob"],
        "state": record["state"]
    }
```

---

## 7. ERROR RESPONSE FORMAT

Every error MUST follow this format:
```json
{ "error": "error_code", "message": "Human-readable description", "timestamp": "ISO-8601" }
```

---

## 8. HMAC AUTHENTICATION

The HMAC middleware validates requests from the Flutter app:
```
message = "{device_id}:{unix_timestamp}:{sha256(request_body)}"
signature = HMAC-SHA256(message, HMAC_SECRET)
```

Headers checked: X-Api-Key, X-Device-Id, X-Timestamp, X-Signature

**For initial development**: Set `ENABLE_HMAC=false` in .env to skip HMAC validation.
Enable it when Dev B has implemented the HMAC signer in Dart and is ready to test.

---

## 9. GROQ PROMPT TEMPLATE

```python
PROMPT = """You are a financial advisor for Indian gig workers.

A gig worker has been assessed using alternative financial data.
Credit Score: {score}/900 (Grade: {grade}, Risk: {risk})
Work Type: {work_type}

Strongest financial behaviors:
1. {pos_1} (Impact: +{pos_1_impact})
2. {pos_2} (Impact: +{pos_2_impact})
3. {pos_3} (Impact: +{pos_3_impact})

Areas needing improvement:
1. {neg_1} (Impact: {neg_1_impact})
2. {neg_2} (Impact: {neg_2_impact})
3. {neg_3} (Impact: {neg_3_impact})

Write your response in {language} language.

Respond in JSON:
{{"explanation": "4-5 sentences in simple language", "suggestions": ["action 1", "action 2", "action 3"]}}"""
```

---

## 10. FILES YOU MUST CREATE (Checklist)

```
backend/
├── requirements.txt                    □
├── Dockerfile                          □
├── .env.example                        □ (already created)
├── render.yaml                         □
├── app/
│   ├── __init__.py                     □
│   ├── main.py                         □
│   ├── config.py                       □
│   ├── auth/
│   │   ├── __init__.py                 □
│   │   ├── hmac_validator.py           □
│   │   └── rate_limiter.py             □
│   ├── api/
│   │   ├── __init__.py                 □
│   │   ├── otp_routes.py              □
│   │   ├── gov_verification.py         □
│   │   ├── bank_verification.py        □
│   │   ├── insurance_verification.py   □
│   │   └── report_routes.py            □
│   ├── services/
│   │   ├── __init__.py                 □
│   │   ├── llm_service.py              □
│   │   └── prompt_builder.py           □
│   ├── schemas/
│   │   ├── __init__.py                 □
│   │   ├── auth_schemas.py             □
│   │   ├── verification_schemas.py     □
│   │   ├── report_schemas.py           □
│   │   └── common_schemas.py           □
│   ├── db/
│   │   ├── __init__.py                 □
│   │   ├── connection.py               □
│   │   └── seed_data.py                □
│   └── utils/
│       ├── __init__.py                 □
│       ├── logger.py                   □
│       └── error_handlers.py           □
├── tests/
│   ├── test_health.py                  □
│   ├── test_auth.py                    □
│   └── test_verification.py            □

contracts/
├── api_contract.json                   □
├── verified_profile_contract.json      □
├── feature_vector_contract.json        □
├── score_output_contract.json          □
├── report_payload_contract.json        □
└── decisions.md                        □

ml_pipeline/
├── requirements.txt                    □
├── data/generator/synthetic_generator.py  □
├── training/train_pillars.py           □
├── training/train_meta_learner.py      □
├── export/export_m2cgen.py             □
├── export/generate_shap.py             □
├── export/generate_golden.py           □
├── output/dart_exports/*.dart          □ (7-8 files)
├── output/json_configs/*.json          □ (3 files)
└── output/golden/golden_inference.json □
```

---

## 11. WHAT SUCCESS LOOKS LIKE

When you are DONE, the following must be true:

1. `curl https://YOUR-RENDER-URL/health` → `{"status": "ok"}`
2. ALL 13 endpoints respond correctly with demo data
3. MongoDB Atlas has all 11 collections seeded
4. LLM report endpoint returns explanation in English/Tamil/Hindi
5. Fallback works if Groq is unavailable
6. `ml_pipeline/output/` contains all .dart + .json + golden files
7. All contracts/*.json files are committed
8. Dev B can call your API from the Flutter app without errors

---

## 12. REFERENCE DOCUMENTS

For deeper details, read these files in the project:
- `planning_new/05_DATA_CONTRACTS_AND_API_SCHEMAS.md` — full contract specs
- `planning_new/PHASE_2_09_DEV_A_BACKEND_DETAILED.md` — backend implementation details
- `planning_new/COMP_19_BACKEND_VERIFICATION_API.md` — endpoint registry
- `planning_new/COMP_20_LLM_REPORT_PIPELINE.md` — Groq integration details
- `planning_new/COMP_23_ML_TRAINING_PIPELINE.md` — ML training specs
- `planning_new/COMP_27_MONGODB_SEED_DATA.md` — seed data specs
- `planning_new/COMP_18_FEATURE_ENGINEERING_95_FEATURES.md` — all 95 features
- `specification folders_new/GIGCREDIT-BACKEND-SERVER-SPECIFICATION.txt` — original spec
- `specification folders_new/Feature engineering (1).txt` — feature definitions
