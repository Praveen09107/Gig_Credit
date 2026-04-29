import 'dart:convert';

import 'features/feature_engineer.dart';
import 'engine/scoring_engine.dart';
import 'engine/confidence_engine.dart';
import 'engine/meta_learner.dart';
import 'explainability/shap_lookup.dart';
import '../models/verified_profile/verified_profile.dart';
import '../models/score_report_model.dart';
import '../models/score_pillar_model.dart';
import '../models/shap_factor_model.dart';

/// Full scoring pipeline orchestrator — PRODUCTION VERSION (7 pillars)
/// VerifiedProfile → 95 features → 7 pillar models → confidence →
/// meta-learner → SHAP → ScoreReportModel
class ScorePipeline {
  /// SHAP lookup JSON (loaded once, cached).
  /// In production this is loaded from assets via rootBundle.
  /// For tests, pass it directly via [runWithShapJson].
  static ScoreReportModel run(VerifiedProfile profile, {String? shapJson}) {
    // Step 1: Feature Engineering (95 features in Dev A's order)
    final features = FeatureEngineer.extract(profile);

    // Step 2: Score 7 pillars using real m2cgen models
    final engine = ScoringEngine();
    final rawPillars = engine.scorePillars(features);

    // Step 3: Confidence adjustment
    final confidence = ConfidenceEngine.computeConfidence(features);
    final pillarConfidence = ConfidenceEngine.computePillarConfidence(features);
    final adjustedPillars = <String, double>{};
    for (final key in rawPillars.keys) {
      final pillarConf = pillarConfidence[key] ?? confidence;
      adjustedPillars[key] = ConfidenceEngine.adjustScore(
        rawPillars[key]!,
        pillarConf,
      );
    }

    // Step 4: Meta-Learner → final score 300-900
    final workType = profile.personalInfo.workType.isNotEmpty
        ? profile.personalInfo.workType
        : 'platform_worker';
    final finalScore = MetaLearner.predict(adjustedPillars, workType);
    final grade = MetaLearner.getGrade(finalScore);
    final riskBand = MetaLearner.getRiskLevel(finalScore);

    // Step 5: SHAP Explainability
    List<ShapFactorModel> strengthModels;
    List<ShapFactorModel> concernModels;
    List<String> suggestions;

    if (shapJson != null && shapJson.isNotEmpty) {
      final shap = ShapLookup.fromJsonString(shapJson);
      final shapResult = shap.analyze(features);
      strengthModels = shapResult.positiveFactors
          .map((s) => ShapFactorModel(
                featureName: s.displayLabel,
                description: '${s.pillarLabel}: ${s.displayLabel} is a strength',
                direction: 'positive',
                impactStrength: s.impact.abs(),
              ))
          .toList();
      concernModels = shapResult.negativeFactors
          .map((s) => ShapFactorModel(
                featureName: s.displayLabel,
                description: '${s.pillarLabel}: ${s.displayLabel} needs improvement',
                direction: 'negative',
                impactStrength: s.impact.abs(),
              ))
          .toList();
      suggestions = shapResult.negativeFactors
          .map((c) => 'Improve ${c.displayLabel.toLowerCase()} to boost your score')
          .toList();
    } else {
      // Fallback SHAP when JSON not loaded
      strengthModels = _fallbackStrengths();
      concernModels = _fallbackConcerns();
      suggestions = concernModels.map((c) => c.description).toList();
    }

    // Step 6: Build 7 pillar display models
    final pillars = _buildPillars(adjustedPillars);

    return ScoreReportModel(
      finalScore: finalScore,
      grade: grade,
      riskBand: riskBand,
      proofId: 'GC-${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      overallConfidence: confidence,
      pillars: pillars,
      topStrengths: strengthModels,
      topConcerns: concernModels,
      tailoredSuggestions: suggestions,
    );
  }

  /// Build 7 pillar display models matching Dev A's architecture.
  static List<ScorePillarModel> _buildPillars(Map<String, double> scores) {
    const pillarConfig = [
      {'code': 'p1', 'title': 'Income Stability', 'subtitle': 'Earnings regularity & growth trends', 'max': 150},
      {'code': 'p2', 'title': 'Payment Discipline', 'subtitle': 'Bill & EMI payment history', 'max': 150},
      {'code': 'p3', 'title': 'Debt Management', 'subtitle': 'EMI ratios & outstanding obligations', 'max': 100},
      {'code': 'p4', 'title': 'Savings Behaviour', 'subtitle': 'Savings rate & emergency fund', 'max': 100},
      {'code': 'p5', 'title': 'Work & Identity', 'subtitle': 'KYC verification & work proof', 'max': 150},
      {'code': 'p6', 'title': 'Financial Resilience', 'subtitle': 'Insurance & gov scheme coverage', 'max': 100},
      {'code': 'p7', 'title': 'Social Accountability', 'subtitle': 'Tax compliance & community trust', 'max': 150},
    ];

    return pillarConfig.map((cfg) {
      final code = cfg['code'] as String;
      final maxScore = cfg['max'] as int;
      final raw = scores[code] ?? 0.4;
      return ScorePillarModel(
        code: code,
        title: cfg['title'] as String,
        subtitle: cfg['subtitle'] as String,
        score: (raw * maxScore).round(),
        maxScore: maxScore,
      );
    }).toList();
  }

  static List<ShapFactorModel> _fallbackStrengths() => [
        ShapFactorModel(featureName: 'Identity Verified', description: 'Your KYC documents are verified', direction: 'positive', impactStrength: 0.05),
        ShapFactorModel(featureName: 'Bank Account Verified', description: 'Active bank account with regular activity', direction: 'positive', impactStrength: 0.04),
        ShapFactorModel(featureName: 'Platform Active', description: 'Active gig platform account', direction: 'positive', impactStrength: 0.03),
      ];

  static List<ShapFactorModel> _fallbackConcerns() => [
        ShapFactorModel(featureName: 'Insurance Gap', description: 'Consider getting health/vehicle insurance', direction: 'negative', impactStrength: 0.04),
        ShapFactorModel(featureName: 'Low Savings', description: 'Building an emergency fund will improve your score', direction: 'negative', impactStrength: 0.03),
        ShapFactorModel(featureName: 'Tax Filing', description: 'Filing ITR can significantly boost your score', direction: 'negative', impactStrength: 0.02),
      ];
}
