# GigCredit v3.0 Upgrade — Master Document Index

> Total: **32 planning documents** for parallel Dev A / Dev B execution

## Foundation Documents (00–06)
| # | Document | Purpose | Status |
|---|----------|---------|--------|
| 00 | `V3_00_MASTER_INDEX.md` | This file — index of all documents | ✅ |
| 01 | `V3_01_ARCHITECTURE_OVERVIEW.md` | System architecture, freeze/rebuild zones | ✅ |
| 02 | `V3_02_DEV_OWNERSHIP_SPLIT.md` | File-level ownership map | ✅ |
| 03 | `V3_03_FEATURE_VECTOR_CONTRACT.md` | All 95 base features: index, name, type, range | ✅ |
| 04 | `V3_04_SCORER_FUNCTION_CONTRACTS.md` | Dart scorer function signatures | ✅ |
| 05 | `V3_05_JSON_ASSET_SCHEMAS.md` | 8+ JSON constant file schemas | ✅ |
| 06 | `V3_06_BACKEND_API_CONTRACTS.md` | Full REST API request/response schemas | ✅ |

## Dev A Documents (07–16)
| # | Document | Purpose | Status |
|---|----------|---------|--------|
| 07 | `V3_07_DEV_A_SYNTHETIC_DATA.md` | Synthetic data generator (15K × 116) | ✅ |
| 08 | `V3_08_DEV_A_TRAINING_PIPELINE.md` | **Per-pillar models: LightGBM/XGBoost/ExtraTrees** | ✅ CORRECTED |
| 09 | `V3_09_DEV_A_CALIBRATION.md` | Isotonic calibration + conformal intervals | ✅ |
| 10 | `V3_10_DEV_A_META_LEARNER.md` | **LR with 20 inputs (8P + 8conf + 4cross)** | ✅ CORRECTED |
| 11 | `V3_11_DEV_A_SHAP_EXTRACTION.md` | SHAP binned lookup (20-bin, work-type-aware) | ✅ |
| 12 | `V3_12_DEV_A_ATTENTION_PROXY.md` | XGBoost/LightGBM → attention proxy | ✅ |
| 13 | `V3_13_DEV_A_EXPORT_PIPELINE.md` | m2cgen export (LightGBM + XGBoost + ExtraTrees) | ✅ |
| 14 | `V3_14_DEV_A_LOAN_ML.md` | Loan LightGBM training (18 features) | ✅ |
| 15 | `V3_15_DEV_A_BACKEND_SCORING.md` | Score storage + L5-L10 explainability API | ✅ |
| 16 | `V3_16_DEV_A_BACKEND_LOAN.md` | Loan API (3-stage decision, AAN, counterfactuals) | ✅ |

## Dev B Documents (17–22)
| # | Document | Purpose | Status |
|---|----------|---------|--------|
| 17 | `V3_17_DEV_B_DATA_MODELS.md` | Dart data model updates and new models | ✅ |
| 18 | `V3_18_DEV_B_SCORING_ENGINE.md` | Feature engineer + scoring engine + meta-learner | ✅ |
| 19 | `V3_19_DEV_B_EXPLAINABILITY.md` | On-device L1–L4 Dart classes | ✅ |
| 20 | `V3_20_DEV_B_SCORE_REPORT_UI.md` | Score report screens and widgets | ✅ |
| 21 | `V3_21_DEV_B_LOAN_UI.md` | 4 loan screens spec | ✅ |
| 22 | `V3_22_DEV_B_SCORE_PIPELINE.md` | 6-stage pipeline orchestrator | ✅ |

## Integration & Operations (23–25)
| # | Document | Purpose | Status |
|---|----------|---------|--------|
| 23 | `V3_23_INTEGRATION_PLAN.md` | Step-by-step integration (Dev B leads) | ✅ |
| 24 | `V3_24_TIMELINE_DEPENDENCIES.md` | Parallel execution timeline + dependency graph | ✅ |
| 25 | `V3_25_TESTING_AND_RISKS.md` | Testing strategy + risk mitigation | ✅ |

## NEW: Advanced Pipeline Documents (26–31)
| # | Document | Purpose | Status |
|---|----------|---------|--------|
| 26 | `V3_26_CROSS_PILLAR_FEATURES.md` | **20 interaction features (95→115), formulas** | ✅ NEW |
| 27 | `V3_27_WORK_TYPE_NORMALISATION.md` | **Stage 1: 5-feature work-type rescaling** | ✅ NEW |
| 28 | `V3_28_EXPLAINABILITY_10_LAYERS.md` | **10-layer XAI architecture (4 on-device + 6 server)** | ✅ NEW |
| 29 | `V3_29_LOAN_PRODUCTS_PRICING.md` | **3 products, risk-based pricing, DiCE, AAN** | ✅ NEW |
| 30 | `V3_30_FAIRNESS_ENGINE.md` | **5 metrics + temporal + linguistic bias audit** | ✅ NEW |
| 31 | `V3_31_AUDIT_TRAIL.md` | **SHA-256 hash-chain + decision replay** | ✅ NEW |

---

## Key Corrections from User's Spec

| What Changed | Old Planning | Corrected |
|-------------|-------------|-----------|
| P1 model | XGBoost | **LightGBM GBDT** (fat-tailed gig income) |
| P2 model | XGBoost | XGBoost + **colsample=0.7** (correlated features) |
| P3 model | XGBoost | XGBoost **depth=2, 80 trees** (shallow, one dominant feature) |
| P4 model | XGBoost | **LightGBM GBDT** + interaction constraints |
| P6 model | XGBoost | **ExtraTreesRegressor** (binary flags) |
| Feature count | 95 | **115** (+20 cross-pillar) |
| Pre-processing | None | **Work-type normalisation** (5 features) |
| Meta-learner input | 24 elements | **20 elements** (8P + 8conf + 4cross) |
| Explainability | 9 layers | **10 layers** (EFS added, different numbering) |
| On-device XAI | L1 SHAP only | **L1–L4** (decomposition, SHAP, actionable, trajectory) |
| Loan products | 3 generic | 3 specific + **risk-based pricing** |
| Fairness | Not planned | **7 metrics** + auto-mitigation |
| Audit | Basic | **SHA-256 hash-chain** + decision replay |
