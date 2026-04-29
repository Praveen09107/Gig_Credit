# V3.0 Integration Plan (CORRECTED — Dev B Leads)

## Pre-Integration Checklist

### Dev A Must Deliver (ALL required before integration)
- [ ] `output/dart_export/p1_scorer.dart` — LightGBM m2cgen (17 features)
- [ ] `output/dart_export/p2_scorer.dart` — XGBoost m2cgen (19 features)
- [ ] `output/dart_export/p3_scorer.dart` — XGBoost shallow m2cgen (13 features)
- [ ] `output/dart_export/p4_scorer.dart` — LightGBM m2cgen (16 features)
- [ ] `output/dart_export/p6_scorer.dart` — ExtraTrees m2cgen (14 features)
- [ ] `output/dart_export/scorecard_p5.dart` — Hand-written (18 features, KYC gate)
- [ ] `output/dart_export/scorecard_p7.dart` — Hand-written (10 features)
- [ ] `output/dart_export/scorecard_p8.dart` — Hand-written (7 features)
- [ ] `output/dart_export/meta_learner_lr.dart` — LR dot-product (20 inputs)
- [ ] `output/dart_export/scoring_constants.dart` — Score mapping utilities
- [ ] `output/assets/shap_lookup_v3.json` — 115 features × 20 bins × 4 work types
- [ ] `output/assets/tabnet_attention.json` — Per-pillar attention weights
- [ ] `output/assets/calibration_knots.json` — 5 ML pillar isotonic knots
- [ ] `output/assets/conformal_intervals.json` — 5 pillars × 4 work types
- [ ] `output/assets/meta_lr_coefficients.json` — 20 coefficients + intercept + top4 indices
- [ ] `output/assets/pillar_weights.json` — 8 pillar weights
- [ ] `output/assets/actionability_tags.json` — 115 features, 3-tier tagging
- [ ] `output/assets/feature_display_names.json` — 115 human labels
- [ ] `output/assets/work_type_medians.json` — 4 work types × 5 constants
- [ ] `output/assets/causal_chains.json` — 15 causal rules
- [ ] `output/assets/loan_thresholds.json` — Per work_type × product thresholds
- [ ] `output/golden/golden_100.json` — 100 profiles with 6-stage expected results
- [ ] `dart analyze output/dart_export/` passes clean
- [ ] Backend running on port 8000 with all endpoints

### Dev B Must Deliver (ALL required before integration)
- [ ] All data models updated (ScoreReport, ScorePillar, Shap, Loan, KFS, etc.)
- [ ] `feature_engineer.dart` — 115 features + work-type norm + cross-pillar
- [ ] `scoring_engine.dart` — 8 pillars with cross-pillar routing
- [ ] `confidence_engine.dart` — Conformal confidence (not old formula)
- [ ] `meta_learner.dart` — 20-input LR call
- [ ] L1 pillar decomposition
- [ ] L2 enhanced SHAP lookup (work-type-aware)
- [ ] L3 actionable tagging (3-tier)
- [ ] L4 trajectory simulation
- [ ] L8 causal chain rules (on-device)
- [ ] `explanation_bundle.dart` — combines L1+L2+L3+L4+L8
- [ ] `score_pipeline.dart` — 6-stage orchestrator
- [ ] Score report UI (8 pillar cards, waterfall, radar, trajectory)
- [ ] 4 Loan screens (products, KFS, application, decision)
- [ ] API service classes (score + loan)

---

## Step I1: Copy Dev A Dart Scorers

```powershell
# From project root
copy "ml_pipeline\output\dart_export\p1_scorer.dart" "app\lib\scoring\models\p1_scorer.dart"
copy "ml_pipeline\output\dart_export\p2_scorer.dart" "app\lib\scoring\models\p2_scorer.dart"
copy "ml_pipeline\output\dart_export\p3_scorer.dart" "app\lib\scoring\models\p3_scorer.dart"
copy "ml_pipeline\output\dart_export\p4_scorer.dart" "app\lib\scoring\models\p4_scorer.dart"
copy "ml_pipeline\output\dart_export\p6_scorer.dart" "app\lib\scoring\models\p6_scorer.dart"
copy "ml_pipeline\output\dart_export\scorecard_p5.dart" "app\lib\scoring\models\scorecard_p5.dart"
copy "ml_pipeline\output\dart_export\scorecard_p7.dart" "app\lib\scoring\models\scorecard_p7.dart"
copy "ml_pipeline\output\dart_export\scorecard_p8.dart" "app\lib\scoring\models\scorecard_p8.dart"
copy "ml_pipeline\output\dart_export\meta_learner_lr.dart" "app\lib\scoring\models\meta_learner_lr.dart"
copy "ml_pipeline\output\dart_export\scoring_constants.dart" "app\lib\scoring\models\scoring_constants.dart"
```

## Step I2: Delete Old Files
```powershell
del "app\lib\scoring\models\meta_scorer.dart"
# Delete any old p1_scorer through p7_scorer that used XGBoost
```

## Step I3: Copy JSON Assets (10 files to app)
```powershell
xcopy "ml_pipeline\output\assets\shap_lookup_v3.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\tabnet_attention.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\calibration_knots.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\conformal_intervals.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\meta_lr_coefficients.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\pillar_weights.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\actionability_tags.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\feature_display_names.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\work_type_medians.json" "app\assets\constants\" /Y
xcopy "ml_pipeline\output\assets\causal_chains.json" "app\assets\constants\" /Y
```

## Step I4: Copy Golden Test
```powershell
copy "ml_pipeline\output\golden\golden_100.json" "app\test\golden\golden_100.json"
```

## Step I5: Update pubspec.yaml
```yaml
flutter:
  assets:
    - assets/constants/shap_lookup_v3.json
    - assets/constants/tabnet_attention.json
    - assets/constants/calibration_knots.json
    - assets/constants/conformal_intervals.json
    - assets/constants/meta_lr_coefficients.json
    - assets/constants/pillar_weights.json
    - assets/constants/actionability_tags.json
    - assets/constants/feature_display_names.json
    - assets/constants/work_type_medians.json
    - assets/constants/causal_chains.json
```

## Step I6: Verify Dart Analysis
```bash
cd app
dart analyze lib/scoring/
# MUST pass with zero errors
```

## Step I7: Run Golden Parity Test
```bash
flutter test test/golden_parity_test.dart
# All 100 profiles must match within ±5 score points
# All 8 pillar scores must match within ±0.02
```

## Step I8: Wire AssetLoader in main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load ALL 10 JSON constant files
  final shapLookup = await AssetLoader.loadJson('assets/constants/shap_lookup_v3.json');
  final calibKnots = await AssetLoader.loadJson('assets/constants/calibration_knots.json');
  final conformal = await AssetLoader.loadJson('assets/constants/conformal_intervals.json');
  final metaCoeffs = await AssetLoader.loadJson('assets/constants/meta_lr_coefficients.json');
  final pillarWeights = await AssetLoader.loadJson('assets/constants/pillar_weights.json');
  final actionTags = await AssetLoader.loadJson('assets/constants/actionability_tags.json');
  final displayNames = await AssetLoader.loadJson('assets/constants/feature_display_names.json');
  final workTypeMedians = await AssetLoader.loadJson('assets/constants/work_type_medians.json');
  final causalChains = await AssetLoader.loadJsonList('assets/constants/causal_chains.json');
  
  runApp(MyApp(
    shapLookup: shapLookup,
    calibrationKnots: calibKnots,
    conformalIntervals: conformal,
    metaCoeffs: metaCoeffs,
    pillarWeights: pillarWeights,
    actionTags: actionTags,
    displayNames: displayNames,
    workTypeMedians: workTypeMedians,
    causalRules: causalChains,
  ));
}
```

## Step I9: Test Backend
```bash
# Terminal 1
cd backend && uvicorn app.main:app --reload --port 8000

# Terminal 2
curl -X POST http://localhost:8000/api/v1/loan/products \
  -H "Content-Type: application/json" \
  -d '{"report_id":"GC-test","final_score":720,"work_type":"platform_worker"}'
# Verify: 3 products, risk-based pricing, max eligible amounts
```

## Step I10: Full Smoke Test on Device
1. Launch app on device/emulator
2. Complete onboarding (use test profile)
3. Generate score → verify:
   - [ ] 8 pillar cards appear (not 7)
   - [ ] Conformal intervals shown on pillar bars (±range)
   - [ ] Pillar waterfall chart (L1 decomposition) shows point contributions
   - [ ] 3-5 strengths display (green, with SHAP-backed impact)
   - [ ] 3-5 concerns display (orange, with action buttons for 🟢/🟡 items)
   - [ ] Non-actionable features NOT shown as improvement suggestions
   - [ ] Trajectory shows 3 paths (7-day, 1-3 month, full potential)
   - [ ] Causal chain message appears if trigger conditions met
4. Tap "Apply for Loan" → verify:
   - [ ] Products screen shows max eligible amount pre-computed
   - [ ] Ineligible products greyed with score gap shown
   - [ ] Risk-based interest rate displayed
5. Select product → verify:
   - [ ] KFS displays with ALL RBI-required fields
   - [ ] Checkbox must be checked before proceeding
6. Submit application → verify:
   - [ ] Approved: shows approval card + 3 upgrade counterfactuals
   - [ ] Rejected: shows AAN with reasons + 3 DiCE paths + alternative product
   - [ ] Amount adjustment path always present ("request ₹X instead")

## Step I11: Verify Audit Trail
```bash
curl http://localhost:8000/api/v1/audit/verify
# Should return: {"chain_valid": true, "total_records": N}
```

## Step I12: Final Cleanup
- Remove old imports of `meta_scorer.dart`
- Remove any `f_0`, `f_1` style references
- Update "7 pillars" strings to "8 pillars"
- Verify dark mode compatibility
- Check all 115 feature display names render correctly

---

## Conflict Resolution Matrix

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Scorer input size mismatch | Cross-pillar feature count wrong | Check V3_04 contract, re-export |
| JSON field missing | Schema not matching V3_05 | Regenerate from constants_exporter |
| Feature index off-by-one | Cross-pillar formula uses wrong index | Check V3_26 formulas |
| P5 always returns 0 | KYC gate triggered | Ensure test data has aadhaar + pan verified |
| Score ±5 mismatch in golden | Work-type normalisation not applied | Verify Stage 1 runs before Stage 3 |
| Meta-learner NaN | Missing top4 indices in JSON | Check `top4_cross_pillar_indices` field |
| Trajectory shows 0 pts gain | All negative SHAPs are non_actionable | Check actionability_tags.json has 🟢 items |
| Causal chain never fires | Trigger thresholds too strict | Adjust trigger values in causal_chains.json |
| Backend 500 on loan/apply | Loan model not loaded | Check loan_lgbm.pkl exists at expected path |
