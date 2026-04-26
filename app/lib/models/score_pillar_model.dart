class ScorePillarModel {
  final String code;
  final String title;
  final String subtitle;
  final int score;
  final int maxScore;
  final double confidence; // 0.0 to 1.0

  const ScorePillarModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.maxScore,
    this.confidence = 1.0,
  });

  factory ScorePillarModel.fromJson(Map<String, dynamic> json) => ScorePillarModel(
    code: json['code'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    score: json['score'] as int,
    maxScore: json['maxScore'] as int,
    confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'title': title,
    'subtitle': subtitle,
    'score': score,
    'maxScore': maxScore,
    'confidence': confidence,
  };
}
