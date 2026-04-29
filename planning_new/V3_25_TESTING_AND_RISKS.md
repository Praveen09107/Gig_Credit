# V3.0 Testing Strategy & Risk Mitigation (CORRECTED)

## Testing Strategy

### 1. Python Pipeline Tests (Dev A)

```bash
# After each training step, verify:
python -m generation.synthetic_data_generator
# Check: 15K × 117 CSV, all features [0,1], no NaN
# Check: work_type_medians.json exported
# Check: 20 cross-pillar features computed (f95-f114)

python -m training.train_pillars_v3
# Check: P1 LightGBM: R² > 0.80, RMSE < 0.10
# Check: P2 XGBoost: R² > 0.80, RMSE < 0.10
# Check: P3 XGBoost shallow: R² > 0.70 (shallow = less expressive, ok)
# Check: P4 LightGBM: R² > 0.80, RMSE < 0.10
# Check: P6 ExtraTrees: R² > 0.75, RMSE < 0.12

python -m training.calibration
# Check: ECE < 0.05 for all 5 ML pillars
# Check: Conformal coverage ≥ 88% for all pillar × work_type combos

python -m training.meta_learner_v3
# Check: AUC-ROC > 0.88, accuracy > 0.82

python -m explainability.shap_extractor
# Check: 115 entries in shap_lookup_v3.json
# Check: 20 bins per entry, 4 work types per entry
# Check: No NaN in any SHAP array

python -m export.export_m2cgen_v3
# Check: dart analyze output/dart_export/ → zero errors
# Check: 5 ML scorer files + 3 scorecard files + 1 meta_learner + 1 constants

python -m export.constants_exporter
# Check: 11 JSON files present
# Check: actionability_tags.json has 115 entries with 3 tiers

python -m export.golden_test_v3
# Check: 100 profiles, all fields populated
# Check: Scores distributed across 300-900 range

python -m loan.loan_data_generator
# Check: 50K × 22 CSV, all valid

python -m loan.loan_lgbm_trainer
# Check: AUC > 0.82

python -m loan.threshold_calibrator
# Check: 12 entries (3 products × 4 work types)
```

### 2. Golden Parity Test (Dev B, after integration)

```dart
// test/golden_parity_test.dart
void main() {
  final goldenData = jsonDecode(File('test/golden/golden_100.json').readAsStringSync());
  
  for (final profile in goldenData) {
    test('Profile ${profile["id"]}', () {
      final features95 = List<double>.from(profile['features_95']);
      final features115 = FeatureEngineer.extractFromRaw(features95, profile['work_type'], medians);
      
      // Stage 3: Score pillars
      final engine = ScoringEngine();
      final rawPillars = engine.scorePillars(features115);
      
      // Verify raw pillar scores
      for (final p in ['P1','P2','P3','P4','P5','P6','P7','P8']) {
        expect(rawPillars[p], closeTo(profile['expected_pillars_raw'][p], 0.02),
          reason: '$p raw score mismatch');
      }
      
      // Stages 4-6: Full pipeline
      final result = ScorePipeline.runSync(features115, profile['work_type']);
      
      // Verify final score within ±5 points
      expect(result.finalScore, closeTo(profile['expected_score'], 5),
        reason: 'Final score mismatch');
      
      // Verify grade matches
      expect(result.grade, equals(profile['expected_grade']),
        reason: 'Grade mismatch');
    });
  }
}
```

### 3. Backend API Tests (Dev A)

```python
# test_scoring_api.py
def test_store_score():
    resp = client.post("/api/v1/score/store", json={
        "user_id": "test_user",
        "final_score": 720,
        "grade": "B+",
        "pillar_scores": {"P1": 0.72, "P2": 0.78, "P3": 0.55, "P4": 0.60, 
                          "P5": 0.85, "P6": 0.45, "P7": 0.52, "P8": 0.30},
        "feature_vector": [0.45] * 115,
        "work_type": "platform_worker",
        "probability": 0.68,
    })
    assert resp.status_code == 200
    assert "report_id" in resp.json()

def test_loan_products():
    resp = client.post("/api/v1/loan/products", json={
        "report_id": "GC-test", "final_score": 720, "work_type": "platform_worker"
    })
    assert resp.status_code == 200
    products = resp.json()["products"]
    assert len(products) == 3
    # Emergency and Bridge should be eligible, Growth should not
    assert products[0]["eligible"] == True
    assert products[1]["eligible"] == True
    assert products[2]["eligible"] == False
    # Verify max_eligible_amount is pre-computed
    assert "max_eligible_amount" in products[0]

def test_loan_rejection_has_aan():
    resp = client.post("/api/v1/loan/apply", json={
        "report_id": "GC-low-dscr",
        "product_id": "emergency_micro",
        "requested_amount": 25000,
        "tenure_months": 3,
        "kfs_id": "KFS-test",
        "kfs_acknowledged": True,
    })
    result = resp.json()
    assert result["decision"] == "rejected"
    assert "aan" in result
    assert "counterfactual_paths" in result
    assert len(result["counterfactual_paths"]) == 3
    # Amount adjustment path always present
    assert any(p["type"] == "amount_adjustment" for p in result["counterfactual_paths"])

def test_audit_trail():
    resp = client.get("/api/v1/audit/verify")
    assert resp.json()["chain_valid"] == True
```

### 4. UI Smoke Tests (Dev B)

```
[ ] App launches without crash
[ ] Score gauge animates from 300 to final
[ ] 8 pillar cards rendered (not 7)
[ ] Pillar waterfall chart (L1) shows point contributions that sum to score
[ ] Radar chart has 8 axes with conformal band
[ ] Top 3 strengths show with green cards
[ ] Top 3 concerns show with orange cards (🟢🟡 only)
[ ] No non-actionable feature shown as improvement
[ ] Trajectory shows 3 paths with different horizons
[ ] Causal insight card appears when trigger conditions met
[ ] Loan products show max eligible amount
[ ] Ineligible products greyed with score gap
[ ] KFS shows all RBI fields
[ ] KFS checkbox blocks proceed when unchecked
[ ] Application slider capped at max_eligible_amount
[ ] Approved decision shows approval card + upgrade counterfactual
[ ] Rejected decision shows AAN + 3 DiCE paths + alternative offer
[ ] Amount adjustment path always present in rejection
[ ] Dark mode works on all screens
```

---

## Risk Mitigation Matrix

| # | Risk | Probability | Impact | Mitigation | Owner |
|---|------|-------------|--------|------------|-------|
| 1 | m2cgen can't export LightGBM | Low | HIGH | Test m2cgen+LightGBM first day; fallback: ONNX+Dart FFI | Dev A |
| 2 | m2cgen can't export ExtraTrees | Low | HIGH | Test m2cgen+sklearn first day; fallback: manual tree extraction | Dev A |
| 3 | Feature index off-by-one in cross-pillar | Medium | HIGH | Golden test catches this immediately | Both |
| 4 | Conformal intervals too wide | Medium | Medium | Fall back to fixed confidence (0.8) | Dev A |
| 5 | SHAP JSON too large (>2MB) | Medium | Medium | Reduce to 10 bins, skip Group F features | Dev A |
| 6 | DiCE counterfactuals timeout | Low | Medium | Pre-compute 3 templates, not dynamic | Dev A |
| 7 | Causal chains never trigger | Medium | Low | Loosen trigger thresholds, add more rules | Dev A |
| 8 | LLM translation unavailable | Medium | Low | Template-based fallback (L10 graceful degrade) | Dev A |
| 9 | Fairness violation detected | Low | HIGH | Auto-mitigate (Hardt per-group thresholds) | Dev A |
| 10 | Score ±5 golden test failure | Medium | HIGH | Debug stage-by-stage, fix specific stage | Both |
| 11 | P5 always returns 0 | Medium | Medium | Ensure test data has Aadhaar+PAN verified | Both |
| 12 | Meta-learner NaN | Low | HIGH | Validate top4_cross_pillar_indices exist in JSON | Both |
| 13 | Loan model overtrained | Medium | Medium | 5-fold cross-validation + AUC check | Dev A |
| 14 | Risk-based pricing edge cases | Low | Medium | Clamp rates to 12-24%, catch score=0 | Dev A |

---

## Fallback Plan (Absolute Worst Case)

If ML pipeline fails entirely on Day 1:
1. Keep P5/P7/P8 scorecards (always work)
2. Use WEIGHTED AVERAGE for P1-P4/P6 (instead of ML models)
3. Skip cross-pillar features (use 95 base only)
4. Skip conformal intervals (use fixed confidence=0.8)
5. Use simple weighted sum instead of meta-learner
6. This gives a working score — just less accurate

**Recovery**: Fix ML models on Day 2, re-export, re-integrate. Day 3 for polishing.
