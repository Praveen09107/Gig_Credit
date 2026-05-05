class GovSchemesInfo {
  final bool isVerified;
  final bool hasEshram;      // eShram card registered
  final bool hasPmScheme;    // PM Jan Dhan / PM-KISAN / similar
  final bool hasRationCard;
  final bool hasPmAyushman;  // Ayushman Bharat health cover

  const GovSchemesInfo({
    this.isVerified = false,
    this.hasEshram = false,
    this.hasPmScheme = false,
    this.hasRationCard = false,
    this.hasPmAyushman = false,
  });

  factory GovSchemesInfo.fromJson(Map<String, dynamic> json) => GovSchemesInfo(
    isVerified: json['isVerified'] as bool? ?? false,
    hasEshram: json['hasEshram'] as bool? ?? false,
    hasPmScheme: json['hasPmScheme'] as bool? ?? false,
    hasRationCard: json['hasRationCard'] as bool? ?? false,
    hasPmAyushman: json['hasPmAyushman'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
    'hasEshram': hasEshram,
    'hasPmScheme': hasPmScheme,
    'hasRationCard': hasRationCard,
    'hasPmAyushman': hasPmAyushman,
  };
}
