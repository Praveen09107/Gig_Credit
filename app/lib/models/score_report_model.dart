import 'score_pillar_model.dart';
import 'shap_factor_model.dart';
import 'trajectory_result.dart';
import 'causal_chain.dart';

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
  
  final List<ScorePillarModel> pillars;
  final Map<String, int> pillarContributions;
  final List<ShapFactorModel> topStrengths;
  final List<ShapFactorModel> topConcerns;
  final List<String> tailoredSuggestions;
  final TrajectoryResult? trajectory;
  final List<CausalRule> causalChains;

  /// Alias for tailoredSuggestions — used by LlmExplanationCard
  List<String>? get llmSuggestions => tailoredSuggestions.isNotEmpty ? tailoredSuggestions : null;


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
    required this.pillars,
    required this.pillarContributions,
    required this.topStrengths,
    required this.topConcerns,
    required this.tailoredSuggestions,
    this.trajectory,
    this.causalChains = const [],
  });

  factory ScoreReportModel.fromJson(Map<String, dynamic> json) => ScoreReportModel(
    finalScore: json['finalScore'] as int,
    grade: json['grade'] as String,
    riskBand: json['riskBand'] as String,
    proofId: json['proofId'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    overallConfidence: (json['overallConfidence'] as num).toDouble(),
    probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
    workType: json['workType'] as String? ?? 'unknown',
    computeTimeMs: json['computeTimeMs'] as int? ?? 0,
    llmExplanation: json['llmExplanation'] as String?,
    peerCohort: json['peerCohort'] as String?,
    efs: json['efs'] as String?,
    deltaShap: json['deltaShap'] as String?,
    pillars: (json['pillars'] as List).map((e) => ScorePillarModel.fromJson(e)).toList(),
    pillarContributions: Map<String, int>.from(json['pillarContributions'] ?? {}),
    topStrengths: (json['topStrengths'] as List).map((e) => ShapFactorModel.fromJson(e)).toList(),
    topConcerns: (json['topConcerns'] as List).map((e) => ShapFactorModel.fromJson(e)).toList(),
    tailoredSuggestions: List<String>.from(json['tailoredSuggestions']),
  );

  Map<String, dynamic> toJson() => {
    'finalScore': finalScore,
    'grade': grade,
    'riskBand': riskBand,
    'proofId': proofId,
    'generatedAt': generatedAt.toIso8601String(),
    'overallConfidence': overallConfidence,
    'llmExplanation': llmExplanation,
    'pillars': pillars.map((e) => e.toJson()).toList(),
    'topStrengths': topStrengths.map((e) => e.toJson()).toList(),
    'topConcerns': topConcerns.map((e) => e.toJson()).toList(),
    'tailoredSuggestions': tailoredSuggestions,
  };
}
