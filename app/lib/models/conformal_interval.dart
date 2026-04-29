class ConformalInterval {
  final double halfWidth;
  final double coverage;

  const ConformalInterval({
    required this.halfWidth,
    required this.coverage,
  });

  factory ConformalInterval.fromJson(Map<String, dynamic> json) {
    return ConformalInterval(
      halfWidth: (json['half_width'] as num).toDouble(),
      coverage: (json['coverage'] as num).toDouble(),
    );
  }
}
