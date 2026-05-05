class EmiEntry {
  final String loanType; // 'home'|'vehicle'|'personal'|'education'|'gold'
  final double monthlyEmi;
  final double outstandingBalance;
  final int remainingMonths;
  final bool regularPayment; // true if no missed EMIs visible in bank

  const EmiEntry({
    required this.loanType,
    required this.monthlyEmi,
    this.outstandingBalance = 0.0,
    this.remainingMonths = 0,
    this.regularPayment = true,
  });

  factory EmiEntry.fromJson(Map<String, dynamic> j) => EmiEntry(
        loanType: j['loanType'] as String? ?? '',
        monthlyEmi: (j['monthlyEmi'] as num?)?.toDouble() ?? 0.0,
        outstandingBalance:
            (j['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
        remainingMonths: j['remainingMonths'] as int? ?? 0,
        regularPayment: j['regularPayment'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'loanType': loanType,
        'monthlyEmi': monthlyEmi,
        'outstandingBalance': outstandingBalance,
        'remainingMonths': remainingMonths,
        'regularPayment': regularPayment,
      };
}

class EmiLoansInfo {
  final bool isVerified;
  final List<EmiEntry> loans;

  /// Derived: total monthly EMI obligation
  double get totalMonthlyEmi =>
      loans.fold(0.0, (sum, e) => sum + e.monthlyEmi);

  /// Derived: ratio of regular (on-time) EMIs
  double get regularPaymentRatio {
    if (loans.isEmpty) return 1.0;
    final regular = loans.where((l) => l.regularPayment).length;
    return regular / loans.length;
  }

  const EmiLoansInfo({
    this.isVerified = false,
    this.loans = const [],
  });

  factory EmiLoansInfo.fromJson(Map<String, dynamic> json) => EmiLoansInfo(
        isVerified: json['isVerified'] as bool? ?? false,
        loans: (json['loans'] as List<dynamic>?)
                ?.map((e) => EmiEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'isVerified': isVerified,
        'loans': loans.map((l) => l.toJson()).toList(),
      };
}
