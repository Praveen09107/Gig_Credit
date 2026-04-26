# ================================================================================
# GIGCREDIT — FOLDER STRUCTURE AND CODING CONVENTIONS
# Document 01 | Version 2.0 | planning_new
# ================================================================================

## 1. MONOREPO STRUCTURE

The entire project lives in a SINGLE repository. Both Dev A and Dev B work in
strictly isolated directory subtrees. There is ZERO file overlap between developers.

```
gig_credit/
├── app/                              # Flutter application (Dev B OWNS)
│   ├── android/                      # Android native configuration
│   ├── ios/                          # iOS placeholder (not active)
│   ├── lib/                          # Dart source code
│   │   ├── main.dart                 # App entry point
│   │   ├── app.dart                  # MaterialApp + routing
│   │   ├── core/                     # Core services (Dev B)
│   │   │   ├── api/                  # API client (HMAC, HTTP)
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── mock_api_client.dart
│   │   │   │   ├── api_endpoints.dart
│   │   │   │   └── hmac_signer.dart
│   │   │   ├── storage/              # Local encrypted storage
│   │   │   │   ├── secure_storage.dart
│   │   │   │   ├── hive_service.dart
│   │   │   │   └── verified_profile.dart
│   │   │   ├── ocr/                  # OCR integration layer
│   │   │   │   ├── ocr_service.dart
│   │   │   │   ├── mock_ocr_service.dart
│   │   │   │   └── document_type_detector.dart
│   │   │   ├── parser/               # Document parsers (Dart)
│   │   │   │   ├── aadhaar_parser.dart
│   │   │   │   ├── pan_parser.dart
│   │   │   │   ├── bank_statement_parser.dart
│   │   │   │   ├── bill_parser.dart
│   │   │   │   └── parser_registry.dart
│   │   │   ├── validation/           # Validation engine
│   │   │   │   ├── field_validator.dart
│   │   │   │   ├── cross_step_validator.dart
│   │   │   │   └── validation_result.dart
│   │   │   ├── theme/                # App-wide theming
│   │   │   │   ├── app_theme.dart
│   │   │   │   ├── app_colors.dart
│   │   │   │   └── app_typography.dart
│   │   │   └── utils/                # Shared utilities
│   │   │       ├── constants.dart
│   │   │       ├── formatters.dart
│   │   │       └── logger.dart
│   │   ├── features/                 # Feature modules (Dev B)
│   │   │   ├── auth/                 # Login / OTP screens
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   └── providers/
│   │   │   ├── dashboard/            # Main dashboard
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   └── providers/
│   │   │   ├── onboarding/           # 9-step onboarding flow
│   │   │   │   ├── screens/
│   │   │   │   │   ├── step1_basic_profile.dart
│   │   │   │   │   ├── step2_identity_kyc.dart
│   │   │   │   │   ├── step3_bank_verification.dart
│   │   │   │   │   ├── step4_utility_bills.dart
│   │   │   │   │   ├── step5_work_proof.dart
│   │   │   │   │   ├── step6_gov_schemes.dart
│   │   │   │   │   ├── step7_insurance.dart
│   │   │   │   │   ├── step8_tax_compliance.dart
│   │   │   │   │   └── step9_emi_loans.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── step_progress_bar.dart
│   │   │   │   │   ├── document_upload_card.dart
│   │   │   │   │   ├── ocr_result_overlay.dart
│   │   │   │   │   └── verification_badge.dart
│   │   │   │   └── providers/
│   │   │   │       ├── onboarding_provider.dart
│   │   │   │       └── step_state_provider.dart
│   │   │   ├── scoring/              # Score display
│   │   │   │   ├── screens/
│   │   │   │   │   ├── processing_screen.dart
│   │   │   │   │   └── score_result_screen.dart
│   │   │   │   └── providers/
│   │   │   ├── report/               # Final report display
│   │   │   │   ├── screens/
│   │   │   │   │   ├── report_screen.dart
│   │   │   │   │   └── pdf_export_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── pillar_chart.dart
│   │   │   │       ├── shap_factors_card.dart
│   │   │   │       └── llm_explanation_card.dart
│   │   │   └── loans/                # Loan marketplace
│   │   │       ├── screens/
│   │   │       └── widgets/
│   │   └── scoring/                  # Scoring engine (Dev A exports → Dev B integrates)
│   │       ├── models/               # m2cgen exported Dart files
│   │       │   ├── p1_scorer.dart
│   │       │   ├── p2_scorer.dart
│   │       │   ├── p3_scorer.dart
│   │       │   ├── p4_scorer.dart
│   │       │   ├── p6_scorer.dart
│   │       │   ├── scorecard_p5.dart
│   │       │   ├── scorecard_p7.dart
│   │       │   └── scoring_constants.dart
│   │       ├── feature_engineer.dart
│   │       ├── meta_learner.dart
│   │       ├── confidence_engine.dart
│   │       └── shap_lookup.dart
│   ├── assets/                       # Bundled assets
│   │   ├── models/                   # ML model files (Dev A provides)
│   │   ├── config/                   # Config JSONs
│   │   │   ├── shap_lookup.json
│   │   │   ├── meta_coefficients.json
│   │   │   ├── feature_means.json
│   │   │   └── lender_rules.json
│   │   ├── fonts/                    # Google Fonts (Inter, etc.)
│   │   └── images/                   # UI assets, icons
│   ├── test/                         # Flutter unit tests (Dev B)
│   └── pubspec.yaml
│
├── backend/                          # Backend server (Dev A OWNS)
│   ├── app/
│   │   ├── main.py                   # FastAPI entry point
│   │   ├── config.py                 # Environment config
│   │   ├── auth/                     # Authentication
│   │   │   ├── hmac_validator.py
│   │   │   └── rate_limiter.py
│   │   ├── api/                      # API routes
│   │   │   ├── otp_routes.py
│   │   │   ├── gov_verification.py
│   │   │   ├── bank_verification.py
│   │   │   ├── insurance_verification.py
│   │   │   └── report_routes.py
│   │   ├── services/                 # Business logic
│   │   │   ├── verification_service.py
│   │   │   ├── llm_service.py
│   │   │   └── prompt_builder.py
│   │   ├── models/                   # Pydantic schemas
│   │   │   ├── verification_schemas.py
│   │   │   ├── report_schemas.py
│   │   │   └── common_schemas.py
│   │   ├── db/                       # MongoDB layer
│   │   │   ├── connection.py
│   │   │   ├── seed_data.py          # Demo data seeder
│   │   │   └── collections.py
│   │   └── utils/
│   │       ├── logger.py
│   │       └── error_handlers.py
│   ├── tests/                        # Backend tests (Dev A)
│   │   ├── test_verification.py
│   │   ├── test_report.py
│   │   └── test_auth.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
│
├── ml_pipeline/                      # ML training pipeline (Dev A OWNS)
│   ├── data/
│   │   ├── synthetic_generator.py    # Generate 15K profiles
│   │   └── generated/                # Output CSVs
│   ├── training/
│   │   ├── train_pillars.py          # Train P1-P4, P6
│   │   ├── train_meta_learner.py     # Train LR meta-learner
│   │   ├── export_m2cgen.py          # Export to Dart
│   │   └── generate_shap.py          # Generate shap_lookup.json
│   ├── validation/
│   │   ├── golden_inference.py       # Generate golden test set
│   │   └── parity_test.py            # Python vs Dart parity
│   ├── output/                       # Trained artifacts
│   │   ├── dart_exports/             # m2cgen Dart files
│   │   ├── json_configs/             # shap_lookup, meta_coefficients
│   │   └── golden/                   # Golden inference JSONs
│   └── requirements.txt
│
├── contracts/                        # Shared data contracts (BOTH devs reference)
│   ├── api_contract.json             # All API request/response schemas
│   ├── feature_vector_contract.json  # 95-feature array specification
│   ├── verified_profile_contract.json# VerifiedProfile object schema
│   ├── score_output_contract.json    # Score + pillar output schema
│   └── report_payload_contract.json  # LLM report payload schema
│
├── demo_data/                        # Demo inputs and expected outputs (BOTH)
│   ├── inputs/                       # Copied from specification folders_new/Inputs
│   ├── expected_outputs/             # Predefined expected results
│   │   ├── demo_verified_profile.json
│   │   ├── demo_feature_vector.json
│   │   ├── demo_score_output.json
│   │   └── demo_report.json
│   └── seed_db.json                  # MongoDB seed data for demo
│
├── scripts/                          # Utility scripts (BOTH)
│   ├── seed_database.py              # Seed MongoDB with demo data
│   ├── verify_artifacts.py           # Check all assets present
│   └── run_parity_test.sh            # Run golden parity validation
│
├── docs/                             # Documentation (reference only)
│   ├── planning_new/                 # THIS folder (new planning)
│   ├── planning_old/                 # Legacy planning (reference)
│   ├── specification folders_new/    # Active specifications
│   └── specification folder_old/     # Legacy specs (reference)
│
├── .gitignore
├── README.md
└── artifact_manifest.json            # Tracks all bundled asset versions
```

---

## 2. DIRECTORY OWNERSHIP MAP

| Directory          | Owner  | Rule                                                    |
|-------------------|--------|----------------------------------------------------------|
| `app/lib/`        | Dev B  | Dev A NEVER modifies files here directly                 |
| `app/lib/scoring/models/` | Dev A exports → Dev B integrates | Dev A generates .dart files, Dev B copies them in |
| `app/assets/`     | Dev B  | Dev A provides files → Dev B places them in assets       |
| `backend/`        | Dev A  | Dev B NEVER modifies files here directly                 |
| `ml_pipeline/`    | Dev A  | Dev B has no business here                               |
| `contracts/`      | SHARED | Changes require BOTH devs to acknowledge                 |
| `demo_data/`      | SHARED | Both devs can add demo data                              |
| `scripts/`        | SHARED | Both devs can add utility scripts                        |

### 2.1 The One-Way Artifact Flow

```
Dev A (ml_pipeline/)
    │
    ├─ Trains models
    ├─ Exports via m2cgen → .dart files
    ├─ Generates shap_lookup.json
    ├─ Generates golden_inference.json
    │
    └─── Copies artifacts TO ──→ app/lib/scoring/models/ (Dev B integrates)
                                  app/assets/config/       (Dev B bundles)
```

**RULE**: Dev A NEVER directly commits to `app/lib/`. Instead:
1. Dev A places exported files in `ml_pipeline/output/dart_exports/`
2. Dev A notifies Dev B
3. Dev B copies files into `app/lib/scoring/models/` and `app/assets/config/`
4. Dev B runs the parity test
5. Dev B commits the integration

---

## 3. CODING CONVENTIONS

### 3.1 Dart (Flutter) — Dev B

```dart
// File naming: snake_case.dart
// Class naming: PascalCase
// Variable naming: camelCase
// Constants: SCREAMING_SNAKE_CASE or kPrefixed

// Example:
class StepProgressBar extends StatelessWidget {
  static const int kMaxSteps = 9;
  final int currentStep;
  // ...
}
```

- State management: **Riverpod** (ConsumerWidget, StateNotifier, Provider)
- Null safety: Always enabled
- Linting: `flutter_lints` or `very_good_analysis`
- No print() in production — use `Logger.d()`, `Logger.e()`

### 3.2 Python (Backend/ML) — Dev A

```python
# File naming: snake_case.py
# Class naming: PascalCase
# Variable naming: snake_case
# Constants: SCREAMING_SNAKE_CASE

# Example:
class VerificationService:
    MAX_RETRY_COUNT = 3
    def verify_aadhaar(self, aadhaar_number: str) -> dict:
        ...
```

- Type hints: REQUIRED on all function signatures
- Pydantic: REQUIRED for all API request/response schemas
- Linting: `ruff` or `flake8`
- Docstrings: Required on all public functions
- No bare `except:` — always catch specific exceptions

### 3.3 Shared Conventions

- All dates: ISO 8601 (`YYYY-MM-DD`) in contracts, `DD/MM/YYYY` in user-facing UI
- All amounts: `float` with 2 decimal precision
- All IDs: `string` type (never int for Aadhaar, PAN, etc.)
- All API responses: JSON with `status` field
- All errors: Structured `{ "error": "code", "message": "description" }`

---

## 4. NAMING RULES FOR FILES

| Category        | Pattern                         | Example                          |
|----------------|---------------------------------|-----------------------------------|
| Planning docs  | `NN_DESCRIPTIVE_NAME.md`        | `01_FOLDER_STRUCTURE.md`          |
| Phase docs     | `PHASE_N_NN_DESCRIPTION.md`     | `PHASE_1_01_DEV_A_TASKS.md`      |
| Component docs | `COMP_NN_COMPONENT_NAME.md`     | `COMP_01_SCORING_ENGINE.md`       |
| Dart files     | `snake_case.dart`               | `step1_basic_profile.dart`        |
| Python files   | `snake_case.py`                 | `gov_verification.py`             |
| Test files     | `test_module_name.dart/.py`     | `test_verification.py`            |
| Config files   | `snake_case.json`               | `shap_lookup.json`                |

---

## 5. ASSET MANIFEST

Every bundled asset must be tracked in `artifact_manifest.json`:

```json
{
  "version": "1.0.0",
  "last_updated": "2026-04-25",
  "artifacts": [
    {
      "filename": "p1_scorer.dart",
      "path": "app/lib/scoring/models/p1_scorer.dart",
      "owner": "dev_a",
      "version": "1.0",
      "sha256": "<hash>",
      "required_for_build": true
    },
    {
      "filename": "shap_lookup.json",
      "path": "app/assets/config/shap_lookup.json",
      "owner": "dev_a",
      "version": "1.0",
      "sha256": "<hash>",
      "required_for_build": true
    }
  ]
}
```

**Rule**: On every build, run `scripts/verify_artifacts.py` to validate
all required artifacts are present and checksums match.
