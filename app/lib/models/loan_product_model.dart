class LoanProductModel {
  final String id;
  final String lenderName;
  final String lenderLogoUrl;
  final double maxEligibleAmount;
  final double interestRate;
  final int tenureMonths;
  final double estimatedEmi;
  final List<String> highlights;
  final bool isEligible;
  final int? scoreGap;

  const LoanProductModel({
    required this.id,
    required this.lenderName,
    required this.lenderLogoUrl,
    required this.maxEligibleAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.estimatedEmi,
    required this.highlights,
    required this.isEligible,
    this.scoreGap,
  });

  factory LoanProductModel.fromJson(Map<String, dynamic> json) => LoanProductModel(
    id: json['id'] as String,
    lenderName: json['lenderName'] as String,
    lenderLogoUrl: json['lenderLogoUrl'] as String,
    maxEligibleAmount: (json['maxEligibleAmount'] as num).toDouble(),
    interestRate: (json['interestRate'] as num).toDouble(),
    tenureMonths: json['tenureMonths'] as int,
    estimatedEmi: (json['estimatedEmi'] as num).toDouble(),
    highlights: List<String>.from(json['highlights']),
    isEligible: json['isEligible'] as bool? ?? true,
    scoreGap: json['scoreGap'] as int?,
  );
}
