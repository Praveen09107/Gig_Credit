import 'score_pillar_model.dart';
import 'shap_factor_model.dart';
import 'trajectory_result.dart';
import 'causal_chain.dart';
import 'tailored_suggestion.dart';

class ScoreReportModel {
  final int finalScore;
  final String grade;
  final String riskBand;
  final String proofId;
  final DateTime generatedAt;
  final double overallConfidence;
  final double probability;
  final String workType;
  final int computeTimeMs;
  final String? llmExplanation;
  final String? peerCohort;
  final String? efs;
  final String? deltaShap;
  // Applicant profile data — stored so loan pipeline works after PII cleanup
  final int applicantAge;
  final double applicantMonthlyIncome;
  
  final List<ScorePillarModel> pillars;
  final Map<String, int> pillarContributions;
  final List<ShapFactorModel> topStrengths;
  final List<ShapFactorModel> topConcerns;
  final List<TailoredSuggestion> tailoredSuggestions;
  final TrajectoryResult? trajectory;
  final List<CausalRule> causalChains;
  final double? metaProbability;
  final String? modelUsed;
  final String? efsVerdict;

  /// Alias for tailoredSuggestions — used by LlmExplanationCard
  List<TailoredSuggestion>? get llmSuggestions => tailoredSuggestions.isNotEmpty ? tailoredSuggestions : null;


  const ScoreReportModel({
    required this.finalScore,
    required this.grade,
    required this.riskBand,
    required this.proofId,
    required this.generatedAt,
    required this.overallConfidence,
    required this.probability,
    required this.workType,
    required this.computeTimeMs,
    this.llmExplanation,
    this.peerCohort,
    this.efs,
    this.deltaShap,
    this.applicantAge = 0,
    this.applicantMonthlyIncome = 0,
    required this.pillars,
    required this.pillarContributions,
    required this.topStrengths,
    required this.topConcerns,
    required this.tailoredSuggestions,
    this.trajectory,
    this.causalChains = const [],
    this.metaProbability,
    this.modelUsed,
    this.efsVerdict,
  });

  factory ScoreReportModel.fromJson(Map<String, dynamic> json) {
    final score = (json['finalScore'] as int? ?? 0).clamp(300, 900);
    return ScoreReportModel(
    finalScore: score,
    grade: _scoreToGrade(score),  // Always recompute — never trust stored grade
    riskBand: json['riskBand'] as String? ?? 'Unknown',
    proofId: json['proofId'] as String? ?? 'N/A',
    generatedAt: json['generatedAt'] != null ? DateTime.parse(json['generatedAt'] as String) : DateTime.now(),
    overallConfidence: (json['overallConfidence'] as num?)?.toDouble() ?? 0.0,
    probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
    workType: json['workType'] as String? ?? 'unknown',
    computeTimeMs: json['computeTimeMs'] as int? ?? 0,
    llmExplanation: json['llmExplanation'] as String?,
    peerCohort: json['peerCohort'] as String?,
    efs: json['efs'] as String?,
    deltaShap: json['deltaShap'] as String?,
    applicantAge: json['applicantAge'] as int? ?? 0,
    applicantMonthlyIncome: (json['applicantMonthlyIncome'] as num?)?.toDouble() ?? 0,
    pillars: (json['pillars'] as List?)?.map((e) => ScorePillarModel.fromJson(e)).toList() ?? [],
    pillarContributions: Map<String, int>.from(json['pillarContributions'] ?? {}),
    topStrengths: (json['topStrengths'] as List?)?.map((e) => ShapFactorModel.fromJson(e)).toList() ?? [],
    topConcerns: (json['topConcerns'] as List?)?.map((e) => ShapFactorModel.fromJson(e)).toList() ?? [],
    tailoredSuggestions: (json['tailoredSuggestions'] as List?)?.map((e) {
      if (e is String) return TailoredSuggestion(text: e, estimatedPtsGain: 15);
      return TailoredSuggestion.fromJson(e);
    }).toList() ?? [],
    causalChains: (json['causalChains'] as List?)?.map((e) => CausalRule.fromJson(e)).toList() ?? [],
    metaProbability: (json['metaProbability'] as num?)?.toDouble(),
    modelUsed: json['modelUsed'] as String?,
    efsVerdict: json['efsVerdict'] as String?,
  );
  }

  /// Single source of truth for score→grade mapping.
  /// Matches score_pipeline.dart exactly.
  static String _scoreToGrade(int score) {
    if (score >= 800) return 'A+';
    if (score >= 750) return 'A';
    if (score >= 700) return 'B+';
    if (score >= 650) return 'B';
    if (score >= 600) return 'C+';
    if (score >= 550) return 'C';
    return 'D';
  }

  /// Public accessor for grade computation (used by history screen, etc.)
  static String computeGrade(int score) => _scoreToGrade(score.clamp(300, 900));

  Map<String, dynamic> toJson() => {
    'finalScore': finalScore,
    'grade': grade,
    'riskBand': riskBand,
    'proofId': proofId,
    'generatedAt': generatedAt.toIso8601String(),
    'overallConfidence': overallConfidence,
    'probability': probability,
    'workType': workType,
    'computeTimeMs': computeTimeMs,
    'llmExplanation': llmExplanation,
    'peerCohort': peerCohort,
    'efs': efs,
    'deltaShap': deltaShap,
    'applicantAge': applicantAge,
    'applicantMonthlyIncome': applicantMonthlyIncome,
    'pillars': pillars.map((e) => e.toJson()).toList(),
    'pillarContributions': pillarContributions,
    'topStrengths': topStrengths.map((e) => e.toJson()).toList(),
    'topConcerns': topConcerns.map((e) => e.toJson()).toList(),
    'tailoredSuggestions': tailoredSuggestions.map((e) => e.toJson()).toList(),
    'causalChains': causalChains.map((e) => e.toJson()).toList(),
    'metaProbability': metaProbability,
    'modelUsed': modelUsed,
    'efsVerdict': efsVerdict,
  };
}
