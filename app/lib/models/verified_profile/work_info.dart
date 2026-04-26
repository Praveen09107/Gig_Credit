/// COMP_24 Step 5 — Work Proof Model
/// Tracks all document uploads for platform worker / vendor / tradesperson / freelancer.
/// These fields feed Features 49-66 (Work & Identity pillar) in the scoring engine.
class WorkInfo {
  final bool isVerified;
  final String platformId;           // Platform worker ID
  final bool rcUploaded;             // Registration Certificate
  final bool dlFrontUploaded;        // Driving License front
  final bool dlBackUploaded;         // Driving License back
  final bool vehicleInsuranceUploaded;
  final int earningScreenshots;      // 0-3 screenshots
  final bool upiScreenshotUploaded;
  final bool payoutUploaded;         // Payout summary/ledger
  // Vendor-specific
  final bool svanidhiUploaded;
  final bool approvalLetterUploaded;
  final bool tradeLicenceUploaded;

  const WorkInfo({
    this.isVerified = false,
    this.platformId = '',
    this.rcUploaded = false,
    this.dlFrontUploaded = false,
    this.dlBackUploaded = false,
    this.vehicleInsuranceUploaded = false,
    this.earningScreenshots = 0,
    this.upiScreenshotUploaded = false,
    this.payoutUploaded = false,
    this.svanidhiUploaded = false,
    this.approvalLetterUploaded = false,
    this.tradeLicenceUploaded = false,
  });

  /// Count of total uploaded work proof documents
  int get uploadedCount {
    int count = 0;
    if (rcUploaded) count++;
    if (dlFrontUploaded) count++;
    if (dlBackUploaded) count++;
    if (vehicleInsuranceUploaded) count++;
    count += earningScreenshots;
    if (upiScreenshotUploaded) count++;
    if (payoutUploaded) count++;
    if (svanidhiUploaded) count++;
    if (approvalLetterUploaded) count++;
    if (tradeLicenceUploaded) count++;
    return count;
  }

  factory WorkInfo.fromJson(Map<String, dynamic> json) => WorkInfo(
    isVerified: json['isVerified'] as bool? ?? false,
    platformId: json['platformId'] as String? ?? '',
    rcUploaded: json['rcUploaded'] as bool? ?? false,
    dlFrontUploaded: json['dlFrontUploaded'] as bool? ?? false,
    dlBackUploaded: json['dlBackUploaded'] as bool? ?? false,
    vehicleInsuranceUploaded: json['vehicleInsuranceUploaded'] as bool? ?? false,
    earningScreenshots: json['earningScreenshots'] as int? ?? 0,
    upiScreenshotUploaded: json['upiScreenshotUploaded'] as bool? ?? false,
    payoutUploaded: json['payoutUploaded'] as bool? ?? false,
    svanidhiUploaded: json['svanidhiUploaded'] as bool? ?? false,
    approvalLetterUploaded: json['approvalLetterUploaded'] as bool? ?? false,
    tradeLicenceUploaded: json['tradeLicenceUploaded'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
    'platformId': platformId,
    'rcUploaded': rcUploaded,
    'dlFrontUploaded': dlFrontUploaded,
    'dlBackUploaded': dlBackUploaded,
    'vehicleInsuranceUploaded': vehicleInsuranceUploaded,
    'earningScreenshots': earningScreenshots,
    'upiScreenshotUploaded': upiScreenshotUploaded,
    'payoutUploaded': payoutUploaded,
    'svanidhiUploaded': svanidhiUploaded,
    'approvalLetterUploaded': approvalLetterUploaded,
    'tradeLicenceUploaded': tradeLicenceUploaded,
  };
}
