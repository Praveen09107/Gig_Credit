# ================================================================================
# GIGCREDIT — TEAM WORK SPLIT AND DIRECTORY OWNERSHIP
# Document 02 | Version 2.0 | planning_new
# ================================================================================

## 1. WHY THE PREVIOUS SPLIT FAILED

### 1.1 Root Causes (from planning_old analysis)

1. **No contract-first development**: Both devs coded against assumptions, not schemas
2. **No mock interfaces**: Dev B was blocked until Dev A finished real APIs
3. **No integration checkpoints**: Integration was attempted only at the very end
4. **Shared file ownership**: Both devs touched the same files → merge conflicts
5. **No golden parity test**: ML models trained in Python but Dart output was never verified
6. **Git confusion**: Beginners pushing/pulling without clear branch strategy
7. **No artifact handoff process**: Model files existed locally but never made it to the app
8. **Verbal-only decisions**: Architecture changes discussed but never documented

### 1.2 How This Split Fixes Everything

- **Contract-first**: `contracts/` folder with frozen JSON schemas BEFORE coding
- **Mock-first**: Dev B uses `MockApiClient` and `MockOcrService` from Day 1
- **5 integration checkpoints**: Mandatory merge + smoke test at each gate
- **Zero file overlap**: Directory-level ownership with one-way artifact flow
- **Golden parity test**: Dev A generates `golden_inference.json`, Dev B validates
- **Strict git protocol**: Feature branches with mandatory PR review
- **Artifact manifest**: Checksummed asset tracking with build verification
- **Written decision log**: All architecture decisions logged in `contracts/decisions.md`

---

## 2. DEVELOPER ROLES

### Dev A — Backend, ML, AI (Python-Side)

**Full Title**: Backend Engineer + ML Engineer + AI Integration Lead

**Owns**:
- `backend/` — entire directory
- `ml_pipeline/` — entire directory
- `contracts/` — can propose changes (Dev B must acknowledge)
- `demo_data/seed_db.json` — database seed data
- `scripts/seed_database.py` — seeding script

**Responsibilities**:
1. Set up FastAPI project with all 13 verification endpoints
2. Set up MongoDB with all 11 collections
3. Seed MongoDB with demo verification data matching the demo inputs
4. Implement HMAC-SHA256 request authentication
5. Implement Groq LLM integration for report generation
6. Train 5 ML models (P1-P4 XGBoost + P6 RandomForest)
7. Export models to Dart via m2cgen
8. Write P5 and P7 Dart scorecards (deterministic, no ML)
9. Generate `shap_lookup.json` with binned SHAP values
10. Generate `golden_inference.json` for parity testing
11. Generate `meta_coefficients.json` with LR weights
12. Deploy backend to Render
13. Write backend unit tests

### Dev B — Flutter, UI/UX, On-Device Logic (Dart-Side)

**Full Title**: Frontend Engineer + On-Device Logic Engineer + UX Lead

**Owns**:
- `app/` — entire directory
- `contracts/` — can propose changes (Dev A must acknowledge)
- `demo_data/expected_outputs/` — expected demo output JSONs

**Responsibilities**:
1. Initialize Flutter project with Riverpod, routing, theming
2. Build impressive, premium UI/UX design system
3. Build all 9 onboarding step screens with forms, uploads, navigation
4. Build Dashboard, Score Result, Report, and Loan screens
5. Implement `MockApiClient` (returns static JSON for testing)
6. Implement `MockOcrService` (returns static parsed data for testing)
7. Integrate real API client with HMAC signing when backend is ready
8. Integrate PaddleOCR via platform channel (or use mock)
9. Implement Dart parsers (Aadhaar, PAN, bank statement, bills)
10. Implement feature engineering (95 features from VerifiedProfile)
11. Integrate m2cgen exported Dart scorers (from Dev A)
12. Implement meta-learner, confidence engine, SHAP lookup
13. Build final report UI with pillar charts, SHAP factors, LLM text
14. Implement PDF export
15. Write Flutter unit tests + widget tests

---

## 3. TASK OWNERSHIP MATRIX (RACI)

| Task                           | Dev A | Dev B | Notes                              |
|-------------------------------|-------|-------|------------------------------------|
| FastAPI setup                 | R,A   | I     | Dev A fully owns                   |
| MongoDB collections           | R,A   | I     | Dev A creates + seeds              |
| Verification endpoints        | R,A   | I     | Dev B uses mock until ready        |
| LLM report endpoint           | R,A   | I     | Dev B uses mock until ready        |
| HMAC auth middleware           | R,A   | C     | Both implement signing (Py+Dart)   |
| ML model training              | R,A   | I     | Python-only, Dev A laptop          |
| m2cgen Dart export             | R,A   | I     | Dev A exports, Dev B integrates    |
| Scorecard P5/P7 (Dart)        | R,A   | C     | Dev A writes, Dev B reviews        |
| Golden inference generation    | R,A   | I     | Dev A generates test data          |
| Flutter project setup          | I     | R,A   | Dev B fully owns                   |
| UI/UX design + theming         | I     | R,A   | Dev B fully owns                   |
| 9-step onboarding screens      | I     | R,A   | Dev B fully owns                   |
| MockApiClient                  | I     | R,A   | Dev B builds from contract         |
| Real API integration           | C     | R,A   | Dev B swaps mock → real            |
| OCR integration                | I     | R,A   | Dev B implements or mocks          |
| Dart parsers                   | I     | R,A   | Dev B implements                   |
| Feature engineering (Dart)     | C     | R,A   | Dev B implements, Dev A reviews    |
| Scoring engine integration     | C     | R,A   | Dev B integrates m2cgen files      |
| Parity test (Dart vs Python)   | C     | R,A   | Dev B runs, Dev A validates        |
| Report UI                      | I     | R,A   | Dev B fully owns                   |
| PDF export                     | I     | R,A   | Dev B fully owns                   |
| Integration checkpoint merge   | R     | R     | BOTH participate                   |
| Final demo testing             | R     | R     | BOTH participate                   |

> R = Responsible, A = Accountable, C = Consulted, I = Informed

---

## 4. COMMUNICATION PROTOCOL

### 4.1 Daily Sync (5 minutes max)

Both devs share at every sync:
```
YESTERDAY: What I completed
TODAY: What I'm working on
BLOCKED: What I need from the other dev
HANDOFF: Any files/artifacts ready for the other dev
```

### 4.2 Decision Log

All architecture decisions must be logged in `contracts/decisions.md`:
```markdown
## Decision #001 — 2026-04-25
**Topic**: OTP flow — real or simulated?
**Decision**: Simulated for demo (OTP always "123456")
**Reason**: No SMS gateway integration in 48 hours
**Approved by**: Dev A + Dev B
```

### 4.3 Handoff Protocol

When Dev A has artifacts for Dev B:
1. Dev A commits artifacts to `ml_pipeline/output/`
2. Dev A posts message: "HANDOFF: p1_scorer.dart, p2_scorer.dart ready in output/"
3. Dev B pulls, copies to `app/lib/scoring/models/`
4. Dev B runs parity test
5. Dev B commits integration
6. Dev B responds: "INTEGRATED: p1, p2 scorers — parity ✓"

---

## 5. WHAT EACH DEV NEEDS FROM THE OTHER

### Dev B Needs from Dev A (in order of priority):

| Priority | Artifact                        | When Needed          | Fallback           |
|----------|--------------------------------|----------------------|--------------------|
| 1        | `api_contract.json`             | Phase 1 (Hour 0-4)  | None — must exist  |
| 2        | Backend deployed + health check | Phase 3 (Hour 16-20)| MockApiClient      |
| 3        | Verification API endpoints live | Phase 3 (Hour 16-20)| MockApiClient      |
| 4        | m2cgen .dart scorer files       | Phase 4 (Hour 20-28)| Hardcoded scores   |
| 5        | `shap_lookup.json`              | Phase 4 (Hour 20-28)| Static SHAP values |
| 6        | `golden_inference.json`         | Phase 4 (Hour 20-28)| Skip parity test   |
| 7        | LLM report endpoint live        | Phase 5 (Hour 28-36)| Template text      |
| 8        | `meta_coefficients.json`        | Phase 4 (Hour 20-28)| Hardcoded weights  |

### Dev A Needs from Dev B:

| Priority | Artifact                        | When Needed          | Notes               |
|----------|--------------------------------|----------------------|---------------------|
| 1        | `contracts/` schemas reviewed   | Phase 1 (Hour 0-4)  | Must agree on schemas|
| 2        | Parity test results             | Phase 4 (Hour 20-28)| Confirms Dart works  |
| 3        | API integration test results    | Phase 5 (Hour 28-36)| Confirms real API OK |

---

## 6. CONFLICT PREVENTION RULES

### 6.1 File-Level Rules

1. **Dev A NEVER creates or edits files in `app/lib/`**
   - Exception: `app/lib/scoring/models/` — but only via handoff protocol
2. **Dev B NEVER creates or edits files in `backend/` or `ml_pipeline/`**
3. **Both devs can edit files in `contracts/`, `demo_data/`, `scripts/`**
   - Rule: Always pull before editing. Communicate before changing.
4. **If both need to edit the same file**: One dev makes the change, the other reviews

### 6.2 Merge-Level Rules

1. Both devs work on feature branches: `dev-a/<feature>`, `dev-b/<feature>`
2. PRs merge to `develop` branch (not `main`)
3. `main` branch is updated ONLY at integration checkpoints
4. Squash merges preferred (cleaner history)
5. If merge conflict occurs: STOP, communicate, resolve together on a call

### 6.3 The "No Surprise" Rule

**NEVER** change a contract, schema, or shared interface without notifying the other dev.
Every change to `contracts/` must be accompanied by a message explaining what changed and why.
