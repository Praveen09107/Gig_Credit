class InsuranceInfo {
  final bool isVerified;
  final bool hasHealthInsurance;
  final bool hasLifeInsurance;
  final bool hasVehicleInsurance;
  final double annualPremiumHealth;
  final double annualPremiumLife;
  final String? policyExpiryDate;

  /// Derived: insurance coverage score 0.0–1.0
  double get coverageScore {
    double score = 0.0;
    if (hasHealthInsurance) score += 0.5;
    if (hasLifeInsurance) score += 0.35;
    if (hasVehicleInsurance) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  const InsuranceInfo({
    this.isVerified = false,
    this.hasHealthInsurance = false,
    this.hasLifeInsurance = false,
    this.hasVehicleInsurance = false,
    this.annualPremiumHealth = 0.0,
    this.annualPremiumLife = 0.0,
    this.policyExpiryDate,
  });

  factory InsuranceInfo.fromJson(Map<String, dynamic> json) => InsuranceInfo(
        isVerified: json['isVerified'] as bool? ?? false,
        hasHealthInsurance: json['hasHealthInsurance'] as bool? ?? false,
        hasLifeInsurance: json['hasLifeInsurance'] as bool? ?? false,
        hasVehicleInsurance: json['hasVehicleInsurance'] as bool? ?? false,
        annualPremiumHealth:
            (json['annualPremiumHealth'] as num?)?.toDouble() ?? 0.0,
        annualPremiumLife:
            (json['annualPremiumLife'] as num?)?.toDouble() ?? 0.0,
        policyExpiryDate: json['policyExpiryDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'isVerified': isVerified,
        'hasHealthInsurance': hasHealthInsurance,
        'hasLifeInsurance': hasLifeInsurance,
        'hasVehicleInsurance': hasVehicleInsurance,
        'annualPremiumHealth': annualPremiumHealth,
        'annualPremiumLife': annualPremiumLife,
        'policyExpiryDate': policyExpiryDate,
      };
}
