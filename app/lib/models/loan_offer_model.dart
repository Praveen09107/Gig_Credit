class LoanOfferModel {
  final String id;
  final String lenderName;
  final String lenderLogoUrl;
  final double amount;
  final double interestRate;
  final int tenureMonths;
  final double estimatedEmi;
  final List<String> highlights;

  const LoanOfferModel({
    required this.id,
    required this.lenderName,
    required this.lenderLogoUrl,
    required this.amount,
    required this.interestRate,
    required this.tenureMonths,
    required this.estimatedEmi,
    required this.highlights,
  });

  factory LoanOfferModel.fromJson(Map<String, dynamic> json) => LoanOfferModel(
    id: json['id'] as String,
    lenderName: json['lenderName'] as String,
    lenderLogoUrl: json['lenderLogoUrl'] as String,
    amount: (json['amount'] as num).toDouble(),
    interestRate: (json['interestRate'] as num).toDouble(),
    tenureMonths: json['tenureMonths'] as int,
    estimatedEmi: (json['estimatedEmi'] as num).toDouble(),
    highlights: List<String>.from(json['highlights']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'lenderName': lenderName,
    'lenderLogoUrl': lenderLogoUrl,
    'amount': amount,
    'interestRate': interestRate,
    'tenureMonths': tenureMonths,
    'estimatedEmi': estimatedEmi,
    'highlights': highlights,
  };
}
