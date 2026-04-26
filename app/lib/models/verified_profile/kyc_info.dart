class KycInfo {
  final bool isVerified;
  final bool backVerified;
  final bool selfieVerified;
  
  const KycInfo({
    this.isVerified = false,
    this.backVerified = false,
    this.selfieVerified = false,
  });

  factory KycInfo.fromJson(Map<String, dynamic> json) => KycInfo(
    isVerified: json['isVerified'] as bool? ?? false,
    backVerified: json['backVerified'] as bool? ?? false,
    selfieVerified: json['selfieVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
    'backVerified': backVerified,
    'selfieVerified': selfieVerified,
  };
}
