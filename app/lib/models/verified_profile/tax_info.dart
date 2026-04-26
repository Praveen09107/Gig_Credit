class TaxInfo {
  final bool isVerified;
  const TaxInfo({this.isVerified = false});

  factory TaxInfo.fromJson(Map<String, dynamic> json) => TaxInfo(
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
  };
}
