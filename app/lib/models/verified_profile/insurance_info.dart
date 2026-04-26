class InsuranceInfo {
  final bool isVerified;
  const InsuranceInfo({this.isVerified = false});

  factory InsuranceInfo.fromJson(Map<String, dynamic> json) => InsuranceInfo(
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
  };
}
