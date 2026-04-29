# V3.0 Dev B — Score Pipeline Rewrite (CORRECTED — 6 Stages)

## File: `app/lib/scoring/score_pipeline.dart`

## 6-Stage Pipeline (matches user's spec exactly)

```dart
class ScorePipeline {
  
  /// Run the complete 6-stage scoring pipeline
  static Future<ScoreReportModel> run(
    VerifiedProfile profile, {
    required Map<String, dynamic> shapLookup,
    required Map<String, dynamic> calibrationKnots,
    required Map<String, dynamic> conformalIntervals,
    required Map<String, dynamic> metaCoeffs,
    required Map<String, dynamic> actionTags,
    required Map<String, dynamic> pillarWeightsJson,
    required Map<String, dynamic> displayNames,
    required Map<String, dynamic> workTypeMedians,
    required List<dynamic> causalRules,
  }) async {
    final sw = Stopwatch()..start();
    
    // ────────────────────────────────────────────────────
    // STAGE 1: Feature Engineering + Work-Type Normalisation
    // ────────────────────────────────────────────────────
    // extract() internally does:
    //   1. Compute 95 base features from VerifiedProfile
    //   2. Normalise 5 features by work-type medians
    //   3. Compute 20 cross-pillar features (indices 95-114)
    //   → Returns 115-element feature vector
    final features = FeatureEngineer.extract(profile, workTypeMedians);
    
    final workType = profile.personalInfo.workType.isNotEmpty
        ? profile.personalInfo.workType : 'platform_worker';
    
    // ────────────────────────────────────────────────────
    // STAGE 3: Five Pillar Models (parallel)
    // ────────────────────────────────────────────────────
    // Each scorer receives base features + routed cross-pillar features
    final engine = ScoringEngine();
    final rawPillars = engine.scorePillars(features);
    
    // P5 KYC Gate: if Aadhaar or PAN not verified → P5 = 0
    if (features[49] < 0.5 || features[50] < 0.5) {
      rawPillars['P5'] = 0.0;
    }
    
    // Calibrate ML pillars via isotonic knots (P1,P2,P3,P4,P6 only)
    final calibratedPillars = engine.calibratePillars(rawPillars, calibrationKnots);
    
    // ────────────────────────────────────────────────────
    // STAGE 4: Conformal Prediction Confidence Engine
    // ────────────────────────────────────────────────────
    // Returns per-pillar confidence values from conformal intervals
    // Replaces old manual formula (0.5×completeness + 0.3×reliability + 0.2×consistency)
    final confidenceValues = ConfidenceEngine.computeConformalConfidence(
      calibratedPillars, workType, conformalIntervals,
    );
    
    // Adjust scores by confidence (pull uncertain toward 0.50)
    final adjustedPillars = <String, double>{};
    for (final key in calibratedPillars.keys) {
      adjustedPillars[key] = ConfidenceEngine.adjustScore(
        calibratedPillars[key]!, confidenceValues[key]!,
      );
    }
    
    // Overall confidence (weighted average)
    final pillarWeights = <String, double>{};
    for (final e in pillarWeightsJson.entries) {
      pillarWeights[e.key] = (e.value as num).toDouble();
    }
    final overallConfidence = pillarWeights.entries.fold(0.0, (sum, e) =>
        sum + (confidenceValues[e.key] ?? 1.0) * e.value) /
        pillarWeights.values.fold(0.0, (s, v) => s + v);
    
    // ────────────────────────────────────────────────────
    // STAGE 5: Logistic Meta-Learner → probability
    // ────────────────────────────────────────────────────
    // 20 inputs: 8 pillar scores + 8 confidence values + 4 cross-pillar features
    final coefficients = List<double>.from(metaCoeffs['coefficients']);
    final intercept = (metaCoeffs['intercept'] as num).toDouble();
    final top4Indices = List<int>.from(metaCoeffs['top4_cross_pillar_indices']);
    
    final metaInput = MetaLearner.buildMetaInput(
      adjustedPillars, confidenceValues, features, top4Indices,
    );
    final probability = predictMeta(metaInput, coefficients, intercept);
    
    // ────────────────────────────────────────────────────
    // STAGE 6: Score Mapping (300-900) + Grade + Risk Band
    // ────────────────────────────────────────────────────
    final finalScore = probabilityToScore(probability);
    final grade = scoreToGrade(finalScore);
    final riskBand = scoreToRiskLevel(finalScore);
    
    // ────────────────────────────────────────────────────
    // ON-DEVICE EXPLAINABILITY: L1 + L2 + L3 + L4 + L8
    // ────────────────────────────────────────────────────
    final explanation = ExplanationBundle.compute(
      features: features,
      featureNames: FEATURE_NAMES_115,
      workType: workType,
      adjustedPillars: adjustedPillars,
      pillarWeights: pillarWeights,
      metaCoefficients: coefficients.sublist(0, 8), // first 8 = pillar coefficients
      finalScore: finalScore,
      grade: grade,
      shapLookup: shapLookup,
      actionTags: actionTags,
      causalRules: causalRules,
    );
    
    // ────────────────────────────────────────────────────
    // BUILD ScoreReportModel
    // ────────────────────────────────────────────────────
    sw.stop();
    
    final pillars = _buildPillarModels(
      adjustedPillars, calibratedPillars, rawPillars,
      confidenceValues, pillarWeights, conformalIntervals, workType,
    );
    
    return ScoreReportModel(
      finalScore: finalScore,
      grade: grade,
      riskBand: riskBand,
      proofId: 'GC-${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      overallConfidence: overallConfidence,
      probability: probability,
      workType: workType,
      pillars: pillars,
      topStrengths: explanation.topStrengths.map(_toShapModel).toList(),
      topConcerns: explanation.topConcerns.map(_toShapModel).toList(),
      actionableItems: explanation.actions,
      conformalIntervals: _buildConformalMap(conformalIntervals, workType),
      tailoredSuggestions: explanation.actions.map((a) => a.actionText).toList(),
      pillarContributions: explanation.pillarContributions,
      trajectory: explanation.trajectory,
      causalChains: explanation.causalChains,
      computeTimeMs: sw.elapsedMicroseconds / 1000.0,
    );
  }
  
  // ────────────────────────────────────────────────────
  // Helper: Build 8 ScorePillarModel objects
  // ────────────────────────────────────────────────────
  static List<ScorePillarModel> _buildPillarModels(
    Map<String, double> adjusted,
    Map<String, double> calibrated,
    Map<String, double> raw,
    Map<String, double> confidence,
    Map<String, double> weights,
    Map<String, dynamic> conformalData,
    String workType,
  ) {
    const config = {
      'P1': {'title': 'Income Stability', 'subtitle': 'Earnings & growth', 'max': 150},
      'P2': {'title': 'Payment Discipline', 'subtitle': 'Bills & EMI history', 'max': 125},
      'P3': {'title': 'Debt Management', 'subtitle': 'EMI & obligations', 'max': 85},
      'P4': {'title': 'Savings Behaviour', 'subtitle': 'Savings & emergency', 'max': 90},
      'P5': {'title': 'Work & Identity', 'subtitle': 'KYC & work proof', 'max': 70},
      'P6': {'title': 'Financial Resilience', 'subtitle': 'Insurance & safety', 'max': 70},
      'P7': {'title': 'Social Accountability', 'subtitle': 'Community & trust', 'max': 55},
      'P8': {'title': 'Tax & Compliance', 'subtitle': 'ITR & registrations', 'max': 55},
    };
    
    return config.entries.map((e) {
      final code = e.key;
      final cfg = e.value;
      final maxScore = cfg['max'] as int;
      final adj = adjusted[code] ?? 0.4;
      
      // Get conformal bounds
      double? confLow, confHigh;
      final pillarConf = conformalData[code];
      if (pillarConf != null) {
        final wtConf = pillarConf[workType] ?? pillarConf['platform_worker'];
        if (wtConf != null) {
          final hw = (wtConf['half_width'] as num).toDouble();
          confLow = ((adj - hw) * maxScore).clamp(0, maxScore).toDouble();
          confHigh = ((adj + hw) * maxScore).clamp(0, maxScore).toDouble();
        }
      }
      
      return ScorePillarModel(
        code: code,
        title: cfg['title'] as String,
        subtitle: cfg['subtitle'] as String,
        score: (adj * maxScore).round(),
        maxScore: maxScore,
        rawScore: raw[code] ?? 0.4,
        calibratedScore: calibrated[code] ?? 0.4,
        conformalLow: confLow,
        conformalHigh: confHigh,
        confidence: confidence[code] ?? 1.0,
        weight: weights[code] ?? 0.1,
        attention: 0.0,
      );
    }).toList();
  }
}
```

## Key Differences from Old Pipeline
| Aspect | Old | New |
|--------|-----|-----|
| Pillars | 7 | 8 |
| Features | 95 | 115 (95 base + 20 cross-pillar) |
| Work-type normalisation | None | Stage 1 (5 features rescaled) |
| Cross-pillar | None | Stage 2 (20 interaction features) |
| Pillar models | All XGBoost | P1:LightGBM, P2:XGBoost, P3:XGBoost-shallow, P4:LightGBM, P6:ExtraTrees |
| Cross-pillar routing | None | Each ML scorer gets its routed cross-pillar features |
| P5 gate | None | KYC gate (Aadhaar+PAN required) |
| Calibration | None | Isotonic regression (5 ML pillars) |
| Confidence | Manual formula | Conformal prediction (per pillar × work type) |
| Meta-learner | XGBoost m2cgen (24 inputs) | LR dot-product (20 inputs: 8P+8conf+4cross) |
| On-device XAI | SHAP only | L1 decomposition + L2 SHAP + L3 actionable + L4 trajectory + L8 causal |
| JSON assets | 1 (shap_lookup) | 10 JSON files loaded |
