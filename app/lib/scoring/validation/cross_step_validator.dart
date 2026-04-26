/// COMP_30: Cross-Step Validation Engine
/// 
/// Runs after document extraction across steps to detect:
/// - Name inconsistency (Aadhaar vs PAN vs Bank)
/// - DOB inconsistency (Aadhaar vs PAN)
/// - Vehicle number inconsistency (RC vs Insurance)
/// - PAN inconsistency (KYC PAN vs ITR PAN)
///
/// Severity levels:
///   ERROR   → blocks scoring (user must fix)
///   WARNING → allows scoring, shows yellow/red badge
///   INFO    → logged internally, no badge
class CrossStepValidator {
  /// Run all cross-step checks against accumulated OCR data.
  /// Returns a list of validation issues found.
  static List<ValidationIssue> validate(Map<String, Map<String, dynamic>> ocrResults) {
    final issues = <ValidationIssue>[];

    // ── 1. Name Consistency: Aadhaar vs PAN ──
    final aadhaarName = _getString(ocrResults, 'aadhaar_front', 'name');
    final panName = _getString(ocrResults, 'pan', 'name');

    if (aadhaarName.isNotEmpty && panName.isNotEmpty) {
      final similarity = _fuzzyMatch(aadhaarName, panName);
      if (similarity < 0.85) {
        issues.add(ValidationIssue(
          code: 'NAME_MISMATCH_AADHAAR_PAN',
          title: 'Name Mismatch',
          description: 'Aadhaar name "$aadhaarName" does not match PAN name "$panName"',
          severity: IssueSeverity.warning,
          steps: [2],
          field1: aadhaarName,
          field2: panName,
          similarity: similarity,
        ));
      }
    }

    // ── 2. DOB Consistency: Aadhaar vs PAN ──
    final aadhaarDob = _getString(ocrResults, 'aadhaar_front', 'dob');
    final panDob = _getString(ocrResults, 'pan', 'dob');

    if (aadhaarDob.isNotEmpty && panDob.isNotEmpty) {
      if (_normalizeDateString(aadhaarDob) != _normalizeDateString(panDob)) {
        issues.add(ValidationIssue(
          code: 'DOB_MISMATCH_AADHAAR_PAN',
          title: 'DOB Mismatch',
          description: 'Aadhaar DOB "$aadhaarDob" does not match PAN DOB "$panDob"',
          severity: IssueSeverity.warning,
          steps: [2],
          field1: aadhaarDob,
          field2: panDob,
        ));
      }
    }

    // ── 3. Vehicle Number: RC vs Insurance ──
    final rcVehicle = _getString(ocrResults, 'work_rc', 'vehicle_number');
    final insVehicle = _getString(ocrResults, 'insurance_vehicle', 'vehicle_number');

    if (rcVehicle.isNotEmpty && insVehicle.isNotEmpty) {
      if (_normalizeVehicle(rcVehicle) != _normalizeVehicle(insVehicle)) {
        issues.add(ValidationIssue(
          code: 'VEHICLE_MISMATCH_RC_INSURANCE',
          title: 'Vehicle Number Mismatch',
          description: 'RC vehicle "$rcVehicle" does not match insured vehicle "$insVehicle"',
          severity: IssueSeverity.warning,
          steps: [5, 7],
          field1: rcVehicle,
          field2: insVehicle,
        ));
      }
    }

    // ── 4. PAN Consistency: KYC PAN vs ITR PAN (ERROR severity) ──
    final kycPan = _getString(ocrResults, 'pan', 'id_number');
    final itrPan = _getString(ocrResults, 'tax_itr', 'pan');

    if (kycPan.isNotEmpty && itrPan.isNotEmpty) {
      if (kycPan.toUpperCase().trim() != itrPan.toUpperCase().trim()) {
        issues.add(ValidationIssue(
          code: 'PAN_MISMATCH_KYC_ITR',
          title: 'PAN Number Mismatch',
          description: 'PAN card "$kycPan" does not match ITR PAN "$itrPan". This blocks scoring.',
          severity: IssueSeverity.error,
          steps: [2, 8],
          field1: kycPan,
          field2: itrPan,
        ));
      }
    }

    // ── 5. Address: Aadhaar vs Utility ──
    final aadhaarAddr = _getString(ocrResults, 'aadhaar_back', 'address');
    // Utility address match is a boolean from OCR, but we can check it:
    final utilityAddrMatch = ocrResults['utility_electricity']?['address_match'];
    if (aadhaarAddr.isNotEmpty && utilityAddrMatch == false) {
      issues.add(ValidationIssue(
        code: 'ADDRESS_MISMATCH_AADHAAR_UTILITY',
        title: 'Address Mismatch',
        description: 'Utility bill address does not match Aadhaar address',
        severity: IssueSeverity.info,
        steps: [2, 4],
        field1: aadhaarAddr,
        field2: '(utility address)',
      ));
    }

    // ── 6. Bank holder vs Aadhaar name ──
    // Bank statements don't extract the holder name in current OCR schema — skip

    return issues;
  }

  /// Check if there are any ERROR-level issues that should block scoring
  static bool hasBlockingErrors(List<ValidationIssue> issues) {
    return issues.any((i) => i.severity == IssueSeverity.error);
  }

  /// Get only WARNING+ severity issues for UI display
  static List<ValidationIssue> getDisplayableIssues(List<ValidationIssue> issues) {
    return issues
        .where((i) => i.severity == IssueSeverity.warning || i.severity == IssueSeverity.error)
        .toList();
  }

  // ── Fuzzy matching ──

  /// Simple normalized Levenshtein-based similarity (0.0–1.0)
  static double _fuzzyMatch(String a, String b) {
    final s1 = a.toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final s2 = b.toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    final dist = _levenshtein(s1, s2);
    return 1.0 - (dist / maxLen);
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (var j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  // ── Helpers ──

  static String _getString(Map<String, Map<String, dynamic>> data, String docType, String key) {
    return (data[docType]?[key]?.toString() ?? '').trim();
  }

  /// Normalize date strings for comparison (handle dd/mm/yyyy, yyyy-mm-dd, etc.)
  static String _normalizeDateString(String date) {
    // Strip all separators, compare raw digits
    return date.replaceAll(RegExp(r'[/\-.]'), '').trim();
  }

  /// Normalize vehicle numbers (strip spaces, uppercase)
  static String _normalizeVehicle(String v) {
    return v.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }
}

enum IssueSeverity { error, warning, info }

class ValidationIssue {
  final String code;
  final String title;
  final String description;
  final IssueSeverity severity;
  final List<int> steps; // which steps are involved
  final String field1;
  final String field2;
  final double? similarity; // for fuzzy match checks

  const ValidationIssue({
    required this.code,
    required this.title,
    required this.description,
    required this.severity,
    required this.steps,
    required this.field1,
    required this.field2,
    this.similarity,
  });
}
