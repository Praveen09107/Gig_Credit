class TaxInfo {
  final bool isVerified;
  final bool itrFiled;
  final int assessmentYear; // e.g. 2024
  final double declaredAnnualIncome;
  final double taxPaid;
  final bool gstRegistered;
  final bool noDefaultHistory;

  /// Derived: compliance score 0.0–1.0
  double get complianceScore {
    double score = 0.0;
    if (itrFiled) score += 0.5;
    if (noDefaultHistory) score += 0.3;
    if (gstRegistered) score += 0.2;
    return score.clamp(0.0, 1.0);
  }

  const TaxInfo({
    this.isVerified = false,
    this.itrFiled = false,
    this.assessmentYear = 0,
    this.declaredAnnualIncome = 0.0,
    this.taxPaid = 0.0,
    this.gstRegistered = false,
    this.noDefaultHistory = true,
  });

  factory TaxInfo.fromJson(Map<String, dynamic> json) => TaxInfo(
        isVerified: json['isVerified'] as bool? ?? false,
        itrFiled: json['itrFiled'] as bool? ?? false,
        assessmentYear: json['assessmentYear'] as int? ?? 0,
        declaredAnnualIncome:
            (json['declaredAnnualIncome'] as num?)?.toDouble() ?? 0.0,
        taxPaid: (json['taxPaid'] as num?)?.toDouble() ?? 0.0,
        gstRegistered: json['gstRegistered'] as bool? ?? false,
        noDefaultHistory: json['noDefaultHistory'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'isVerified': isVerified,
        'itrFiled': itrFiled,
        'assessmentYear': assessmentYear,
        'declaredAnnualIncome': declaredAnnualIncome,
        'taxPaid': taxPaid,
        'gstRegistered': gstRegistered,
        'noDefaultHistory': noDefaultHistory,
      };
}
