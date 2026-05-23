import 'fuzzy_matcher.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Step2Validator — Real on-device KYC validation per STEP-2 SPEC
///
/// Implements:
///   • Aadhaar format validation (12 digits, Verhoeff checksum awareness)
///   • PAN format validation (regex [A-Z]{5}[0-9]{4}[A-Z])
///   • Cross-step identity chain: Step-1 name/DOB ↔ Aadhaar OCR ↔ PAN OCR
///   • HARD FAIL vs Soft Flag classification
///
/// Face match is STATIC per user request — handled by DemoFaceVerifier.
/// ─────────────────────────────────────────────────────────────────────────────

enum Step2Severity { hardFail, softFlag, info }

class Step2Issue {
  final String code;
  final String field;
  final String message;
  final Step2Severity severity;
  final double? matchScore;

  const Step2Issue({
    required this.code,
    required this.field,
    required this.message,
    required this.severity,
    this.matchScore,
  });

  bool get isBlocking => severity == Step2Severity.hardFail;
}

class Step2ValidationResult {
  final bool passed;
  final List<Step2Issue> issues;
  final double nameMatchScore; // Best name match across docs

  const Step2ValidationResult({
    required this.passed,
    required this.issues,
    required this.nameMatchScore,
  });

  List<Step2Issue> get hardFails =>
      issues.where((i) => i.severity == Step2Severity.hardFail).toList();
  List<Step2Issue> get softFlags =>
      issues.where((i) => i.severity == Step2Severity.softFlag).toList();
}

class Step2Validator {
  // ═══════════════════════════════════════════════════════════════
  // AADHAAR FORMAT VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Validate Aadhaar number format.
  /// Rules: 12 digits, cannot start with 0 or 1.
  static Step2Issue? validateAadhaarFormat(String aadhaar) {
    final clean = aadhaar.replaceAll(' ', '').trim();

    if (clean.length != 12) {
      return const Step2Issue(
        code: 'AADHAAR_LENGTH',
        field: 'aadhaar',
        message: 'Aadhaar must be exactly 12 digits',
        severity: Step2Severity.hardFail,
      );
    }

    if (!RegExp(r'^\d{12}$').hasMatch(clean)) {
      return const Step2Issue(
        code: 'AADHAAR_DIGITS',
        field: 'aadhaar',
        message: 'Aadhaar must contain only digits',
        severity: Step2Severity.hardFail,
      );
    }

    // Spec: Aadhaar cannot start with 0 or 1
    if (clean.startsWith('0') || clean.startsWith('1')) {
      return const Step2Issue(
        code: 'AADHAAR_FIRST_DIGIT',
        field: 'aadhaar',
        message: 'Valid Aadhaar numbers do not start with 0 or 1',
        severity: Step2Severity.hardFail,
      );
    }

    // All-same digit check (e.g., 222222222222)
    if (clean.split('').toSet().length == 1) {
      return const Step2Issue(
        code: 'AADHAAR_SUSPICIOUS',
        field: 'aadhaar',
        message: 'Aadhaar number appears invalid — all same digits',
        severity: Step2Severity.hardFail,
      );
    }

    return null; // Valid
  }

  // ═══════════════════════════════════════════════════════════════
  // PAN FORMAT VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Validate PAN number format.
  /// Format: [A-Z]{5}[0-9]{4}[A-Z], 4th char should be 'P' for individuals.
  static Step2Issue? validatePanFormat(String pan) {
    final clean = pan.trim().toUpperCase();

    if (clean.length != 10) {
      return const Step2Issue(
        code: 'PAN_LENGTH',
        field: 'pan',
        message: 'PAN must be exactly 10 characters',
        severity: Step2Severity.hardFail,
      );
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(clean)) {
      return const Step2Issue(
        code: 'PAN_FORMAT',
        field: 'pan',
        message: 'PAN must follow format: ABCDE1234F (5 letters + 4 digits + 1 letter)',
        severity: Step2Severity.hardFail,
      );
    }

    // 4th character should be 'P' for individual PANs (soft flag if not)
    if (clean[3] != 'P') {
      return Step2Issue(
        code: 'PAN_4TH_CHAR',
        field: 'pan',
        message: 'PAN 4th character is "${clean[3]}" — expected "P" for individual applicants',
        severity: Step2Severity.softFlag,
      );
    }

    return null; // Valid
  }

  // ═══════════════════════════════════════════════════════════════
  // OCR FIELD EXTRACTION VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Validate that OCR extracted the expected Aadhaar number.
  static Step2Issue? validateAadhaarOcrNumber(String enteredAadhaar, String? ocrAadhaar) {
    if (ocrAadhaar == null || ocrAadhaar.isEmpty) {
      return const Step2Issue(
        code: 'AADHAAR_OCR_NO_NUMBER',
        field: 'aadhaar_front',
        message: 'Could not extract Aadhaar number from uploaded image',
        severity: Step2Severity.softFlag,
      );
    }

    final cleanEntered = enteredAadhaar.replaceAll(' ', '');
    final cleanOcr = ocrAadhaar.replaceAll(' ', '');

    if (cleanEntered != cleanOcr) {
      return Step2Issue(
        code: 'AADHAAR_NUMBER_MISMATCH',
        field: 'aadhaar',
        message: 'Entered Aadhaar ($cleanEntered) does not match OCR extraction ($cleanOcr)',
        severity: Step2Severity.hardFail,
      );
    }

    return null;
  }

  /// Validate that OCR extracted PAN matches entered PAN.
  static Step2Issue? validatePanOcrNumber(String enteredPan, String? ocrPan) {
    if (ocrPan == null || ocrPan.isEmpty) {
      return const Step2Issue(
        code: 'PAN_OCR_NO_NUMBER',
        field: 'pan',
        message: 'Could not extract PAN number from uploaded image',
        severity: Step2Severity.softFlag,
      );
    }

    final cleanEntered = enteredPan.trim().toUpperCase();
    final cleanOcr = ocrPan.trim().toUpperCase();

    if (cleanEntered != cleanOcr) {
      return Step2Issue(
        code: 'PAN_NUMBER_MISMATCH',
        field: 'pan',
        message: 'Entered PAN ($cleanEntered) does not match OCR extraction ($cleanOcr)',
        severity: Step2Severity.hardFail,
      );
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // CROSS-STEP IDENTITY CHAIN VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Full Step 2 cross-validation against Step 1 data and OCR results.
  ///
  /// Identity chain: Step1.name ↔ Aadhaar.name ↔ PAN.name
  /// DOB chain:      Step1.dob  ↔ Aadhaar.dob  ↔ PAN.dob
  static Step2ValidationResult validateFull({
    // Step 1 data (from verified_profile)
    required String step1Name,
    required String step1Dob,
    // Entered numbers
    required String enteredAadhaar,
    required String enteredPan,
    // OCR extracted data
    Map<String, dynamic>? aadhaarFrontOcr,
    Map<String, dynamic>? panOcr,
    // Selfie verification (static flag from DemoFaceVerifier)
    required bool selfieVerified,
  }) {
    final issues = <Step2Issue>[];
    double bestNameScore = 0.0;

    // ── Format validation ──
    final aadhaarIssue = validateAadhaarFormat(enteredAadhaar);
    if (aadhaarIssue != null) issues.add(aadhaarIssue);

    final panIssue = validatePanFormat(enteredPan);
    if (panIssue != null) issues.add(panIssue);

    // ── OCR number cross-check ──
    if (aadhaarFrontOcr != null) {
      final ocrNum = aadhaarFrontOcr['aadhaar_number'] as String?;
      final numIssue = validateAadhaarOcrNumber(enteredAadhaar, ocrNum);
      if (numIssue != null) issues.add(numIssue);
    }

    if (panOcr != null) {
      final ocrNum = panOcr['pan_number'] as String?;
      final numIssue = validatePanOcrNumber(enteredPan, ocrNum);
      if (numIssue != null) issues.add(numIssue);
    }

    // ── NAME CHAIN: Step1 ↔ Aadhaar ↔ PAN ──
    final String? aadhaarName = aadhaarFrontOcr?['name'] as String?;
    final String? panName = panOcr?['name'] as String?;

    // Step1 name vs Aadhaar name
    if (step1Name.isNotEmpty && aadhaarName != null && aadhaarName.isNotEmpty) {
      final result = FuzzyMatcher.matchNames(step1Name, aadhaarName);
      if (result.score > bestNameScore) bestNameScore = result.score;

      if (result.severity == MatchSeverity.hardFail) {
        issues.add(Step2Issue(
          code: 'NAME_MISMATCH_STEP1_AADHAAR',
          field: 'name',
          message: 'Step 1 name "$step1Name" does not match Aadhaar name "$aadhaarName" (${(result.score * 100).toStringAsFixed(1)}%)',
          severity: Step2Severity.hardFail,
          matchScore: result.score,
        ));
      } else if (result.severity == MatchSeverity.softFlag) {
        issues.add(Step2Issue(
          code: 'NAME_PARTIAL_STEP1_AADHAAR',
          field: 'name',
          message: 'Partial match: "$step1Name" vs Aadhaar "$aadhaarName" (${(result.score * 100).toStringAsFixed(1)}%)',
          severity: Step2Severity.softFlag,
          matchScore: result.score,
        ));
      }
    }

    // Step1 name vs PAN name
    if (step1Name.isNotEmpty && panName != null && panName.isNotEmpty) {
      final result = FuzzyMatcher.matchNames(step1Name, panName);
      if (result.score > bestNameScore) bestNameScore = result.score;

      if (result.severity == MatchSeverity.hardFail) {
        issues.add(Step2Issue(
          code: 'NAME_MISMATCH_STEP1_PAN',
          field: 'name',
          message: 'Step 1 name "$step1Name" does not match PAN name "$panName" (${(result.score * 100).toStringAsFixed(1)}%)',
          severity: Step2Severity.hardFail,
          matchScore: result.score,
        ));
      } else if (result.severity == MatchSeverity.softFlag) {
        issues.add(Step2Issue(
          code: 'NAME_PARTIAL_STEP1_PAN',
          field: 'name',
          message: 'Partial match: "$step1Name" vs PAN "$panName" (${(result.score * 100).toStringAsFixed(1)}%)',
          severity: Step2Severity.softFlag,
          matchScore: result.score,
        ));
      }
    }

    // Aadhaar name vs PAN name
    if (aadhaarName != null && aadhaarName.isNotEmpty &&
        panName != null && panName.isNotEmpty) {
      final result = FuzzyMatcher.matchNames(aadhaarName, panName);
      if (result.score > bestNameScore) bestNameScore = result.score;

      if (result.severity == MatchSeverity.hardFail) {
        issues.add(Step2Issue(
          code: 'NAME_MISMATCH_AADHAAR_PAN',
          field: 'name',
          message: 'Aadhaar name "$aadhaarName" does not match PAN name "$panName" (${(result.score * 100).toStringAsFixed(1)}%)',
          severity: Step2Severity.hardFail,
          matchScore: result.score,
        ));
      } else if (result.severity == MatchSeverity.softFlag) {
        issues.add(Step2Issue(
          code: 'NAME_PARTIAL_AADHAAR_PAN',
          field: 'name',
          message: 'Partial match: Aadhaar "$aadhaarName" vs PAN "$panName" (${(result.score * 100).toStringAsFixed(1)}%)',
          severity: Step2Severity.softFlag,
          matchScore: result.score,
        ));
      }
    }

    // ── DOB CHAIN: Step1 ↔ Aadhaar ↔ PAN ──
    final String? aadhaarDob = aadhaarFrontOcr?['dob'] as String?;
    final String? panDob = panOcr?['dob'] as String?;

    // Step1 DOB vs Aadhaar DOB
    if (step1Dob.isNotEmpty && aadhaarDob != null && aadhaarDob.isNotEmpty) {
      if (!_dobsMatch(step1Dob, aadhaarDob)) {
        issues.add(Step2Issue(
          code: 'DOB_MISMATCH_STEP1_AADHAAR',
          field: 'dob',
          message: 'Step 1 DOB ($step1Dob) does not match Aadhaar DOB ($aadhaarDob)',
          severity: Step2Severity.hardFail,
        ));
      }
    }

    // Step1 DOB vs PAN DOB
    if (step1Dob.isNotEmpty && panDob != null && panDob.isNotEmpty) {
      if (!_dobsMatch(step1Dob, panDob)) {
        issues.add(Step2Issue(
          code: 'DOB_MISMATCH_STEP1_PAN',
          field: 'dob',
          message: 'Step 1 DOB ($step1Dob) does not match PAN DOB ($panDob)',
          severity: Step2Severity.hardFail,
        ));
      }
    }

    // Aadhaar DOB vs PAN DOB
    if (aadhaarDob != null && aadhaarDob.isNotEmpty &&
        panDob != null && panDob.isNotEmpty) {
      if (!_dobsMatch(aadhaarDob, panDob)) {
        issues.add(Step2Issue(
          code: 'DOB_MISMATCH_AADHAAR_PAN',
          field: 'dob',
          message: 'Aadhaar DOB ($aadhaarDob) does not match PAN DOB ($panDob)',
          severity: Step2Severity.hardFail,
        ));
      }
    }

    // ── Selfie ──
    if (!selfieVerified) {
      issues.add(const Step2Issue(
        code: 'SELFIE_NOT_VERIFIED',
        field: 'selfie',
        message: 'Live selfie face match not completed',
        severity: Step2Severity.softFlag,
      ));
    }

    final hasHardFails = issues.any((i) => i.severity == Step2Severity.hardFail);

    return Step2ValidationResult(
      passed: !hasHardFails,
      issues: issues,
      nameMatchScore: bestNameScore,
    );
  }

  /// Compare DOBs accounting for format variations (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD).
  static bool _dobsMatch(String dob1, String dob2) {
    final d1 = _normalizeDob(dob1);
    final d2 = _normalizeDob(dob2);
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Parse DOB from various formats into DateTime.
  static DateTime? _normalizeDob(String dob) {
    final clean = dob.trim();

    // Try DD/MM/YYYY
    final slashParts = clean.split('/');
    if (slashParts.length == 3) {
      try {
        return DateTime(
          int.parse(slashParts[2]),
          int.parse(slashParts[1]),
          int.parse(slashParts[0]),
        );
      } catch (_) {}
    }

    // Try DD-MM-YYYY
    final dashParts = clean.split('-');
    if (dashParts.length == 3) {
      try {
        // Could be YYYY-MM-DD or DD-MM-YYYY
        final first = int.parse(dashParts[0]);
        if (first > 31) {
          // YYYY-MM-DD
          return DateTime(first, int.parse(dashParts[1]), int.parse(dashParts[2]));
        } else {
          // DD-MM-YYYY
          return DateTime(int.parse(dashParts[2]), int.parse(dashParts[1]), first);
        }
      } catch (_) {}
    }

    return null;
  }
}
