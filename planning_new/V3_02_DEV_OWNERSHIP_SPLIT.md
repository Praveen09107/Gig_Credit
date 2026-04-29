# V3.0 Dev Ownership & Work Split

## Dev A (AI Agent) — ML Pipeline, Backend, Generated Code

### Responsibilities
- Python ML pipeline: data generation, training, calibration, SHAP, export
- m2cgen-generated Dart scorer files (auto-generated, not hand-written)
- Dart scorecard files for rule-based pillars (P7 updated, P8 new)
- Dart meta-learner logistic regression
- All JSON constant/asset files
- Backend FastAPI routes (scoring, loan, explainability)
- Golden test data generation

### Files Dev A Owns (CREATE or MODIFY)
```
ml_pipeline/
├── config.py                              ← DONE
├── requirements.txt                       ← DONE
├── generation/
│   └── synthetic_data_generator.py        ← CREATE
├── training/
│   ├── train_pillars_v3.py                ← CREATE (replace old)
│   ├── calibration.py                     ← CREATE
│   └── meta_learner_v3.py                 ← CREATE (replace old)
├── explainability/
│   ├── shap_extractor.py                  ← CREATE
│   └── attention_proxy.py                 ← CREATE
├── loan/
│   ├── loan_data_generator.py             ← CREATE
│   ├── loan_lgbm_trainer.py               ← CREATE
│   └── threshold_calibrator.py            ← CREATE
├── export/
│   ├── export_m2cgen_v3.py                ← CREATE (replace old)
│   ├── constants_exporter.py              ← CREATE
│   └── golden_test_v3.py                  ← CREATE (replace old)
└── output/
    ├── models/      (p1.pkl ... p6.pkl, loan_lgbm.pkl)
    ├── assets/      (8 JSON files)
    ├── dart_export/ (scorer .dart files)
    └── golden/      (golden_100.json)

backend/app/
├── api/
│   ├── scoring_router.py                  ← CREATE
│   ├── loan_router.py                     ← CREATE
│   └── explainability_router.py           ← CREATE
├── services/
│   ├── loan_engine.py                     ← CREATE
│   ├── hard_rules.py                      ← CREATE
│   ├── affordability.py                   ← CREATE
│   ├── aan_generator.py                   ← CREATE
│   ├── kfs_generator.py                   ← CREATE
│   └── audit_chain.py                     ← CREATE
└── main.py                                ← MODIFY (add routers)
```

### Files Dev A Generates → Dev B Receives
```
app/lib/scoring/models/
├── p1_scorer.dart          ← GENERATED (replaces old)
├── p2_scorer.dart          ← GENERATED (replaces old)
├── p3_scorer.dart          ← GENERATED (replaces old)
├── p4_scorer.dart          ← GENERATED (replaces old)
├── p6_scorer.dart          ← GENERATED (replaces old)
├── scorecard_p7.dart       ← GENERATED (replaces old, 10 features)
├── scorecard_p8.dart       ← GENERATED (NEW)
├── meta_learner_lr.dart    ← GENERATED (NEW, replaces meta_scorer.dart)
└── scoring_constants.dart  ← GENERATED (replaces old)

app/assets/constants/
├── shap_lookup.json           ← GENERATED
├── tabnet_attention.json      ← GENERATED
├── calibration_knots.json     ← GENERATED
├── conformal_intervals.json   ← GENERATED
├── meta_lr_coefficients.json  ← GENERATED
├── pillar_weights.json        ← GENERATED
├── actionable_tags.json       ← GENERATED
└── feature_display_names.json ← GENERATED
```

---

## Dev B (You) — Flutter UI/UX, Integration

### Responsibilities
- Dart data model updates (add fields for 8 pillars, conformal, actions)
- Feature engineer update (rename features, add P8)
- Scoring engine integration (wire new scorers, add calibration step)
- On-device explainability UI (L1 SHAP, L2 Attention, L6 Actions)
- Score report UI (redesigned screens and widgets)
- Loan UI (4 new screens)
- API service clients for backend
- Final integration of all Dev A artifacts
- pubspec.yaml asset registration

### Files Dev B Owns (CREATE or MODIFY)
```
app/lib/models/
├── score_report_model.dart          ← MODIFY (add new fields)
├── score_pillar_model.dart          ← MODIFY (add conformal, attention)
├── shap_factor_model.dart           ← MODIFY (add pillar, actionable)
├── loan_decision_model.dart         ← CREATE
├── kfs_model.dart                   ← CREATE
└── loan_product_model.dart          ← CREATE (or modify loan_offer_model)

app/lib/scoring/
├── features/
│   └── feature_engineer.dart        ← MODIFY (rename features, add P8)
├── engine/
│   ├── scoring_engine.dart          ← MODIFY (8 pillars, calibration)
│   ├── confidence_engine.dart       ← MODIFY (add P8)
│   └── meta_learner.dart            ← MODIFY (use LR not XGB)
├── explainability/
│   ├── shap_lookup.dart             ← MODIFY (update for semantic names)
│   ├── layer1_shap.dart             ← CREATE
│   ├── layer2_attention.dart        ← CREATE
│   ├── layer6_actions.dart          ← CREATE
│   └── explanation_bundle.dart      ← CREATE
└── score_pipeline.dart              ← MODIFY (13-step pipeline)

app/lib/features/
├── report/
│   ├── screens/
│   │   └── score_report_screen.dart      ← CREATE (redesigned)
│   └── widgets/
│       ├── score_gauge_widget.dart        ← CREATE
│       ├── pillar_radar_chart.dart        ← CREATE
│       ├── pillar_detail_card.dart        ← CREATE
│       ├── shap_waterfall_chart.dart      ← CREATE
│       ├── action_improvement_card.dart   ← CREATE
│       ├── conformal_bar_widget.dart      ← CREATE
│       ├── score_summary_header.dart      ← CREATE
│       └── financial_profile_card.dart    ← CREATE
├── loans/
│   ├── screens/
│   │   ├── product_selection_screen.dart  ← CREATE
│   │   ├── kfs_display_screen.dart        ← CREATE
│   │   ├── loan_application_screen.dart   ← CREATE
│   │   └── loan_decision_screen.dart      ← CREATE
│   └── widgets/
│       ├── product_card.dart              ← CREATE
│       ├── kfs_card.dart                  ← CREATE
│       ├── decision_card.dart             ← CREATE
│       └── counterfactual_card.dart       ← CREATE
└── ...

app/lib/services/
├── score_api_service.dart           ← CREATE
├── loan_api_service.dart            ← CREATE
└── asset_loader.dart                ← CREATE (loads JSON constants)
```

---

## Files NEITHER Dev Should Touch
```
app/lib/features/auth/          (authentication — frozen)
app/lib/features/applications/  (onboarding steps 1-9 — frozen)
app/lib/models/verified_profile/ (VerifiedProfile — frozen)
app/lib/core/                   (theme, routes — frozen until integration)
backend/app/auth/               (auth — frozen)
backend/app/db/                 (database config — frozen)
```

## Conflict-Free Guarantee
- Dev A writes ONLY to `ml_pipeline/` and `backend/app/api/` + `backend/app/services/`
- Dev B writes ONLY to `app/lib/` (excluding `scoring/models/` which is Dev A generated)
- The ONLY shared files are generated artifacts (Dev A creates → Dev B copies in)
- No file is modified by both devs → zero merge conflicts
