class EmiLoansInfo {
  final bool isVerified;
  const EmiLoansInfo({this.isVerified = false});

  factory EmiLoansInfo.fromJson(Map<String, dynamic> json) => EmiLoansInfo(
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
  };
}
