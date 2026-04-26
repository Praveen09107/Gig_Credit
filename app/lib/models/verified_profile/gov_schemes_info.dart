class GovSchemesInfo {
  final bool isVerified;
  const GovSchemesInfo({this.isVerified = false});

  factory GovSchemesInfo.fromJson(Map<String, dynamic> json) => GovSchemesInfo(
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
  };
}
