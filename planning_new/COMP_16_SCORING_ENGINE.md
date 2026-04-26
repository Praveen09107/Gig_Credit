# ================================================================================
# GIGCREDIT — COMPONENT: SCORING ENGINE SPECIFICATION
# Document 16 | planning_new
# Owner: Dev A (exports) → Dev B (integrates)
# ================================================================================

## 1. SCORING PIPELINE EXECUTION ORDER

```
VerifiedProfile
    │
    ▼
[1] FeatureEngineer.engineer(profile) → List<double>[95]
    │
    ▼
[2] sanitizeFeatures(features) → NaN → 0.40, clamp [0,1]
    │
    ▼
[3] Score 7 Pillars (sequential):
    P1 = scoreP1(features[0..12])      ← XGBoost m2cgen
    P2 = scoreP2(features[13..27])     ← XGBoost m2cgen
    P3 = scoreP3(features[28..36])     ← XGBoost m2cgen
    P4 = scoreP4(features[37..48])     ← XGBoost m2cgen
    P5 = scorecardP5(features[49..66]) ← Dart scorecard
    P6 = scoreP6(features[67..77])     ← RandomForest m2cgen
    P7 = scorecardP7(features[78..94]) ← Dart scorecard
    │
    ▼
[4] Apply Debt Band Cap:
    if emi_to_income_ratio > 0.80 → P3 = min(P3, 0.30)
    │
    ▼
[5] Validate Pillar Outputs:
    All pillars clamped to [0.0, 1.0]
    NaN check → replace with 0.50
    │
    ▼
[6] Confidence Adjustment:
    adjusted[p] = raw[p] × confidence[p] + 0.50 × (1 - confidence[p])
    If confidence[p] < 0.30 → exclude pillar (set to 0.50 neutral)
    │
    ▼
[7] Meta-Learner:
    Input = [7 adjusted pillars, 4 work-type one-hot, 8 interactions]
    logit = dot(input, weights) + intercept
    probability = sigmoid(logit)
    score = round(probability × 600) + 300
    │
    ▼
[8] Grade Assignment:
    800-900 = S (Exceptional)
    720-799 = A (Excellent)
    640-719 = B (Good)
    560-639 = C (Average)
    480-559 = D (Below Average)
    300-479 = E (Poor)
```

---

## 2. FEATURE SANITIZATION

```dart
List<double> sanitizeFeatures(List<double> features) {
  return features.map((f) {
    if (f.isNaN || f.isInfinite) return 0.40;
    return f.clamp(0.0, 1.0);
  }).toList();
}
```

---

## 3. HARD SCORING BLOCKS

Before ANY scoring begins, check:
```dart
bool canScore(VerifiedProfile profile) {
  // Block 1: Identity must be verified
  if (!profile.identity.aadhaarVerified) return false;
  
  // Block 2: Face match (placeholder always passes)
  if (profile.identity.faceMatchScore < 0.70) return false;
  
  // Block 3: Bank statement must exist with >= 30 transactions
  if (profile.bank.primary.transactions.length < 30) return false;
  
  return true;
}
```

If any block triggers → show: "Please complete required verification to proceed."

---

## 4. META-LEARNER INPUT SPECIFICATION

19 values total:

| Index | Name                    | Source            |
|-------|------------------------|-------------------|
| 0     | P1 adjusted score      | Pillar scorer     |
| 1     | P2 adjusted score      | Pillar scorer     |
| 2     | P3 adjusted score      | Pillar scorer     |
| 3     | P4 adjusted score      | Pillar scorer     |
| 4     | P5 adjusted score      | Pillar scorer     |
| 5     | P6 adjusted score      | Pillar scorer     |
| 6     | P7 adjusted score      | Pillar scorer     |
| 7     | is_platform_worker     | 1.0 or 0.0        |
| 8     | is_vendor              | 1.0 or 0.0        |
| 9     | is_tradesperson        | 1.0 or 0.0        |
| 10    | is_freelancer          | 1.0 or 0.0        |
| 11    | P1 × is_platform       | Interaction        |
| 12    | P2 × is_platform       | Interaction        |
| 13    | P1 × is_vendor         | Interaction        |
| 14    | P2 × is_vendor         | Interaction        |
| 15    | P1 × is_tradesperson   | Interaction        |
| 16    | P2 × is_tradesperson   | Interaction        |
| 17    | P1 × is_freelancer     | Interaction        |
| 18    | P2 × is_freelancer     | Interaction        |

---

## 5. SCORING PERFORMANCE TARGETS

- Feature engineering: < 50ms
- All 7 pillar scores: < 20ms total
- Meta-learner: < 5ms
- SHAP lookup: < 10ms
- **Total scoring pipeline: < 100ms on mid-range Android**

---

## 6. DEMO FALLBACK

If scoring produces unexpected results:
```dart
ScoreResult getDemoFallback() {
  return ScoreResult(
    finalScore: 682,
    grade: 'B',
    riskBand: 'Medium',
    pillarScores: {
      'p1': 0.72, 'p2': 0.68, 'p3': 0.55, 'p4': 0.61,
      'p5': 0.78, 'p6': 0.45, 'p7': 0.60,
    },
  );
}
```
