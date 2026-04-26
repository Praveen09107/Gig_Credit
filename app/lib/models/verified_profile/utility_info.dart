class UtilityInfo {
  final bool isVerified;
  const UtilityInfo({this.isVerified = false});

  factory UtilityInfo.fromJson(Map<String, dynamic> json) => UtilityInfo(
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
  };
}
