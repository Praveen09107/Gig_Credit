class ScorePillarModel {
  final String code;
  final String title;
  final String subtitle;
  final int score;
  final int maxScore;
  final double rawScore;
  final double calibratedScore;
  final double conformalLow;
  final double conformalHigh;
  final double confidence; // 0.0 to 1.0
  final double weight;
  final double? attention;

  const ScorePillarModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.maxScore,
    required this.rawScore,
    required this.calibratedScore,
    required this.conformalLow,
    required this.conformalHigh,
    this.confidence = 1.0,
    required this.weight,
    this.attention,
  });

  factory ScorePillarModel.fromJson(Map<String, dynamic> json) => ScorePillarModel(
    code: json['code'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    score: json['score'] as int,
    maxScore: json['maxScore'] as int? ?? 100, // per-pillar mapping handled in pipeline
    rawScore: (json['rawScore'] as num?)?.toDouble() ?? 0.0,
    calibratedScore: (json['calibratedScore'] as num?)?.toDouble() ?? 0.0,
    conformalLow: (json['conformalLow'] as num?)?.toDouble() ?? 0.0,
    conformalHigh: (json['conformalHigh'] as num?)?.toDouble() ?? 0.0,
    confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    attention: (json['attention'] as num?)?.toDouble(),
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
