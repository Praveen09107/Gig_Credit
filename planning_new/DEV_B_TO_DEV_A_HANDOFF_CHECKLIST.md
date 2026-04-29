# Dev B ➔ Dev A: Handoff & Integration Checklist

**Status:** Dev B (Frontend & On-Device Engine) has successfully implemented and unit-tested 100% of the mathematical, orchestration, and UI components for the V3.0 Gig Worker Credit Scoring platform. 

This document serves as the exact checklist for **Dev A (Backend/ML)**. It details what Dev B has already built and exactly what JSON files and endpoints Dev A must provide to complete the final integration.

---

## 1. What Dev B Has Implemented & Tested

Dev A does **not** need to worry about any of the following; Dev B has completely solved these on the Flutter client:

*   **Null-Safety & Feature Extraction**: The `FeatureEngineer` extracts 115 features from the `VerifiedProfile`. If data is missing, Dev B automatically injects fallback medians.
*   **Piecewise Linear Interpolation**: Dev B wrote a custom `isotonicInterpolate` function in Dart that exactly mirrors `sklearn.isotonic.IsotonicRegression`. 
*   **Conformal Confidence Mapping**: Dev B's `ConfidenceEngine` automatically reads interval widths and pulls scores toward 0.5 based on High/Medium/Low confidence tiers.
*   **Meta-Learner Math**: Dev B implemented the exact sigmoid dot-product calculation for the 20-input meta-learner.
*   **XAI Rule Engines**: 
    *   **L1/L2/L3**: Dev B automatically converts raw SHAP arrays into actionable, color-coded UI cards (Immediate vs Behavioural).
    *   **L4**: Dev B calculates the 7-day and 1-3 month score trajectories.
    *   **L8**: Dev B has a boolean rule evaluator that reads causal triggers (`>=, <, ==`) and surfaces root-cause strings.
*   **Score Report UI**: All `fl_chart` radar graphs, waterfall charts, and animated gauges are built and mapped to the data model.

---

## 2. What Dev B Needs From Dev A (The Checklist)

Because the Flutter engine is perfectly prepared, Dev B is currently running on "mock" data. **Dev B is blocked on integration until Dev A provides the following exact files and endpoints.**

### A. The 10 Essential JSON Configuration Files
Dev A must export these files from their Jupyter/Python pipeline. Dev B will drop these directly into `app/assets/constants/` to instantly power the app.

- [ ] **`golden_100.json`**: A batch of 100 actual gig worker profiles with their expected `final_score`. Dev B will run a parity script against this to prove the Dart engine matches the Python engine within ±5 points.
- [ ] **`model_weights.json`**: The logistic regression coefficients (or simple weights) for the 5 ML pillars + the 20 coefficients and intercept for the Meta-Learner.
- [ ] **`isotonic_knots.json`**: The exact `x_knots` and `y_knots` arrays from the trained sklearn IsotonicRegression models for the 5 ML pillars.
- [ ] **`conformal_intervals.json`**: The `half_width` values for every pillar, segmented by `work_type` (e.g., driver, delivery, domestic).
- [ ] **`shap_lookup_v3.json`**: The 20-bin lookup tables for every feature so the on-device engine can assign SHAP impacts without running a TreeExplainer.
- [ ] **`actionability_tags.json`**: The dictionary assigning each feature as `immediate`, `behavioural`, or `non_actionable`, along with its `expected_gain_pts`.
- [ ] **`causal_chains.json`**: The array of L8 rules mapping specific feature thresholds to `root_cause` and `action_text` (e.g., "High EMI + Low Savings").
- [ ] **`feature_medians.json`**: A dictionary containing the actual median values for all 115 features. Dev B needs this to replace the dummy `ScoringConstants.featureDefaults`.

### B. The 3 API Endpoints
Dev B has already created the API service classes (`ScoringService` and `LoanService`) in Flutter. Dev A needs to deploy the Python backend to accept these exact requests:

- [ ] **`POST /api/score/batch` (Sync endpoint)**
  *   **Dev B sends**: Array of generated Score Reports.
  *   **Dev A must**: Ingest them, log them to the database, and return a 200 OK.
- [ ] **`POST /api/report/generate` (LLM Pipeline - COMP_20)**
  *   **Dev B sends**: `credit_score`, `pillar_scores`, top 3 positive SHAP features, and top 3 negative SHAP features.
  *   **Dev A must**: Inject this into the Groq Prompt Template, query the LLM, and return the Natural Language `explanation` and `suggestions` (or fallback template text if Groq fails).
- [ ] **`POST /api/loan/decision` (DiCE Pipeline)**
  *   **Dev B sends**: `profile_id`, `requested_amount`, `current_score`.
  *   **Dev A must**: Process the decision. If rejected, Dev A must return 3 actionable counterfactuals (e.g., "Increase savings by ₹2,000 to get approved").

---

### Integration Process
1. Dev A uploads the JSON files to the repo or hands them to Dev B.
2. Dev B replaces the mock constants in Dart.
3. Dev B runs `flutter test test/golden_parity_test.dart` using the `golden_100.json`.
4. If the test passes (variance < 5 points), the offline engine is mathematically certified for production!
