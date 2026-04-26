import 'score_pillar_model.dart';
import 'shap_factor_model.dart';

class ScoreReportModel {
  final int finalScore;
  final String grade;
  final String riskBand;
  final String proofId;
  final DateTime generatedAt;
  final double overallConfidence;
  final String? llmExplanation;
  
  final List<ScorePillarModel> pillars;
  final List<ShapFactorModel> topStrengths;
  final List<ShapFactorModel> topConcerns;
  final List<String> tailoredSuggestions;

  /// Alias for tailoredSuggestions — used by LlmExplanationCard
  List<String>? get llmSuggestions => tailoredSuggestions.isNotEmpty ? tailoredSuggestions : null;


  const ScoreReportModel({
    required this.finalScore,
    required this.grade,
    required this.riskBand,
    required this.proofId,
    required this.generatedAt,
    required this.overallConfidence,
    this.llmExplanation,
    required this.pillars,
    required this.topStrengths,
    required this.topConcerns,
    required this.tailoredSuggestions,
  });

  factory ScoreReportModel.fromJson(Map<String, dynamic> json) => ScoreReportModel(
    finalScore: json['finalScore'] as int,
    grade: json['grade'] as String,
    riskBand: json['riskBand'] as String,
    proofId: json['proofId'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    overallConfidence: (json['overallConfidence'] as num).toDouble(),
    llmExplanation: json['llmExplanation'] as String?,
    pillars: (json['pillars'] as List).map((e) => ScorePillarModel.fromJson(e)).toList(),
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
