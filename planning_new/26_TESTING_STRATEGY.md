# ================================================================================
# GIGCREDIT — TESTING STRATEGY
# Document 26 | planning_new
# ================================================================================

## 1. TESTING PHILOSOPHY FOR HACKATHON

**Reality**: In a 48-hour hackathon, exhaustive testing is impossible.
**Strategy**: Test the CRITICAL PATH that the demo will follow.

Priority:
1. **Demo flow works** (highest priority)
2. **Scoring produces reasonable numbers** (high)
3. **Backend APIs respond correctly** (high)
4. **Edge cases don't crash the app** (medium)
5. **Error states show user-friendly messages** (medium)

---

## 2. DEV A — BACKEND TESTS

### Unit Tests (backend/tests/)

```python
# test_verification.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_health():
    async with AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.get("/health")
        assert resp.status_code == 200
        assert resp.json()["status"] == "ok"

@pytest.mark.asyncio
async def test_aadhaar_verify_valid():
    async with AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.post("/gov/aadhaar/verify", json={"aadhaar": "123456789012"})
        assert resp.status_code == 200
        assert resp.json()["status"] == "valid"
        assert "name" in resp.json()

@pytest.mark.asyncio
async def test_aadhaar_verify_not_found():
    async with AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.post("/gov/aadhaar/verify", json={"aadhaar": "000000000000"})
        assert resp.status_code == 404

@pytest.mark.asyncio
async def test_aadhaar_verify_invalid_format():
    async with AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.post("/gov/aadhaar/verify", json={"aadhaar": "123"})
        assert resp.status_code == 400
```

Run: `cd backend && pytest tests/ -v`

### Integration Test (curl)
```bash
# Quick smoke test for deployed backend
curl -s https://gigcredit-api.onrender.com/health
curl -s -X POST https://gigcredit-api.onrender.com/gov/aadhaar/verify -H "Content-Type: application/json" -d '{"aadhaar":"123456789012"}'
curl -s -X POST https://gigcredit-api.onrender.com/api/report/generate -H "Content-Type: application/json" -d '{"credit_score":682,"grade":"B","risk_level":"Medium","work_type":"platform_worker","language":"English","pillar_scores":{"income_stability":72},"positive_factors":[],"negative_factors":[],"confidence_level":"High"}'
```

---

## 3. DEV B — FLUTTER TESTS

### Unit Tests (app/test/)

```dart
// test/scoring/feature_engineer_test.dart
void main() {
  test('Feature engineering produces 95 features', () {
    final profile = MockVerifiedProfile.platformWorker();
    final features = FeatureEngineer().engineer(profile);
    expect(features.length, 95);
  });
  
  test('All features are in [0, 1] range', () {
    final profile = MockVerifiedProfile.platformWorker();
    final features = FeatureEngineer().engineer(profile);
    for (final f in features) {
      expect(f, greaterThanOrEqualTo(0.0));
      expect(f, lessThanOrEqualTo(1.0));
    }
  });
  
  test('No NaN in features', () {
    final profile = MockVerifiedProfile.platformWorker();
    final features = FeatureEngineer().engineer(profile);
    for (final f in features) {
      expect(f.isNaN, false);
    }
  });
}

// test/scoring/meta_learner_test.dart
void main() {
  test('Meta-learner produces score 300-900', () {
    final pillars = {
      'p1': 0.72, 'p2': 0.68, 'p3': 0.55, 'p4': 0.61,
      'p5': 0.78, 'p6': 0.45, 'p7': 0.60,
    };
    final score = MetaLearner.fromAsset().predict(pillars, 'platform_worker');
    expect(score, greaterThanOrEqualTo(300));
    expect(score, lessThanOrEqualTo(900));
  });
}
```

Run: `cd app && flutter test`

### Widget Tests (app/test/widget/)

```dart
// test/widget/step_progress_bar_test.dart
void main() {
  testWidgets('StepProgressBar shows 9 steps', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StepProgressBar(currentStep: 3, totalSteps: 9),
    ));
    expect(find.byType(StepProgressBar), findsOneWidget);
  });
}
```

---

## 4. PARITY TEST (Python vs Dart)

```dart
// test/scoring/parity_test.dart
void main() {
  test('Python and Dart scoring match within 1e-5', () async {
    final golden = await loadGoldenInference();
    
    for (final testCase in golden) {
      final features = List<double>.from(testCase['features']);
      
      // Run Dart scoring
      final dartPillars = ScoringEngine().scorePillars(features);
      
      // Compare with Python golden values
      final pyPillars = testCase['pillar_scores'];
      for (final p in dartPillars.keys) {
        final diff = (dartPillars[p]! - pyPillars[p]).abs();
        expect(diff, lessThan(1e-5), reason: 'Pillar $p mismatch: $diff');
      }
    }
  });
}
```

---

## 5. DEMO FLOW TEST

The most important test: run the demo flow manually on a real device.

### Checklist:
```
□ App installs and launches
□ Login → enter mobile → OTP → dashboard
□ Dashboard → Get Started → Step 1
□ Step 1 → fill all fields → Continue
□ Step 2 → upload Aadhaar + PAN + selfie → Verified ✓
□ Step 3 → upload bank statement → Parsed + Verified ✓
□ Step 4 → upload utility bills → On-time ratios shown
□ Step 5 → upload work proof → Verified ✓
□ Step 6 → enter eShram UAN → Verified ✓
□ Step 7 → upload insurance → Active ✓
□ Step 8 → upload ITR → Filed ✓
□ Step 9 → declare loans → Match ✓
□ Processing screen → animated progress
□ Score reveal → 682, Grade B, Medium Risk
□ Report → 7 pillars + SHAP + LLM explanation
□ PDF export → readable PDF generated
□ Loans → 3 offers shown
□ Apply → pre-filled form → submit
□ NO CRASHES anywhere in the flow
```
