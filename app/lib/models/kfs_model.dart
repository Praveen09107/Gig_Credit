class KfsModel {
  final double loanAmount;
  final int tenureDays;
  final double interestRateAnnual;
  final double processingFee;
  final double totalRepaymentAmount;
  final double apr;
  final String coolingOffPeriod;
  final double penalChargePerDay;
  final String grievanceOfficerContact;

  const KfsModel({
    required this.loanAmount,
    required this.tenureDays,
    required this.interestRateAnnual,
    required this.processingFee,
    required this.totalRepaymentAmount,
    required this.apr,
    required this.coolingOffPeriod,
    required this.penalChargePerDay,
    required this.grievanceOfficerContact,
  });

  factory KfsModel.fromJson(Map<String, dynamic> json) {
    return KfsModel(
      loanAmount: (json['loanAmount'] as num).toDouble(),
      tenureDays: json['tenureDays'] as int,
      interestRateAnnual: (json['interestRateAnnual'] as num).toDouble(),
      processingFee: (json['processingFee'] as num).toDouble(),
      totalRepaymentAmount: (json['totalRepaymentAmount'] as num).toDouble(),
      apr: (json['apr'] as num).toDouble(),
      coolingOffPeriod: json['coolingOffPeriod'] as String,
      penalChargePerDay: (json['penalChargePerDay'] as num).toDouble(),
      grievanceOfficerContact: json['grievanceOfficerContact'] as String,
    );
  }
}
