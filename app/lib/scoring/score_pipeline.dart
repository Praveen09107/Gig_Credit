
import '../models/verified_profile/verified_profile.dart';
import '../models/score_report_model.dart';
import '../models/score_pillar_model.dart';
import '../models/tailored_suggestion.dart';
import 'features/feature_engineer.dart';
import 'engine/scoring_engine.dart';
import 'engine/confidence_engine.dart';
import 'engine/meta_learner.dart';
import 'explainability/explanation_bundle.dart';

class ScorePipeline {
  /// Executes the 6-stage V3 pipeline
  static ScoreReportModel execute({
    required VerifiedProfile profile,
    required String workType,
    required Map<String, dynamic> calibrationKnotsJson,
    required Map<String, dynamic> conformalIntervalsJson,
    required Map<String, dynamic> metaJson,
    required Map<String, dynamic> weightsJson,
    required Map<String, dynamic> shapLookupJson,
    required Map<String, dynamic> displayNamesJson,
    required Map<String, dynamic> actionabilityJson,
    required List<dynamic> causalChainsJsonList,
    Map<String, dynamic>? dummyFeatures,
  }) {
    // ---------------------------------------------------------
    // STAGE 1: Feature Extraction & Normalisation
    // ---------------------------------------------------------
    List<double> features = FeatureEngineer.extract(profile, dummyFeatures: dummyFeatures);

    // ---------------------------------------------------------
    // STAGE 3: Scoring Pillars & Calibration
    // ---------------------------------------------------------
    Map<String, double> rawScores = ScoringEngine.scorePillars(features);
    Map<String, double> calibratedScores = ScoringEngine.calibrateScores(
      rawScores,
      calibrationKnotsJson,
    );

    // ---------------------------------------------------------
    // STAGE 4: Confidence Bounds & Adjustment
    // ---------------------------------------------------------
    Map<String, double> confidences = ConfidenceEngine.computeConfidence(
      workType,
      conformalIntervalsJson,
    );
    Map<String, double> adjustedScores = ConfidenceEngine.adjustScores(
      calibratedScores,
      confidences,
    );

    // ---------------------------------------------------------
    // STAGE 5: Meta-Learner (20-input logistic regression)
    // ---------------------------------------------------------
    double probability = MetaLearner.predict(
      adjustedScores,
      confidences,
      features,
      metaJson,
    );

    // ---------------------------------------------------------
    // STAGE 6: Score Mapping & XAI Bundle
    // ---------------------------------------------------------
    int finalScore = (probability * 600 + 300).round().clamp(300, 900);
    
    // Overall confidence is avg of pillar confidences
    double overallConfidence = confidences.values.reduce((a, b) => a + b) / 8.0;

    // Run Explainability Bundle (L1, L2, L3, L4, L8)
    ExplanationBundle xaiBundle = ExplanationBundle.compute(
      finalScore: finalScore,
      adjustedScores: adjustedScores,
      features: features,
      workType: workType,
      weightsJson: weightsJson,
      metaJson: metaJson,
      shapLookupJson: shapLookupJson,
      displayNamesJson: displayNamesJson,
      actionabilityJson: actionabilityJson,
      causalChainsJsonList: causalChainsJsonList,
    );

    // Build the 8 ScorePillarModel objects
    List<ScorePillarModel> pillars = _buildPillars(
      rawScores,
      calibratedScores,
      confidences,
      workType,
      conformalIntervalsJson,
      weightsJson,
    );

    // Assemble final report
    return ScoreReportModel(
      finalScore: finalScore,
      grade: _scoreToGrade(finalScore),
      riskBand: _scoreToRiskBand(finalScore),
      proofId: "GP-${DateTime.now().millisecondsSinceEpoch}",
      generatedAt: DateTime.now(),
      overallConfidence: overallConfidence,
      probability: probability,
      workType: workType,
      computeTimeMs: xaiBundle.computeTimeMs,
      pillars: pillars,
      pillarContributions: xaiBundle.pillarContributions,
      topStrengths: xaiBundle.topStrengths,
      topConcerns: xaiBundle.topConcerns,
      tailoredSuggestions: xaiBundle.actions.map((a) => TailoredSuggestion(
        text: a.actionText,
        estimatedPtsGain: a.expectedGainPts > 0 ? a.expectedGainPts : null,
      )).toList(),
      trajectory: xaiBundle.trajectory,
      causalChains: xaiBundle.causalChains,
      metaProbability: probability,
      efsVerdict: overallConfidence > 0.7 ? 'STABLE' : 'UNSTABLE',
      modelUsed: 'llama-3.3-70b-versatile',
      // Store applicant profile data so loan pipeline works after PII cleanup
      applicantAge: profile.personalInfo.age,
      applicantMonthlyIncome: profile.personalInfo.selfDeclaredIncome,
    );
  }

  static List<ScorePillarModel> _buildPillars(
    Map<String, double> rawScores,
    Map<String, double> calibratedScores,
    Map<String, double> confidences,
    String workType,
    Map<String, dynamic> conformalIntervalsJson,
    Map<String, dynamic> weightsJson,
  ) {
    Map<String, String> titles = {
      'P1': 'Income Reliability',
      'P2': 'Spending & Obligations',
      'P3': 'Debt Servicing',
      'P4': 'Savings Trajectory',
      'P5': 'Identity & KYC',
      'P6': 'Safety Nets',
      'P7': 'Social Accountability',
      'P8': 'Tax & Compliance',
    };

    List<ScorePillarModel> result = [];

    rawScores.forEach((code, raw) {
      double cal = calibratedScores[code] ?? raw;
      double conf = confidences[code] ?? 1.0;
      double weight = (weightsJson[code] as num?)?.toDouble() ?? 1.0;

      double halfWidth = 0.0;
      if (conformalIntervalsJson.containsKey(code) && conformalIntervalsJson[code].containsKey(workType)) {
        halfWidth = (conformalIntervalsJson[code][workType] as num).toDouble();
      }
      
      // Calculate maxScore via weight? Let's just use 100 for now or derive from weight * something.
      // In the V3 spec: 150/125/85/90/70/70/55/55
      int maxPts = 100;
      switch (code) {
        case 'P1': maxPts = 150; break;
        case 'P2': maxPts = 125; break;
        case 'P3': maxPts = 85; break;
        case 'P4': maxPts = 90; break;
        case 'P5': maxPts = 70; break;
        case 'P6': maxPts = 70; break;
        case 'P7': maxPts = 55; break;
        case 'P8': maxPts = 55; break;
      }

      int scorePts = (cal * maxPts).round();

      result.add(ScorePillarModel(
        code: code,
        title: titles[code] ?? code,
        subtitle: "Based on V3 Models",
        score: scorePts,
        maxScore: maxPts,
        rawScore: raw,
        calibratedScore: cal,
        conformalLow: (cal - halfWidth).clamp(0.0, 1.0),
        conformalHigh: (cal + halfWidth).clamp(0.0, 1.0),
        confidence: conf,
        weight: weight,
      ));
    });

    return result;
  }

  static String _scoreToGrade(int score) {
    if (score >= 800) return "A+";
    if (score >= 750) return "A";
    if (score >= 700) return "B+";
    if (score >= 650) return "B";
    if (score >= 600) return "C+";
    if (score >= 550) return "C";
    return "D";
  }

  static String _scoreToRiskBand(int score) {
    if (score >= 750) return "Very Low Risk";
    if (score >= 650) return "Low Risk";
    if (score >= 550) return "Medium Risk";
    return "High Risk";
  }
}
