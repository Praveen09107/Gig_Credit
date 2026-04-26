# ================================================================================
# GIGCREDIT — PHASE 2: UI SCREENS & BACKEND APIs
# Document 08 | Hours 4–12 | planning_new
# ================================================================================

## PHASE OBJECTIVE
Dev A implements ALL verification endpoints. Dev B builds ALL 9 onboarding screens.
By Hour 12, the backend is fully operational and the app has beautiful UI for every step.

---

## DEV A TASKS (Hours 4–12)

### A2.1 — HMAC Authentication Middleware (1 hour)

Create `backend/app/auth/hmac_validator.py`:

```python
import hmac, hashlib, time
from fastapi import Request, HTTPException

async def validate_hmac(request: Request):
    api_key = request.headers.get("X-Api-Key")
    device_id = request.headers.get("X-Device-Id")
    timestamp = request.headers.get("X-Timestamp")
    signature = request.headers.get("X-Signature")
    
    # Validate all headers present
    if not all([api_key, device_id, timestamp, signature]):
        raise HTTPException(401, detail="Missing auth headers")
    
    # Check API key
    if api_key != settings.SERVER_API_KEY:
        raise HTTPException(401, detail="Invalid API key")
    
    # Check timestamp (±5 minutes)
    if abs(time.time() - int(timestamp)) > 300:
        raise HTTPException(401, detail="Request expired")
    
    # Verify HMAC
    body = await request.body()
    body_hash = hashlib.sha256(body).hexdigest()
    message = f"{device_id}:{timestamp}:{body_hash}"
    expected = hmac.new(settings.HMAC_SECRET.encode(), message.encode(), hashlib.sha256).hexdigest()
    
    if not hmac.compare_digest(signature, expected):
        raise HTTPException(401, detail="Invalid signature")
```

> **DEMO SHORTCUT**: For initial development, make HMAC validation optional
> (check a `SKIP_AUTH` env variable). Enable it at Gate G2 when Dev B integrates.

### A2.2 — OTP Endpoints (30 min)

Create `backend/app/api/otp_routes.py`:
- `POST /auth/otp/send` — Generate OTP, store in MongoDB, return in response (demo mode)
- `POST /auth/otp/verify` — Validate OTP against stored value

### A2.3 — Government Verification Endpoints (2 hours)

Create `backend/app/api/gov_verification.py`:
- `POST /gov/aadhaar/verify` — Query aadhaar_db
- `POST /gov/pan/verify` — Query pan_db
- `POST /gov/vehicle/rc/verify` — Query vehicle_rc_db
- `POST /gov/eshram/verify` — Query eshram_db
- `POST /gov/pmsym/verify` — Query pmsym_db
- `POST /gov/insurance/policy/verify` — Query insurance_db
- `POST /gov/income-tax/itr/verify` — Query itr_db

Each endpoint follows the same pattern:
1. Validate input format (regex for Aadhaar, PAN, etc.)
2. Query MongoDB collection
3. If found → return record fields
4. If not found → return 404

### A2.4 — Bank Verification Endpoints (1 hour)

Create `backend/app/api/bank_verification.py`:
- `POST /bank/ifsc/verify` — Query ifsc_db
- `POST /bank/account/verify` — Query bank_accounts_db
- `POST /bank/loan/check` — Query loan_accounts_db

### A2.5 — Seed Database with Demo Data (2 hours)

Create `backend/app/db/seed_data.py`:

This is CRITICAL. The MongoDB must contain records that match the demo inputs exactly.

```python
DEMO_AADHAAR = {
    "aadhaar": "123456789012",  # Match the demo Aadhaar card
    "name": "Ravi Kumar",
    "dob": "1997-06-12",
    "state": "Tamil Nadu",
    "pin": "600001",
    "status": "active"
}

DEMO_PAN = {
    "pan": "ABCDE1234F",  # Match the demo PAN card
    "name": "Ravi Kumar",
    "dob": "1997-06-12",
    "pan_active": True,
    "itr_filed": True,
    "itr_years": [2022, 2023, 2024]
}

# ... All 11 collections seeded with matching demo data
```

**IMPORTANT**: Dev A must look at the actual demo input images in 
`specification folders_new/Inputs/inputs hardcopies/` to extract the REAL
Aadhaar number, PAN number, etc. and seed those exact values.

### A2.6 — LLM Report Endpoint (1.5 hours)

Create `backend/app/api/report_routes.py` and `backend/app/services/llm_service.py`:
- `POST /api/report/generate`
- Receives explanation payload (score + SHAP data)
- Builds prompt from template
- Calls Groq API (llama3-70b-8192)
- Returns explanation + suggestions in requested language
- Fallback template if Groq fails

### A2.7 — Backend Tests (30 min)

Create `backend/tests/test_verification.py`:
- Test each endpoint with valid input → expect 200
- Test each endpoint with invalid input → expect 400/404
- Test HMAC validation

**DELIVERABLES by Hour 12:**
- [ ] ALL 13 verification endpoints working
- [ ] MongoDB seeded with demo data
- [ ] LLM report endpoint working with Groq
- [ ] HMAC middleware implemented
- [ ] Backend tests pass

---

## DEV B TASKS (Hours 4–12)

### B2.1 — Step 1: Basic Profile Screen (1 hour)

Create `app/lib/features/onboarding/screens/step1_basic_profile.dart`:

UI Elements:
- Section A: Personal Details
  - Full Name (text field with validation)
  - Date of Birth (date picker)
  - Mobile Number (numeric field, 10-digit validation)
  - OTP Input (6-digit, with countdown timer)
  - Current Address (multi-line)
  - Permanent Address (multi-line, "Same as current" checkbox)
  - State of Residence (searchable dropdown, 36 states/UTs)
- Section B: Professional Details
  - Work Type (4 beautiful card selector with icons)
  - Self-Declared Income (₹ numeric field)
  - Years in Profession (stepper 0-40)
  - Dependents (stepper 0-10)
  - Vehicle Ownership (toggle switch)
  - Secondary Income (optional text + amount)

Design:
- Dark theme with glassmorphic cards
- Each section in a rounded card with gradient border
- Progress indicator at top showing "Step 1 of 9"
- "Continue" button at bottom with subtle animation

### B2.2 — Step 2: Identity KYC Screen (1.5 hours)

Three upload cards:
- **Aadhaar Card** (front + back upload with camera/gallery option)
  - Show guide overlay for correct photo angle
  - After upload → show thumbnail with "Processing..." indicator
  - After OCR → show extracted name, DOB with green checkmark
- **PAN Card** (single upload)
  - Same flow as Aadhaar
- **Live Selfie** (camera only — no gallery)
  - Circular camera preview
  - "Take Photo" button
  - After capture → "Verifying face..." animation
  - Green badge: "Face Matched ✓"

### B2.3 — Step 3: Bank Verification Screen (1.5 hours)

- Bank Name (searchable dropdown — list of Indian banks)
- Account Holder Name (text)
- Branch Name (text)
- IFSC Code (with auto-format: XXXX0XXXXXX)
- Account Number (numeric, masked display)
- Bank Statement Upload (PDF picker, shows file name + size)
- MICR Code (optional)
- Secondary Bank (expandable toggle section)
- UPI Statement (optional expandable)

After upload:
- "Parsing bank statement..." animation
- Show summary: "Found 127 transactions | 6 months coverage ✓"
- "2 EMIs auto-detected" badge

### B2.4 — Step 4: Utility Bills Screen (1 hour)

Three mandatory accordion panels:
- **Electricity** — 6-slot grid (Month 1-6 upload boxes)
- **LPG/Gas** — 6-slot grid
- **Mobile** — 6-slot grid

Each slot: Upload button → thumbnail → checkmark after OCR
Optional panels: Rent proof, WiFi bills, OTT subscriptions

### B2.5 — Step 5: Work Proof Screen (1 hour)

Dynamic based on work_type from Step 1:
- **Platform Worker**: RC book, DL front/back, Vehicle insurance, 3 earning screenshots
- **Vendor**: SVANidhi ID, approval letter, trade licence
- **Skilled Trade**: Trade licence, skill certificate, client invoice
- **Freelancer**: Platform URL, profile screenshot, payment receipt

### B2.6 — Steps 6-9 Screens (2 hours total)

Step 6: Government Schemes — 7 optional fields with upload/text inputs
Step 7: Insurance — Health, Vehicle (conditional), Life sections
Step 8: Tax — ITR upload, Assessment year dropdown, GST fields
Step 9: EMI/Loans — Toggle "Do you have active loans?" → Repeatable loan cards (up to 5)

### B2.7 — Shared Widgets (1 hour)

Create reusable widgets:
- `StepProgressBar` — horizontal progress dots (9 steps)
- `DocumentUploadCard` — camera/gallery upload with thumbnail preview
- `VerificationBadge` — animated green checkmark badge
- `SectionCard` — glassmorphic card container
- `LoadingOverlay` — processing animation overlay
- `OcrResultOverlay` — shows extracted fields with confidence

**DELIVERABLES by Hour 12:**
- [ ] ALL 9 step screens built with forms and upload UI
- [ ] Navigation between steps works (forward/back)
- [ ] Step progress indicator shows current step
- [ ] Upload cards work (camera + gallery)
- [ ] MockApiClient integrated — OTP flow works
- [ ] Premium dark theme applied everywhere
