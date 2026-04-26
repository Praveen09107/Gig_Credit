# ================================================================================
# GIGCREDIT — PROJECT OVERVIEW AND ARCHITECTURE
# Document 00 | Version 2.0 | planning_new
# Strategy: Demo-First Hackathon Prototype with Real Backbone
# ================================================================================

## 1. WHAT IS GIGCREDIT

GigCredit is a privacy-first, on-device credit scoring mobile application built
for Indian gig workers who have no CIBIL credit history.

It converts REAL FINANCIAL BEHAVIOR (bank statements, utility bills, work proof,
insurance, government schemes, ITR/GST) into an alternative credit score (300–900).
Scoring happens entirely on the user's mobile device. No sensitive data leaves
the device for scoring purposes.

After scoring, GigCredit connects verified gig workers to NBFC/fintech lenders
through an in-app loan application marketplace.

---

## 2. HACKATHON STRATEGY — DEMO-FIRST PROTOTYPE

> **CRITICAL PHILOSOPHY**: This is a 48-hour hackathon demo. NOT a production deployment.

### 2.1 What "Demo-First" Means

- The app MUST look and feel like a fully working product to judges
- The UI/UX must be impressive, polished, and professional
- Core components (on-device scoring, backend APIs, OCR) are implemented for REAL
- Components that cannot be fully implemented in 48 hours use **smart placeholders**
  that return predefined outputs matching the demo input set
- Predefined demo inputs are stored in `specification folders_new/Inputs/`

### 2.2 Component Classification

| Component                  | Strategy         | Notes                                           |
|---------------------------|------------------|--------------------------------------------------|
| Flutter UI/UX             | REAL             | Must be impressive and polished                  |
| 9-Step Onboarding Flow    | REAL             | Full navigation, forms, upload UI                |
| Backend Verification APIs | REAL (simulated) | FastAPI + MongoDB with seeded demo data          |
| OCR Engine                | HYBRID           | Real for demo inputs; placeholder for others     |
| Bank Statement Parser     | HYBRID           | Real parsing for demo PDFs; fallback for others  |
| Face Verification         | PLACEHOLDER      | Always returns match=true for demo               |
| Document Authenticity     | PLACEHOLDER      | Always returns authentic=true for demo           |
| Scoring Engine (m2cgen)   | REAL             | Pure Dart arithmetic, fully working              |
| Feature Engineering       | REAL             | 95 features computed from verified profile       |
| SHAP Explainability       | REAL             | shap_lookup.json with pre-computed values        |
| LLM Report Generation     | REAL             | Groq API call for plain language explanation     |
| Loan Matching Engine      | PLACEHOLDER      | Hardcoded partner offers                         |
| PDF Report Export         | REAL             | On-device PDF generation                         |
| Security (HMAC, encrypt)  | SIMPLIFIED       | Implemented but not production-hardened           |
| Data Deletion             | PLACEHOLDER      | UI shows deletion; actual cleanup simplified     |

### 2.3 Demo Input Strategy

All demo inputs live in `specification folders_new/Inputs/inputs hardcopies/`:
- Step 2: Aadhaar front/back (.jpeg), PAN card (.jpeg)
- Step 3: Bank Statements (3 PDFs)
- Step 4: Utility bills (EB, gas, mobile, rent, wifi, OTT)
- Step 5: Work proof documents (4 worker categories)
- Step 6: Government scheme documents (eShram, PM-SYM, Mudra, PPF, etc.)
- Step 7: Insurance documents (health, life, vehicle .jpeg)
- Step 8: ITR (.jpeg), GST registration (.pdf), GSTR returns (.pdf)
- Step 9: No hardcopy needed (user-declared EMI data)

**Backend MongoDB will be seeded with matching verification records for these
exact demo inputs so the full flow works end-to-end.**

---

## 3. TECH STACK

| Layer          | Technology                          | Purpose                              |
|----------------|-------------------------------------|--------------------------------------|
| Frontend       | Flutter (Dart)                      | Cross-platform mobile app            |
| State Mgmt     | Riverpod                            | Reactive state management            |
| Backend        | FastAPI (Python 3.11+)              | Verification APIs + LLM proxy        |
| Database       | MongoDB (Atlas or local)            | Simulated gov/bank verification DB   |
| LLM            | Groq API (llama3-70b-8192)          | Report explanation generation        |
| ML Export      | m2cgen (Python → Dart)              | Pure Dart arithmetic scoring         |
| OCR            | PaddleOCR Lite (native Android)     | On-device document text extraction   |
| PDF Parsing    | pdfplumber (Python) / pdfx (Dart)   | Bank statement extraction            |
| Deployment     | Render / Docker                     | Backend hosting                      |
| Version Ctrl   | Git + GitHub                        | Source code management               |

---

## 4. SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                    USER'S FLUTTER DEVICE                      │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────────┐  │
│  │ Document  │  │ On-Device│  │   Scoring Engine         │  │
│  │ Capture   │→ │ OCR      │→ │   (m2cgen Pure Dart)     │  │
│  │ (Camera)  │  │ (Paddle) │  │   7 Pillars + MetaLearner│  │
│  └──────────┘  └──────────┘  └─────────────┬────────────┘  │
│                                              │               │
│  ┌───────────────────────────────────────────▼────────────┐  │
│  │         Feature Engineering (Dart, 95 features)        │  │
│  └───────────────────────────┬────────────────────────────┘  │
│                               │                               │
│  ┌───────────────────────────▼────────────────────────────┐  │
│  │         SHAP Lookup → Explanation Payload Builder       │  │
│  └───────────────────────────┬────────────────────────────┘  │
└──────────────────────────────│────────────────────────────────┘
                               │ HTTPS (HMAC Auth)
┌──────────────────────────────▼────────────────────────────────┐
│                      BACKEND SERVER                            │
│                   (FastAPI + MongoDB)                          │
│                                                                │
│  ┌──────────────────────┐   ┌─────────────────────────────┐  │
│  │ Verification API     │   │ LLM Report Layer            │  │
│  │ /gov/aadhaar/verify  │   │ /api/report/generate        │  │
│  │ /gov/pan/verify      │   │   → Groq (llama3-70b)       │  │
│  │ /bank/ifsc/verify    │   │   → Plain English + Tips    │  │
│  │ ...11 more endpoints │   │                             │  │
│  └──────────────────────┘   └─────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### 4.1 Backend Responsibilities (ONLY)

1. **Verification API** — Verify identifiers against MongoDB (simulated gov/bank DB)
2. **LLM Report Generation** — Convert SHAP JSON → plain language via Groq API

### 4.2 Backend NEVER Does

- Compute credit scores
- Run ML models
- Process bank statements
- Store user documents, Aadhaar, PAN, or transaction data

---

## 5. FOUR USER TYPES SUPPORTED

| # | Work Type             | Examples                                     |
|---|----------------------|----------------------------------------------|
| 1 | Platform Worker       | Swiggy, Zomato, Ola, Uber, Rapido driver     |
| 2 | Vendor / Seller       | Fruit seller, kirana shop, street food vendor |
| 3 | Skilled Tradesperson  | Electrician, plumber, carpenter, mechanic     |
| 4 | Freelancer            | Designer, developer, writer, consultant       |

Work type (selected in Step 1) determines:
- Step 5 content (work proof documents)
- P1 income feature engineering routing
- Meta-learner work-type interaction terms
- Vehicle insurance mandatory status in Step 7

---

## 6. 9-STEP ONBOARDING FLOW SUMMARY

| Step | Name                    | Fields (M/O)  | Backend Calls      | On-Device Processing     |
|------|------------------------|---------------|--------------------|-----------------------------|
| 1    | Basic Profile          | 12M / 1O      | OTP send+verify    | Work type routing            |
| 2    | Identity (KYC)         | 6M / 0O       | Aadhaar+PAN verify | OCR, face match (placeholder)|
| 3    | Bank Verification      | 6M / 11O      | IFSC+Acct+Loan     | PDF parse, txn tagging       |
| —    | EMI Auto-Analysis      | 0 (automated) | None               | Pattern detection from Step 3|
| 4    | Utility Bills          | 18M / 13O     | None               | OCR, bank cross-check        |
| 5    | Work Proof (dynamic)   | 3-8M / 1-2O   | RC verify (plat.)  | OCR, DL class match          |
| 6    | Gov Scheme Signals     | 0M / 7O       | eShram+PMSYM       | Scheme participation stored  |
| 7    | Insurance Signals      | 0-2M / 4O     | Policy verify      | Policy cross-check           |
| 8    | Tax & Compliance       | 0M / 5O       | ITR verify         | Filing status stored         |
| 9    | EMI & Loan Behaviour   | 1M / 25O      | None               | Cross-check vs Step 3        |

---

## 7. SCORING ENGINE ARCHITECTURE

### 7.1 Seven Pillar Models

| Pillar | Name                   | Features | Model Type              | Dart File         |
|--------|------------------------|----------|-------------------------|-------------------|
| P1     | Income Stability       | 0–12     | XGBoost (m2cgen Dart)   | p1_scorer.dart    |
| P2     | Payment Discipline     | 13–27    | XGBoost (m2cgen Dart)   | p2_scorer.dart    |
| P3     | Debt Management        | 28–36    | XGBoost (m2cgen Dart)   | p3_scorer.dart    |
| P4     | Savings Behaviour      | 37–48    | XGBoost (m2cgen Dart)   | p4_scorer.dart    |
| P5     | Work and Identity      | 49–66    | Dart Scorecard          | scorecard_p5.dart |
| P6     | Financial Resilience   | 67–77    | RandomForest (m2cgen)   | p6_scorer.dart    |
| P7     | Social Accountability  | 78–94    | Dart Scorecard          | scorecard_p7.dart |

### 7.2 Meta-Learner

- Type: Logistic Regression (pure Dart dot product + sigmoid)
- Input: 19 values (7 pillar scores + 4 work-type one-hot + 8 interaction terms)
- Formula: `logit = dot(meta_inputs, coefficients) + intercept`
- `probability = 1 / (1 + exp(-logit))`
- `final_score = round(probability × 600) + 300`
- Output range: 300 (worst) → 900 (best)

### 7.3 Score Grades

| Score     | Grade | Label           | Risk Band |
|-----------|-------|-----------------|-----------|
| 800–900   | S     | Exceptional     | Low       |
| 720–799   | A     | Excellent       | Low       |
| 640–719   | B     | Good            | Low       |
| 560–639   | C     | Average         | Medium    |
| 480–559   | D     | Below Average   | Medium    |
| 300–479   | E     | Poor            | High      |

---

## 8. TEAM STRUCTURE

| Role   | Responsibilities                                          |
|--------|----------------------------------------------------------|
| Dev A  | Backend (FastAPI), ML Pipeline (Python), AI Integration   |
| Dev B  | Flutter UI/UX, On-device Logic, Scoring Engine (Dart)     |
| Shared | Integration checkpoints, testing, final assembly          |

**CRITICAL RULE**: Dev A and Dev B work on strictly isolated directory trees.
No file is ever owned by both developers simultaneously.

---

## 9. REFERENCE DOCUMENTS

All specifications are sourced from `specification folders_new/`:
- `GIGCREDIT-MASTER-PROJECT-SPECIFICATION.txt` — Master flow
- `GIGCREDIT-BACKEND-SERVER-SPECIFICATION.txt` — Backend APIs
- `GIGCREDIT-OCR-ENGINE-PARSER-INSTRUCTIONS.txt` — OCR/Parser
- `GIGCREDIT-SHAP-LLM-REPORT-PIPELINE-SPECIFICATION.txt` — Report pipeline
- `Feature engineering (1).txt` — 95-feature definitions
- `error handling and error managing.txt` — Error prevention
- `gig_credit_flutter_on_device_technical_specification.md` — Flutter arch
- `ML Specification/` — 6 detailed ML pipeline documents
- `Inputs/` — Demo input hardcopies and step-wise input specs
- `input validation and verification/` — 10 step-wise validation specs

Legacy reference (what went wrong): `planning_old/` (41 documents)
Legacy specs (superseded): `specification folder_old/` (19 documents)
