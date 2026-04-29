# V3.0 Dev B — Scoring Engine & Feature Engineer (CORRECTED)

## 6-Stage On-Device Pipeline

```
VerifiedProfile
  → STAGE 1: FeatureEngineer.extract()        → 95 base features
  → STAGE 1b: normaliseByWorkType()            → 5 features rescaled
  → STAGE 2: computeCrossPillarFeatures()      → 20 features added = 115 total
  → STAGE 3: ScoringEngine.scorePillars()      → 8 raw pillar scores (with cross-pillar routing)
  → P5 KYC gate check
  → Calibrate ML pillars (isotonic knots)
  → STAGE 4: ConformalConfidence.compute()     → 8 confidence values
  → Adjust scores by confidence
  → STAGE 5: MetaLearner.predict(20 inputs)    → probability
  → STAGE 6: Score mapping (300-900)
```

---

## B7: Feature Engineer Update

### `app/lib/scoring/features/feature_engineer.dart`

**Changes**:
1. Rename features to semantic names (comments)
2. Add P8 features (indices 88-94)
3. Add work-type normalisation (Stage 1)
4. Add cross-pillar computation (Stage 2)
5. Array size changes from 95 to 115

```dart
class FeatureEngineer {
  static const int baseFeatureCount = 95;
  static const int totalFeatureCount = 115;
  
  /// Extract all 115 features from verified profile
  static List<double> extract(
    VerifiedProfile profile,
    Map<String, dynamic> workTypeMedians,
  ) {
    final features = List<double>.filled(totalFeatureCount, 0.4);
    
    // ── P1: Income Stability (f0..f12) ──────────────
    features[0] = _computeIncomeNorm(profile);     // avg_monthly_income_norm
    features[1] = _computeIncomeCv(profile);        // income_stability_cv
    features[2] = _computeGrowthSlope(profile);     // income_growth_slope
    // ... (keep existing logic, rename comments)
    
    // ── P7: Social Accountability (f78..f87) — NOW 10 features ──
    features[78] = _communityStanding(profile);
    // ... (indices 78-87 only)
    
    // ── P8: Tax & Compliance (f88..f94) — NEW ──────
    features[88] = profile.taxInfo.isVerified ? 0.55 : 0.0;
    features[89] = profile.taxInfo.isVerified ? 0.70 : 0.0;
    features[90] = profile.taxInfo.isVerified ? 0.60 : 0.0;
    features[91] = (profile.kycInfo.isVerified && profile.bankInfo.isVerified) ? 0.80 : 0.0;
    features[92] = profile.govSchemesInfo.isVerified ? 0.30 : 0.0;
    features[93] = profile.workInfo.isVerified ? 0.20 : 0.0;
    features[94] = profile.taxInfo.isVerified ? 0.30 : 0.0;
    
    // ── STAGE 1: Work-Type Normalisation ──────────────
    _normaliseByWorkType(features, profile.personalInfo.workType, workTypeMedians);
    
    // ── STAGE 2: Cross-Pillar Features (f95..f114) ──────
    _computeCrossPillarFeatures(features);
    
    return features;
  }
  
  static void _normaliseByWorkType(
    List<double> f, String workType, Map<String, dynamic> medians,
  ) {
    final wt = medians[workType] ?? medians['platform_worker']!;
    f[1]  = (f[1]  / (wt['income_cv'] as double)).clamp(0.0, 2.0) / 2.0;
    f[2]  = (f[2]  / (wt['income_growth_norm'] as double)).clamp(0.0, 2.0) / 2.0;
    f[4]  = (f[4]  / (wt['gig_share_norm'] as double)).clamp(0.0, 2.0) / 2.0;
    f[28] = (f[28] / (wt['payment_gap_freq'] as double)).clamp(0.0, 2.0) / 2.0;
    f[47] = (f[47] / (wt['balance_variability'] as double)).clamp(0.0, 2.0) / 2.0;
  }
  
  static void _computeCrossPillarFeatures(List<double> f) {
    // Group A: Income × Debt
    f[95]  = f[28] * (1.0 - f[1]);
    f[96]  = (1.0 - f[1]) * f[29];
    f[97]  = (f[0] - f[28]).clamp(0.0, 1.0);
    f[98]  = f[2] * (1.0 - f[31]);
    // Group B: Payment × Savings
    f[99]  = (f[13] - f[37]).clamp(0.0, 1.0);
    f[100] = f[39] * f[13];
    f[101] = f[23] * f[43];
    // Group C: Resilience Composite
    f[102] = f[67]*0.35 + f[39]*0.40 + (1-f[28])*0.25;
    f[103] = (f[102] - f[28]).clamp(0.0, 1.0);
    f[104] = (f[67] + f[68]) * f[1];
    // Group D: Gig Stability Streaks
    f[105] = f[3] < f[13] ? f[3] : f[13]; // min
    f[106] = f[2] * f[15];
    f[107] = f[5] * f[23];
    f[108] = f[10] * f[13];
    // Group E: Formal Recognition
    f[109] = (f[79] + f[69]) * f[1];
    f[110] = f[88] * f[5];
    f[111] = _pillarMean(f, 78, 88) * f[0];
    // Group F: Temporal (defaults — no time-series data on-device)
    f[112] = 0.50;
    f[113] = 0.50;
    f[114] = 0.50;
  }
}
```

---

## B8: Scoring Engine — Cross-Pillar Feature Routing

### `app/lib/scoring/engine/scoring_engine.dart`

**Critical**: Each ML pillar scorer now takes base features + specific cross-pillar features.

```dart
class ScoringEngine {
  Map<String, double> scorePillars(List<double> f) {
    return {
      // P1 LightGBM: 13 base (0-12) + 4 cross-pillar (95,96,97,98) = 17
      'P1': p1.scoreP1([...f.sublist(0, 13), f[95], f[96], f[97], f[98]]).clamp(0.0, 1.0),
      
      // P2 XGBoost: 15 base (13-27) + 4 cross-pillar (105,106,107,108) = 19
      'P2': p2.scoreP2([...f.sublist(13, 28), f[105], f[106], f[107], f[108]]).clamp(0.0, 1.0),
      
      // P3 XGBoost shallow: 9 base (28-36) + 4 cross-pillar (95,96,97,98) = 13
      'P3': p3.scoreP3([...f.sublist(28, 37), f[95], f[96], f[97], f[98]]).clamp(0.0, 1.0),
      
      // P4 LightGBM: 12 base (37-48) + 4 cross-pillar (99,100,101,102) = 16
      'P4': p4.scoreP4([...f.sublist(37, 49), f[99], f[100], f[101], f[102]]).clamp(0.0, 1.0),
      
      // P5 Scorecard: 18 base (49-66) only, no cross-pillar
      'P5': p5.scoreP5(f.sublist(49, 67)).clamp(0.0, 1.0),
      
      // P6 ExtraTrees: 11 base (67-77) + 3 cross-pillar (102,103,104) = 14
      'P6': p6.scoreP6([...f.sublist(67, 78), f[102], f[103], f[104]]).clamp(0.0, 1.0),
      
      // P7 Scorecard: 10 base (78-87) only
      'P7': p7.scoreP7(f.sublist(78, 88)).clamp(0.0, 1.0),
      
      // P8 Scorecard: 7 base (88-94) only
      'P8': p8.scoreP8(f.sublist(88, 95)).clamp(0.0, 1.0),
    };
  }
}
```

---

## B10: Meta-Learner — 20 Inputs (CORRECTED)

### `app/lib/scoring/engine/meta_learner.dart`

```dart
class MetaLearner {
  static const int metaInputSize = 20;  // NOT 24

  static List<double> buildMetaInput(
    Map<String, double> pillarScores,
    Map<String, double> confidenceValues,
    List<double> features,
    List<int> top4CrossPillarIndices,
  ) {
    return [
      // 8 calibrated pillar scores
      pillarScores['P1']!, pillarScores['P2']!, pillarScores['P3']!, pillarScores['P4']!,
      pillarScores['P5']!, pillarScores['P6']!, pillarScores['P7']!, pillarScores['P8']!,
      // 8 conformal confidence values
      confidenceValues['P1']!, confidenceValues['P2']!, confidenceValues['P3']!, confidenceValues['P4']!,
      confidenceValues['P5']!, confidenceValues['P6']!, confidenceValues['P7']!, confidenceValues['P8']!,
      // 4 auto-selected cross-pillar features
      features[top4CrossPillarIndices[0]],
      features[top4CrossPillarIndices[1]],
      features[top4CrossPillarIndices[2]],
      features[top4CrossPillarIndices[3]],
    ];
  }
}
```

---

## B9: Conformal Confidence (CORRECTED)

### `app/lib/scoring/engine/confidence_engine.dart`

**Replaces old formula** `0.5 × completeness + 0.3 × reliability + 0.2 × consistency`

```dart
class ConfidenceEngine {
  /// Compute per-pillar confidence from conformal intervals
  static Map<String, double> computeConformalConfidence(
    Map<String, double> calibratedScores,
    String workType,
    Map<String, dynamic> conformalIntervals,
  ) {
    final confidence = <String, double>{};
    
    for (final pillar in ['P1','P2','P3','P4','P5','P6','P7','P8']) {
      final pillarData = conformalIntervals[pillar];
      if (pillarData == null) {
        confidence[pillar] = 1.0; // scorecards = perfect confidence
        continue;
      }
      final wtData = pillarData[workType] ?? pillarData['platform_worker'];
      final halfWidth = (wtData['half_width'] as num).toDouble();
      final intervalWidth = 2.0 * halfWidth;
      
      // Map interval width to confidence level
      if (intervalWidth <= 0.12) {
        confidence[pillar] = 1.0;       // HIGH
      } else if (intervalWidth <= 0.20) {
        confidence[pillar] = 0.75;      // MEDIUM — pull toward 0.50
      } else {
        confidence[pillar] = 0.50;      // LOW — neutralise toward 0.50
      }
    }
    
    // P5, P7, P8 scorecards always get confidence 1.0
    confidence['P5'] = 1.0;
    confidence['P7'] = 1.0;
    confidence['P8'] = 1.0;
    
    return confidence;
  }
  
  /// Adjust score by confidence (pull uncertain scores toward 0.50)
  static double adjustScore(double score, double confidence) {
    return score * confidence + 0.5 * (1.0 - confidence);
  }
}
```
