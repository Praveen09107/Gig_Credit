class KycInfo {
  final bool isVerified;       // Aadhaar front verified
  final bool backVerified;     // Aadhaar back verified
  final bool selfieVerified;
  final bool panVerified;      // PAN card verified
  final double nameMatchScore; // Fuzzy match score Aadhaar↔PAN name (0.0–1.0)

  const KycInfo({
    this.isVerified = false,
    this.backVerified = false,
    this.selfieVerified = false,
    this.panVerified = false,
    this.nameMatchScore = 0.0,
  });

  factory KycInfo.fromJson(Map<String, dynamic> json) => KycInfo(
    isVerified: json['isVerified'] as bool? ?? false,
    backVerified: json['backVerified'] as bool? ?? false,
    selfieVerified: json['selfieVerified'] as bool? ?? false,
    panVerified: json['panVerified'] as bool? ?? false,
    nameMatchScore: (json['nameMatchScore'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
    'backVerified': backVerified,
    'selfieVerified': selfieVerified,
    'panVerified': panVerified,
    'nameMatchScore': nameMatchScore,
  };
}

