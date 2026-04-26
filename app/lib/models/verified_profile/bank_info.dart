class BankInfo {
  final bool isVerified;
  const BankInfo({this.isVerified = false});

  factory BankInfo.fromJson(Map<String, dynamic> json) => BankInfo(
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
  };
}
