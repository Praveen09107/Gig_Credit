/// COMP_24 Step 1 — Personal Info Model
/// Stores all 12 mandatory + 1 optional field from the Basic Profile step.
/// These fields feed Features 5, 8, 12, 55-57, 85, 87 in the scoring engine.
class PersonalInfo {
  final bool isVerified;
  final String fullName;
  final String dateOfBirth;         // DD/MM/YYYY
  final String mobileNumber;        // 10 digits
  final String currentAddress;
  final String permanentAddress;
  final String stateOfResidence;
  final String workType;            // platform_worker | vendor | tradesperson | freelancer
  final double selfDeclaredIncome;  // ₹1,000 – ₹5,00,000
  final int yearsInProfession;      // 0-40
  final int dependents;             // 0-10
  final bool vehicleOwnership;
  final double? secondaryIncome;    // optional

  /// Computed age from dateOfBirth (DD/MM/YYYY). Returns 0 if unparseable.
  int get age {
    try {
      final cleanDob = dateOfBirth.replaceAll('-', '/').trim();
      final parts = cleanDob.split('/');
      if (parts.length != 3) return 0;
      final dob = DateTime(int.parse(parts[2].trim()), int.parse(parts[1].trim()), int.parse(parts[0].trim()));
      final now = DateTime.now();
      int a = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) a--;
      return a.clamp(0, 120);
    } catch (_) { return 0; }
  }

  const PersonalInfo({
    this.isVerified = false,
    this.fullName = '',
    this.dateOfBirth = '',
    this.mobileNumber = '',
    this.currentAddress = '',
    this.permanentAddress = '',
    this.stateOfResidence = '',
    this.workType = 'platform_worker',
    this.selfDeclaredIncome = 0.0,
    this.yearsInProfession = 0,
    this.dependents = 0,
    this.vehicleOwnership = false,
    this.secondaryIncome,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
    isVerified: json['isVerified'] as bool? ?? false,
    fullName: json['fullName'] as String? ?? '',
    dateOfBirth: json['dateOfBirth'] as String? ?? '',
    mobileNumber: json['mobileNumber'] as String? ?? '',
    currentAddress: json['currentAddress'] as String? ?? '',
    permanentAddress: json['permanentAddress'] as String? ?? '',
    stateOfResidence: json['stateOfResidence'] as String? ?? '',
    workType: json['workType'] as String? ?? 'platform_worker',
    selfDeclaredIncome: (json['selfDeclaredIncome'] as num?)?.toDouble() ?? 0.0,
    yearsInProfession: json['yearsInProfession'] as int? ?? 0,
    dependents: json['dependents'] as int? ?? 0,
    vehicleOwnership: json['vehicleOwnership'] as bool? ?? false,
    secondaryIncome: (json['secondaryIncome'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth,
    'mobileNumber': mobileNumber,
    'currentAddress': currentAddress,
    'permanentAddress': permanentAddress,
    'stateOfResidence': stateOfResidence,
    'workType': workType,
    'selfDeclaredIncome': selfDeclaredIncome,
    'yearsInProfession': yearsInProfession,
    'dependents': dependents,
    'vehicleOwnership': vehicleOwnership,
    'secondaryIncome': secondaryIncome,
  };
}
