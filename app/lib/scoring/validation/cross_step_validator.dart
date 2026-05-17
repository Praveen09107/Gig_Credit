
enum IssueSeverity { info, warning, error }

class ValidationIssue {
  final String code;
  final String title;
  final String description;
  final IssueSeverity severity;
  final List<int> steps;
  final String field1;
  final String field2;
  final double? similarity;

  const ValidationIssue({
    required this.code,
    required this.title,
    required this.description,
    required this.severity,
    this.steps = const [],
    this.field1 = '',
    this.field2 = '',
    this.similarity,
  });
}

class CrossStepValidator {
  static List<ValidationIssue> validate(Map<String, dynamic> ocrResults) {
    final issues = <ValidationIssue>[];

    final aadhaar = ocrResults['aadhaar_front'] as Map<String, dynamic>?;
    final pan = ocrResults['pan'] as Map<String, dynamic>?;
    final rc = ocrResults['work_rc'] as Map<String, dynamic>?;
    final ins = ocrResults['insurance_vehicle'] as Map<String, dynamic>?;
    final itr = ocrResults['tax_itr'] as Map<String, dynamic>?;

    // Aadhaar vs PAN Name
    if (aadhaar != null && pan != null) {
      final aName = (aadhaar['name'] as String?)?.trim().toUpperCase();
      final pName = (pan['name'] as String?)?.trim().toUpperCase();
      if (aName != null && pName != null && aName.isNotEmpty && pName.isNotEmpty) {
        if (aName != pName) {
          issues.add(ValidationIssue(
            code: 'NAME_MISMATCH_AADHAAR_PAN',
            title: 'Name Mismatch',
            description: 'Name on Aadhaar does not match PAN',
            severity: IssueSeverity.warning,
            steps: [1, 2],
            field1: aadhaar['name'],
            field2: pan['name'],
          ));
        }
      }

      // Aadhaar vs PAN DOB
      final aDob = (aadhaar['dob'] as String?)?.trim();
      final pDob = (pan['dob'] as String?)?.trim();
      if (aDob != null && pDob != null && aDob.isNotEmpty && pDob.isNotEmpty) {
        if (aDob != pDob) {
          issues.add(ValidationIssue(
            code: 'DOB_MISMATCH_AADHAAR_PAN',
            title: 'DOB Mismatch',
            description: 'Date of Birth on Aadhaar does not match PAN',
            severity: IssueSeverity.warning,
            steps: [1, 2],
            field1: aDob,
            field2: pDob,
          ));
        }
      }
    }

    // RC vs Insurance Vehicle
    if (rc != null && ins != null) {
      final rNum = (rc['vehicle_number'] as String?)?.replaceAll(' ', '').toUpperCase();
      final iNum = (ins['vehicle_number'] as String?)?.replaceAll(' ', '').toUpperCase();
      if (rNum != null && iNum != null && rNum.isNotEmpty && iNum.isNotEmpty) {
        if (rNum != iNum) {
          issues.add(ValidationIssue(
            code: 'VEHICLE_MISMATCH_RC_INSURANCE',
            title: 'Vehicle Mismatch',
            description: 'Vehicle number on RC does not match Insurance',
            severity: IssueSeverity.warning,
            steps: [5, 7],
            field1: rc['vehicle_number'],
            field2: ins['vehicle_number'],
          ));
        }
      }
    }

    // KYC PAN vs ITR PAN
    if (pan != null && itr != null) {
      final kPan = (pan['id_number'] as String?)?.trim().toUpperCase();
      final iPan = (itr['pan'] as String?)?.trim().toUpperCase();
      if (kPan != null && iPan != null && kPan.isNotEmpty && iPan.isNotEmpty) {
        if (kPan != iPan) {
          issues.add(ValidationIssue(
            code: 'PAN_MISMATCH_KYC_ITR',
            title: 'PAN Mismatch',
            description: 'ITR PAN does not match KYC PAN',
            severity: IssueSeverity.error,
            steps: [2, 8],
            field1: pan['id_number'],
            field2: itr['pan'],
          ));
        }
      }
    }

    return issues;
  }

  static List<ValidationIssue> getDisplayableIssues(List<ValidationIssue> issues) {
    return issues.where((i) => i.severity != IssueSeverity.info).toList();
  }

  static bool hasBlockingErrors(List<ValidationIssue> issues) {
    return issues.any((issue) => issue.severity == IssueSeverity.error);
  }
}
