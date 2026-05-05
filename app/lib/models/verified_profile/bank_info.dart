class BankTransaction {
  final String date;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String? refId;
  final String description;

  const BankTransaction({
    required this.date,
    required this.amount,
    required this.type,
    this.refId,
    required this.description,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> j) => BankTransaction(
        date: j['date'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        type: j['type'] as String? ?? 'debit',
        refId: j['ref_id'] as String?,
        description: j['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'amount': amount,
        'type': type,
        'ref_id': refId,
        'description': description,
      };
}

class BankInfo {
  final bool isVerified;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String accountHolderName;

  /// Monthly credit/deposit totals (List length = number of months parsed)
  final List<double> monthlyCredits;

  /// Monthly debit totals
  final List<double> monthlyDebits;

  /// All structured transactions parsed from the PDF
  final List<BankTransaction> transactions;

  /// Derived: average monthly income (mean of credits)
  double get avgMonthlyIncome {
    if (monthlyCredits.isEmpty) return 0.0;
    return monthlyCredits.reduce((a, b) => a + b) / monthlyCredits.length;
  }

  /// Derived: income coefficient of variation (lower = more stable)
  double get incomeCv {
    if (monthlyCredits.length < 2) return 0.5;
    final mean = avgMonthlyIncome;
    if (mean == 0) return 1.0;
    final variance = monthlyCredits
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        monthlyCredits.length;
    return (variance > 0 ? (variance) : 0.0) == 0
        ? 0.0
        : (variance > 0 ? variance : 0.0);
  }

  /// Derived: average monthly expenses (debits)
  double get avgMonthlyExpenses {
    if (monthlyDebits.isEmpty) return 0.0;
    return monthlyDebits.reduce((a, b) => a + b) / monthlyDebits.length;
  }

  const BankInfo({
    this.isVerified = false,
    this.accountNumber = '',
    this.ifscCode = '',
    this.bankName = '',
    this.accountHolderName = '',
    this.monthlyCredits = const [],
    this.monthlyDebits = const [],
    this.transactions = const [],
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) => BankInfo(
        isVerified: json['isVerified'] as bool? ?? false,
        accountNumber: json['accountNumber'] as String? ?? '',
        ifscCode: json['ifscCode'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        accountHolderName: json['accountHolderName'] as String? ?? '',
        monthlyCredits: (json['monthlyCredits'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
        monthlyDebits: (json['monthlyDebits'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
        transactions: (json['transactions'] as List<dynamic>?)
                ?.map((e) =>
                    BankTransaction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'isVerified': isVerified,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
        'accountHolderName': accountHolderName,
        'monthlyCredits': monthlyCredits,
        'monthlyDebits': monthlyDebits,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };
}
