class TailoredSuggestion {
  final String text;
  final int? estimatedPtsGain;

  const TailoredSuggestion({
    required this.text,
    this.estimatedPtsGain,
  });

  factory TailoredSuggestion.fromJson(Map<String, dynamic> json) => TailoredSuggestion(
    text: json['text'] as String? ?? json['suggestion'] as String? ?? '',
    estimatedPtsGain: json['estimated_pts_gain'] as int? ?? json['estimatedPtsGain'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'estimatedPtsGain': estimatedPtsGain,
  };
}
