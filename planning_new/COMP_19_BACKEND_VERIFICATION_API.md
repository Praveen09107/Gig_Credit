# ================================================================================
# GIGCREDIT — COMPONENT: BACKEND VERIFICATION API
# Document 19 | planning_new
# Owner: Dev A
# ================================================================================

## 1. ENDPOINT REGISTRY

| # | Method | Path                           | Step | Collection    | Fields Returned          |
|---|--------|-------------------------------|------|---------------|--------------------------|
| 1 | POST   | /auth/otp/send                | 1    | otp_db        | status, expires, otp     |
| 2 | POST   | /auth/otp/verify              | 1    | otp_db        | status, mobile_verified  |
| 3 | POST   | /gov/aadhaar/verify           | 2    | aadhaar_db    | name, dob, state         |
| 4 | POST   | /gov/pan/verify               | 2    | pan_db        | name, dob, pan_active    |
| 5 | POST   | /bank/ifsc/verify             | 3    | ifsc_db       | bank_name, branch, city  |
| 6 | POST   | /bank/account/verify          | 3    | bank_acct_db  | holder, type, active     |
| 7 | POST   | /bank/loan/check              | 3    | loan_acct_db  | has_loans, loans[]       |
| 8 | POST   | /gov/vehicle/rc/verify        | 5    | vehicle_rc_db | owner, class, expiry     |
| 9 | POST   | /gov/eshram/verify            | 6    | eshram_db     | name, category, date     |
| 10| POST   | /gov/pmsym/verify             | 6    | pmsym_db      | status, months, date     |
| 11| POST   | /gov/insurance/policy/verify  | 7    | insurance_db  | holder, type, expiry     |
| 12| POST   | /gov/income-tax/itr/verify    | 8    | itr_db        | form, income, date       |
| 13| POST   | /api/report/generate          | —    | (Groq API)    | explanation, suggestions |

+ GET /health (no auth required)

---

## 2. FASTAPI PROJECT SETUP

```python
# backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api import otp_routes, gov_verification, bank_verification, report_routes
from app.db.connection import connect_db, close_db
from app.auth.hmac_validator import HmacMiddleware

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()

app = FastAPI(title="GigCredit API", version="1.0.0", lifespan=lifespan)

# CORS
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# HMAC auth (can be disabled via env var for development)
if os.getenv("ENABLE_HMAC", "false").lower() == "true":
    app.add_middleware(HmacMiddleware)

# Routes
app.include_router(otp_routes.router, prefix="/auth", tags=["auth"])
app.include_router(gov_verification.router, prefix="/gov", tags=["government"])
app.include_router(bank_verification.router, prefix="/bank", tags=["bank"])
app.include_router(report_routes.router, prefix="/api", tags=["report"])

@app.get("/health")
async def health():
    return {"status": "ok", "service": "gigcredit-api", "version": "1.0.0"}
```

---

## 3. INPUT VALIDATION RULES

### Aadhaar
- Must be exactly 12 digits
- Regex: `^\d{12}$`
- Cannot start with 0 or 1

### PAN
- Must be exactly 10 characters: 5 letters + 4 digits + 1 letter
- Regex: `^[A-Z]{5}[0-9]{4}[A-Z]{1}$`
- 4th character must be one of: P,C,H,F,A,T,B,L,J,G

### IFSC
- Must be exactly 11 characters: 4 letters + 0 + 6 alphanumeric
- Regex: `^[A-Z]{4}0[A-Z0-9]{6}$`

### Account Number
- 9-18 digits
- Regex: `^\d{9,18}$`

### Vehicle Number
- Indian format: 2 letters + 2 digits + 1-3 letters + 1-4 digits
- Regex: `^[A-Z]{2}\d{2}[A-Z]{1,3}\d{1,4}$`

### UAN (eShram)
- Must start with UAN
- 15 characters total

### Mobile
- Must be exactly 10 digits
- Must start with 6,7,8, or 9

---

## 4. ERROR RESPONSE FORMAT

Every error response MUST follow this format:
```json
{
  "error": "error_code",
  "message": "Human-readable description",
  "timestamp": "2026-04-25T10:00:00Z"
}
```

Error codes:
- `invalid_format` → HTTP 400
- `not_found` → HTTP 404
- `invalid_otp` → HTTP 400
- `otp_expired` → HTTP 400
- `too_many_requests` → HTTP 429
- `unauthorized` → HTTP 401
- `server_error` → HTTP 500
- `groq_unavailable` → HTTP 503

---

## 5. MONGODB ATLAS SETUP STEPS

1. Go to mongodb.com → Create Free Cluster
2. Choose M0 Free Tier → AWS → Mumbai (ap-south-1) region
3. Create database user: `gigcredit_admin` / `<strong-password>`
4. Network Access: Allow 0.0.0.0/0 (for demo; restrict in production)
5. Get connection string: `mongodb+srv://gigcredit_admin:<password>@cluster0.xxx.mongodb.net/`
6. Set as `MONGODB_URI` env variable in Render

---

## 6. RENDER DEPLOYMENT STEPS

1. Create `backend/Dockerfile` (or use Render's native Python deploy)
2. Push to GitHub
3. On Render: New → Web Service → Connect GitHub → Select repo
4. Settings:
   - Root Directory: `backend`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - Environment: Python 3.11
5. Environment Variables:
   - `MONGODB_URI` = connection string
   - `GROQ_API_KEY` = Groq API key
   - `HMAC_SECRET` = `demo-secret-key`
   - `SERVER_API_KEY` = `demo-api-key`
   - `ENABLE_HMAC` = `false` (enable at Gate G2)
6. Deploy → Wait for build → Test `/health` endpoint
