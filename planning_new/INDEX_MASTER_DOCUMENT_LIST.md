# ================================================================================
# GIGCREDIT — MASTER INDEX: ALL PLANNING DOCUMENTS
# Document INDEX | planning_new
# READ THIS FIRST
# ================================================================================

## HOW TO USE THESE DOCUMENTS

1. **Both devs**: Read documents 00–06 first (Project Overview → Demo Strategy)
2. **Dev A**: Read documents 09, 19, 23, 27, 28 (Backend + ML specific)
3. **Dev B**: Read documents 10, 16, 17, 18, 29, 32 (Flutter + Scoring specific)
4. **Both devs**: Read document 04 (Integration Gates) — this is your checkpoint system
5. **During work**: Reference phase docs (07-15) for current phase tasks

---

## CORE DOCUMENTS (Both Devs Must Read)

| # | Document | File | Size | Purpose |
|---|----------|------|------|---------|
| 00 | Project Overview & Architecture | [00_PROJECT_OVERVIEW](00_PROJECT_OVERVIEW_AND_ARCHITECTURE.md) | 14KB | What GigCredit is, tech stack, system architecture |
| 01 | Folder Structure & Conventions | [01_FOLDER_STRUCTURE](01_FOLDER_STRUCTURE_AND_CONVENTIONS.md) | 16KB | Monorepo structure, directory ownership, coding style |
| 02 | Team Work Split & Ownership | [02_TEAM_WORK_SPLIT](02_TEAM_WORK_SPLIT_AND_OWNERSHIP.md) | 10KB | RACI matrix, handoff protocol, communication rules |
| 03 | Git Workflow & Merge Protocol | [03_GIT_WORKFLOW](03_GIT_WORKFLOW_AND_MERGE_PROTOCOL.md) | 7KB | Branch strategy, commit format, conflict resolution |
| 04 | Integration Checkpoints & Gates | [04_INTEGRATION_CHECKPOINTS](04_INTEGRATION_CHECKPOINTS_AND_GATES.md) | 10KB | 5 gates (G0-G4) with pass/fail criteria |
| 05 | Data Contracts & API Schemas | [05_DATA_CONTRACTS](05_DATA_CONTRACTS_AND_API_SCHEMAS.md) | 11KB | ALL API request/response schemas, VerifiedProfile |
| 06 | Demo Strategy & Fallback Plan | [06_DEMO_STRATEGY](06_DEMO_STRATEGY_AND_FALLBACK_PLAN.md) | 9KB | Tier A/B/C classification, demo flow script |

---

## PHASE-BY-PHASE IMPLEMENTATION (Read During Each Phase)

| # | Document | File | Hours | Purpose |
|---|----------|------|-------|---------|
| 07 | Phase 1: Setup & Contract Freeze | [PHASE_1_07](PHASE_1_07_SETUP_AND_CONTRACT_FREEZE.md) | 0-4 | Environment setup, mocks, git |
| 08 | Phase 2: UI Screens & Backend APIs | [PHASE_2_08](PHASE_2_08_UI_SCREENS_AND_BACKEND_APIS.md) | 4-12 | All 9 step screens + 13 endpoints |
| 09 | Phase 2: Dev A Backend Detailed | [PHASE_2_09](PHASE_2_09_DEV_A_BACKEND_DETAILED.md) | 4-12 | Seed data, endpoint patterns, LLM service |
| 10 | Phase 2: Dev B UI/UX Detailed | [PHASE_2_10](PHASE_2_10_DEV_B_UI_UX_DETAILED.md) | 4-12 | Screen-by-screen design specs |
| 11 | Phase 3: Integration & OCR | [PHASE_3_11](PHASE_3_11_INTEGRATION_AND_OCR.md) | 12-20 | Deploy, real API, OCR pipeline |
| 12 | Phase 4: ML Export & Scoring | [PHASE_4_12](PHASE_4_12_ML_EXPORT_AND_SCORING.md) | 20-28 | m2cgen, meta-learner, SHAP, parity |
| 13 | Phase 5: Report & Full Integration | [PHASE_5_13](PHASE_5_13_REPORT_AND_FULL_INTEGRATION.md) | 28-36 | LLM report, PDF export, full pipeline |
| 14 | Phase 6: Polish, Loans & Error Handling | [PHASE_6_14](PHASE_6_14_POLISH_LOANS_ERROR_HANDLING.md) | 36-42 | Loan marketplace, animations, error UI |
| 15 | Phase 7: Final Demo & QA | [PHASE_7_15](PHASE_7_15_FINAL_DEMO_AND_QA.md) | 42-48 | Demo rehearsal, release APK, script |

---

## COMPONENT SPECIFICATIONS (Reference During Implementation)

| # | Document | File | Owner | Purpose |
|---|----------|------|-------|---------|
| 16 | Scoring Engine | [COMP_16](COMP_16_SCORING_ENGINE.md) | Both | Pipeline order, meta-learner spec |
| 17 | OCR & Parser Pipeline | [COMP_17](COMP_17_OCR_AND_PARSER_PIPELINE.md) | Dev B | OCR strategy, parsers, demo fallback |
| 18 | Feature Engineering (95 Features) | [COMP_18](COMP_18_FEATURE_ENGINEERING_95_FEATURES.md) | Dev B | Complete 95-feature map with formulas |
| 19 | Backend Verification API | [COMP_19](COMP_19_BACKEND_VERIFICATION_API.md) | Dev A | Endpoint registry, validation, deploy |
| 20 | LLM Report Pipeline | [COMP_20](COMP_20_LLM_REPORT_PIPELINE.md) | Both | Prompt template, Groq integration |
| 21 | SHAP Explainability | [COMP_21](COMP_21_SHAP_EXPLAINABILITY.md) | Both | Lookup format, feature labels |
| 22 | Security & Authentication | [COMP_22](COMP_22_SECURITY_AND_AUTH.md) | Both | HMAC protocol, demo simplifications |
| 23 | ML Training Pipeline | [COMP_23](COMP_23_ML_TRAINING_PIPELINE.md) | Dev A | Synthetic data, training, export |
| 24 | 9-Step Input & Validation | [COMP_24](COMP_24_NINE_STEP_INPUT_VALIDATION.md) | Dev B | All fields per step with validation rules |
| 27 | MongoDB Seed Data | [COMP_27](COMP_27_MONGODB_SEED_DATA.md) | Dev A | All collections, seed values |
| 30 | Cross-Step Validation | [COMP_30](COMP_30_CROSS_STEP_VALIDATION.md) | Dev B | Validation matrix, EMI detection, confidence |
| **34** | **Frontend Complete Planning** | **[COMP_34](COMP_34_FRONTEND_COMPLETE_PLANNING.md)** | **Dev B** | **Master frontend plan — all screens, states, components, interactions, implementation order derived from full spec analysis** |

---

## OPERATIONAL DOCUMENTS

| # | Document | File | Purpose |
|---|----------|------|---------|
| 25 | Error Prevention & Risk | [25_ERROR_PREVENTION](25_ERROR_PREVENTION_AND_RISK.md) | Risk register, emergency procedures |
| 26 | Testing Strategy | [26_TESTING](26_TESTING_STRATEGY.md) | Backend tests, Flutter tests, demo checklist |
| 28 | Dev A Complete Checklist | [28_DEV_A_CHECKLIST](28_DEV_A_COMPLETE_CHECKLIST.md) | Hour-by-hour todo for Dev A |
| 29 | Dev B Complete Checklist | [29_DEV_B_CHECKLIST](29_DEV_B_COMPLETE_CHECKLIST.md) | Hour-by-hour todo for Dev B |
| 31 | Timeline & Dependency Map | [31_TIMELINE](31_TIMELINE_AND_DEPENDENCY_MAP.md) | Visual timeline, critical path |
| 32 | Flutter Dependencies | [32_FLUTTER_DEPS](32_FLUTTER_DEPENDENCIES.md) | pubspec.yaml, package purposes |
| 33 | Lessons from Planning Old | [33_LESSONS](33_LESSONS_FROM_PLANNING_OLD.md) | What went wrong and how it's fixed |

---

## DOCUMENT STATISTICS

- **Total Documents**: 35 (including this index)
- **Total Size**: ~265KB of detailed planning
- **Code Examples**: 60+ (Dart + Python)
- **Data Contracts**: 5 frozen schemas
- **Integration Gates**: 5 checkpoints (G0–G4)
- **Risk Mitigations**: 16 identified risks with fallbacks
- **Test Cases**: Demo flow checklist + parity test + unit tests
- **Frontend Spec Coverage**: 100% (all 16 spec files analysed, 3 gaps fixed)

---

## QUICK START

### Dev A's First Hour:
1. Read: 00, 01, 02, 03, 05, 06
2. Do: Phase 1 tasks from Doc 07 (Dev A section)
3. Reference: Doc 09 (Backend Detailed), Doc 19 (Verification API)

### Dev B's First Hour:
1. Read: 00, 01, 02, 03, 05, 06
2. Do: Phase 1 tasks from Doc 07 (Dev B section)
3. Reference: **Doc 34 (Frontend Complete Planning — PRIMARY)**, Doc 10 (UI/UX Detailed), Doc 32 (Flutter Dependencies)

### After Both Finish Phase 1:
Run Gate G0 checklist from Doc 04 → Proceed to Phase 2
