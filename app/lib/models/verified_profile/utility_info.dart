class UtilityBillEntry {
  final String billType; // 'electricity'|'gas'|'mobile'|'wifi'|'ott'|'rent'
  final double amount;
  final String? dueDate;
  final String? transactionRef;
  final bool verified;

  const UtilityBillEntry({
    required this.billType,
    required this.amount,
    this.dueDate,
    this.transactionRef,
    this.verified = false,
  });

  factory UtilityBillEntry.fromJson(Map<String, dynamic> j) => UtilityBillEntry(
        billType: j['billType'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        dueDate: j['dueDate'] as String?,
        transactionRef: j['transactionRef'] as String?,
        verified: j['verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'billType': billType,
        'amount': amount,
        'dueDate': dueDate,
        'transactionRef': transactionRef,
        'verified': verified,
      };
}

class UtilityInfo {
  final bool isVerified;
  final List<UtilityBillEntry> bills;

  /// Derived: total monthly utility spend
  double get totalMonthlyBills =>
      bills.fold(0.0, (sum, b) => sum + b.amount);

  /// Derived: how many of the verified bills have a matched bank transaction
  double get paymentVerificationRatio {
    if (bills.isEmpty) return 0.0;
    final verified = bills.where((b) => b.verified).length;
    return verified / bills.length;
  }

  const UtilityInfo({
    this.isVerified = false,
    this.bills = const [],
  });

  factory UtilityInfo.fromJson(Map<String, dynamic> json) => UtilityInfo(
        isVerified: json['isVerified'] as bool? ?? false,
        bills: (json['bills'] as List<dynamic>?)
                ?.map((e) =>
                    UtilityBillEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'isVerified': isVerified,
        'bills': bills.map((b) => b.toJson()).toList(),
      };
}
