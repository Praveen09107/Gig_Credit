# ================================================================================
# GIGCREDIT — INTEGRATION CHECKPOINTS AND QUALITY GATES
# Document 04 | Version 2.0 | planning_new
# ================================================================================

## 1. WHY INTEGRATION CHECKPOINTS MATTER

In the previous attempt, both devs worked in isolation for the entire 48 hours
and attempted integration only at the very end. Result: **0% integration success**.

This document defines **5 mandatory integration checkpoints** where both devs
must stop, merge, and verify together before proceeding.

---

## 2. CHECKPOINT OVERVIEW

| Gate | Hour  | Name                          | What Must Work                           |
|------|-------|-------------------------------|------------------------------------------|
| G0   | 0-4   | Architecture Freeze           | Contracts frozen, mocks working, git OK  |
| G1   | 12-16 | Skeleton Integration          | Mock app talks to mock backend           |
| G2   | 20-24 | Real Backend + Stub Frontend  | Real APIs respond, app calls them        |
| G3   | 32-36 | Scoring + Report Integration  | Real scoring in Dart, LLM report works   |
| G4   | 42-48 | Final Demo Assembly           | Full end-to-end demo flow verified       |

---

## 3. GATE G0 — ARCHITECTURE FREEZE (Hour 0–4)

### Entry Criteria
- Both devs have read planning_new documents
- Both devs have cloned the repository

### What Must Be Done

**Dev A**:
- [ ] FastAPI project initialized (`backend/app/main.py` runs)
- [ ] `contracts/api_contract.json` finalized
- [ ] `contracts/feature_vector_contract.json` finalized
- [ ] `contracts/verified_profile_contract.json` finalized
- [ ] Health endpoint: `GET /health` returns `{"status": "ok"}`

**Dev B**:
- [ ] Flutter project initialized (`flutter run` succeeds)
- [ ] Design system created (colors, typography, theme)
- [ ] `MockApiClient` returns static JSON for OTP and Aadhaar
- [ ] `MockOcrService` returns static parsed data for Aadhaar
- [ ] Navigation shell (auth → dashboard → step 1 → ... → step 9 → score)

**Together**:
- [ ] Both devs have reviewed and agreed on ALL contracts
- [ ] Git branches created: `develop`, `dev-a/backend`, `dev-b/ui`
- [ ] Both devs can pull and push without errors
- [ ] `.gitignore` verified

### Exit Criteria (Gate Pass)
```
□ contracts/*.json files exist and both devs agree
□ flutter run works on Dev B's machine
□ python backend/app/main.py works on Dev A's machine
□ Both devs successfully pushed to their branches
□ develop branch has initial project structure
```

### Smoke Test
```bash
# Dev A machine:
curl http://localhost:8000/health
# Expected: {"status": "ok"}

# Dev B machine:
flutter run
# Expected: App launches with login screen → dashboard → step navigation works
```

---

## 4. GATE G1 — SKELETON INTEGRATION (Hour 12–16)

### Purpose
Verify that the Flutter app can **call the backend** (even with mock/basic responses).

### What Must Be Done

**Dev A**:
- [ ] OTP endpoints implemented (`/auth/otp/send`, `/auth/otp/verify`)
- [ ] At least 2 verification endpoints working (Aadhaar + PAN)
- [ ] MongoDB connected with demo seed data for Aadhaar and PAN
- [ ] HMAC middleware implemented and tested

**Dev B**:
- [ ] Steps 1-4 UI screens built with forms and upload cards
- [ ] `RealApiClient` with HMAC signing implemented
- [ ] App successfully calls `/health` endpoint
- [ ] App successfully calls `/auth/otp/send` and receives response

**Together**:
- [ ] Dev B's app can call Dev A's running backend
- [ ] OTP flow works end-to-end (send → verify → proceed to Step 2)
- [ ] Aadhaar verification call works (send aadhaar number → get response)
- [ ] Merge both branches to `develop`

### Exit Criteria (Gate Pass)
```
□ App successfully sends HTTP request to backend
□ HMAC authentication passes
□ OTP flow returns verified=true
□ At least one verification endpoint returns real data
□ develop branch has working skeleton
```

### Smoke Test
```bash
# Dev A: Start backend
cd backend && uvicorn app.main:app --reload

# Dev B: Run app and trigger
# 1. Open app → Step 1 → Enter mobile → Send OTP → Enter OTP → Verified ✓
# 2. Step 2 → Enter Aadhaar number → Call verify → Get response ✓

# Verify in backend logs that requests are received
```

---

## 5. GATE G2 — REAL BACKEND + STUB FRONTEND (Hour 20–24)

### Purpose
All backend APIs are operational. App calls all of them (results may use placeholders).

### What Must Be Done

**Dev A**:
- [ ] ALL 13 verification endpoints implemented and tested
- [ ] MongoDB seeded with ALL demo input data
- [ ] LLM report endpoint implemented (`/api/report/generate`)
- [ ] Backend deployed to Render (or accessible via ngrok)
- [ ] m2cgen Dart export files generated (at least P1, P2)
- [ ] `golden_inference.json` generated for available pillars

**Dev B**:
- [ ] ALL 9 step screens built with forms and navigation
- [ ] Document upload UI working (camera + gallery)
- [ ] OCR integration attempted (real or mock)
- [ ] App calls ALL verification endpoints with demo data
- [ ] Score processing screen built (with loading animation)
- [ ] Report screen shell built

**Together**:
- [ ] Full 9-step flow works with demo data
- [ ] All verification calls return valid responses
- [ ] LLM report endpoint returns explanation text
- [ ] Merge to `develop` and tag `v2.0-gate2`

### Exit Criteria (Gate Pass)
```
□ All 13 backend endpoints respond correctly
□ Backend is accessible remotely (Render or ngrok)
□ App completes 9-step flow with demo inputs
□ LLM report endpoint returns valid JSON
□ At least 2 m2cgen Dart files are exported
```

---

## 6. GATE G3 — SCORING + REPORT INTEGRATION (Hour 32–36)

### Purpose
Real on-device scoring works. Real LLM report works. The full pipeline is connected.

### What Must Be Done

**Dev A**:
- [ ] ALL m2cgen Dart files exported (P1-P4, P6)
- [ ] P5 and P7 Dart scorecards written
- [ ] `scoring_constants.dart` with meta-learner coefficients
- [ ] `shap_lookup.json` generated
- [ ] `meta_coefficients.json` generated
- [ ] `golden_inference.json` with full test cases

**Dev B**:
- [ ] ALL m2cgen Dart files integrated into `app/lib/scoring/models/`
- [ ] Feature engineering function working (95 features from VerifiedProfile)
- [ ] Meta-learner producing score 300-900
- [ ] Confidence engine adjusting pillar scores
- [ ] SHAP lookup working (top 3 positive + top 3 negative)
- [ ] Report screen displaying real score, pillars, SHAP factors
- [ ] LLM explanation text rendered in report
- [ ] PDF export working

**Together**:
- [ ] Run golden parity test: Python output vs Dart output < 1e-5
- [ ] Full demo flow: Input → OCR → Verify → Score → Report → PDF
- [ ] LLM explanation is in correct language
- [ ] Merge to `develop` and tag `v3.0-gate3`

### Exit Criteria (Gate Pass)
```
□ Parity test passes (Python vs Dart output match within 1e-5)
□ Demo user gets a score between 300-900
□ Report shows 7 pillar scores with visual bars
□ Report shows SHAP strengths and concerns
□ LLM explanation text appears in selected language
□ PDF export generates a readable document
```

---

## 7. GATE G4 — FINAL DEMO ASSEMBLY (Hour 42–48)

### Purpose
Polish everything. Rehearse the demo. Fix edge cases. Ensure the app is demo-ready.

### What Must Be Done

**Dev A**:
- [ ] Backend stable on Render (no crashes)
- [ ] All API responses < 2 seconds
- [ ] Fallback templates working if Groq is down
- [ ] Rate limiting configured

**Dev B**:
- [ ] UI polish: animations, transitions, loading states
- [ ] Error states handled (network error → user-friendly message)
- [ ] Loan marketplace screen with hardcoded partner offers
- [ ] App icon, splash screen set
- [ ] Release APK built successfully

**Together**:
- [ ] Run full demo flow 3 times without errors
- [ ] Demo with ALL predefined inputs from `Inputs/inputs hardcopies/`
- [ ] Time the demo (should be < 5 minutes for judges)
- [ ] Prepare demo script (who clicks what, what to say)
- [ ] Build release APK
- [ ] Final merge to `main` and tag `v1.0-release`

### Exit Criteria (Gate Pass)
```
□ Full demo flow runs 3/3 times without errors
□ App looks polished and professional
□ Demo takes < 5 minutes
□ Release APK builds successfully
□ Backend is stable on Render
□ Demo script is written
□ main branch has final code
```

---

## 8. WHAT HAPPENS IF A GATE FAILS

### Recovery Protocol

1. **Identify the blocker**: Which specific component is failing?
2. **Assess severity**:
   - **Critical (flow stops)**: Both devs fix together, no other work until resolved
   - **Major (feature broken)**: Switch to placeholder/mock for that component
   - **Minor (cosmetic)**: Note it, fix during Gate G4 polish time
3. **Activate fallback**: If a real component can't be fixed in 30 minutes:
   - Replace with placeholder that returns expected demo output
   - Log it in `contracts/decisions.md` as a known workaround
4. **Proceed to next phase**: Don't let one broken feature hold up everything

### Fallback Components (Pre-Built)

| Component              | Fallback                              |
|------------------------|---------------------------------------|
| Verification API down  | MockApiClient returns static success  |
| OCR not working        | MockOcrService returns parsed data    |
| Face match failing     | Always return similarity=0.95         |
| Scoring producing NaN  | Return hardcoded demo score (682, B)  |
| LLM API timeout        | Use template explanation text         |
| PDF export broken      | Skip PDF, show report on screen only  |

---

## 9. INTEGRATION CHECKPOINT TIMELINE VISUAL

```
Hour:  0    4    8    12   16   20   24   28   32   36   40   44   48
       │    │    │    │    │    │    │    │    │    │    │    │    │
  G0:  ├────┤
  G1:  │              ├────┤
  G2:  │                        ├────┤
  G3:  │                                      ├────┤
  G4:  │                                                ├────────┤

Dev A: [Setup + Contracts][Backend APIs    ][ML + Export  ][Polish ]
Dev B: [Setup + UI Shell ][9-Step Screens  ][Score+Report ][Polish ]
       [PARALLEL]         [PARALLEL]        [INTEGRATION]  [FINAL ]
```
