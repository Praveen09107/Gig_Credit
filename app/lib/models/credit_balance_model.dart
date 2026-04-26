class CreditBalanceModel {
  final int freeRemaining;
  final int paidBalance;

  const CreditBalanceModel({
    this.freeRemaining = 3,
    this.paidBalance = 0,
  });

  int get totalAvailable => freeRemaining + (paidBalance ~/ 10);
  bool get canGenerateScore => freeRemaining > 0 || paidBalance >= 10;

  factory CreditBalanceModel.fromJson(Map<String, dynamic> json) => CreditBalanceModel(
    freeRemaining: json['freeRemaining'] as int? ?? 3,
    paidBalance: json['paidBalance'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'freeRemaining': freeRemaining,
    'paidBalance': paidBalance,
  };

  CreditBalanceModel copyWith({
    int? freeRemaining,
    int? paidBalance,
  }) => CreditBalanceModel(
    freeRemaining: freeRemaining ?? this.freeRemaining,
    paidBalance: paidBalance ?? this.paidBalance,
  );
}
