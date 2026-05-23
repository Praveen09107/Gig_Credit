/// ─────────────────────────────────────────────────────────────────────────────
/// Step1Validator — Real on-device validation per GIGCREDIT STEP-1 SPEC
///
/// Implements all validation rules from the specification:
///   • Field-level format validation (13 fields)
///   • Cross-internal consistency checks (age vs profession, income checks)
///   • HARD FAIL (blocking) vs Soft Flag (non-blocking) classification
///
/// Spec reference: GIGCREDIT — STEP-1 VALIDATION & VERIFICATION
/// ─────────────────────────────────────────────────────────────────────────────

/// Severity of a validation issue
enum Step1Severity { hardFail, softFlag, info }

/// A single validation issue found during Step 1 checks
class Step1Issue {
  final String code;
  final String field;
  final String message;
  final Step1Severity severity;

  const Step1Issue({
    required this.code,
    required this.field,
    required this.message,
    required this.severity,
  });

  bool get isBlocking => severity == Step1Severity.hardFail;
}

/// Result of Step 1 validation
class Step1ValidationResult {
  final bool passed;
  final List<Step1Issue> issues;
  final int age;

  const Step1ValidationResult({
    required this.passed,
    required this.issues,
    required this.age,
  });

  List<Step1Issue> get hardFails =>
      issues.where((i) => i.severity == Step1Severity.hardFail).toList();
  List<Step1Issue> get softFlags =>
      issues.where((i) => i.severity == Step1Severity.softFlag).toList();
  List<Step1Issue> get infos =>
      issues.where((i) => i.severity == Step1Severity.info).toList();
}

class Step1Validator {
  /// Run all Step 1 validation checks.
  /// Returns a result indicating pass/fail + all issues found.
  static Step1ValidationResult validate({
    required String fullName,
    required String dateOfBirth,
    required String mobileNumber,
    required String currentAddress,
    required String permanentAddress,
    required String stateOfResidence,
    required String workType,
    required double selfDeclaredIncome,
    required int yearsInProfession,
    required int dependents,
    required bool vehicleOwnership,
    double? secondaryIncome,
    bool sameAddress = false,
  }) {
    final issues = <Step1Issue>[];
    int computedAge = 0;

    // ═══════════════════════════════════════════════════════════════
    // FIELD-LEVEL VALIDATION
    // ═══════════════════════════════════════════════════════════════

    // ── 1. Full Name ──
    final name = fullName.trim();
    if (name.length < 2 || name.length > 50) {
      issues.add(const Step1Issue(
        code: 'NAME_LENGTH',
        field: 'fullName',
        message: 'Name must be 2-50 characters',
        severity: Step1Severity.hardFail,
      ));
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      issues.add(const Step1Issue(
        code: 'NAME_FORMAT',
        field: 'fullName',
        message: 'Name must contain only letters and spaces',
        severity: Step1Severity.hardFail,
      ));
    } else {
      // Name should have at least 2 words (first + last)
      final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length < 2) {
        issues.add(const Step1Issue(
          code: 'NAME_SINGLE_WORD',
          field: 'fullName',
          message: 'Please enter your full name (first and last name)',
          severity: Step1Severity.softFlag,
        ));
      }
    }

    // ── 2. Date of Birth ──
    final dob = dateOfBirth.trim();
    final dobParts = dob.split('/');
    if (dobParts.length != 3) {
      issues.add(const Step1Issue(
        code: 'DOB_FORMAT',
        field: 'dateOfBirth',
        message: 'Use DD/MM/YYYY format',
        severity: Step1Severity.hardFail,
      ));
    } else {
      try {
        final day = int.parse(dobParts[0]);
        final month = int.parse(dobParts[1]);
        final year = int.parse(dobParts[2]);

        if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 || year > 2020) {
          issues.add(const Step1Issue(
            code: 'DOB_RANGE',
            field: 'dateOfBirth',
            message: 'Invalid date values',
            severity: Step1Severity.hardFail,
          ));
        } else {
          // Compute age: floor((today - dob) / 365.25)
          final dobDate = DateTime(year, month, day);
          final now = DateTime.now();
          computedAge = now.year - dobDate.year;
          if (now.month < dobDate.month ||
              (now.month == dobDate.month && now.day < dobDate.day)) {
            computedAge--;
          }

          // Spec: age must be 18-65
          if (computedAge < 18) {
            issues.add(Step1Issue(
              code: 'AGE_UNDERAGE',
              field: 'dateOfBirth',
              message: 'Applicant must be at least 18 years old (computed age: $computedAge)',
              severity: Step1Severity.hardFail,
            ));
          } else if (computedAge > 65) {
            issues.add(Step1Issue(
              code: 'AGE_OVERAGE',
              field: 'dateOfBirth',
              message: 'Applicant must be 65 or younger (computed age: $computedAge)',
              severity: Step1Severity.hardFail,
            ));
          }

          // Spec: future date check
          if (dobDate.isAfter(now)) {
            issues.add(const Step1Issue(
              code: 'DOB_FUTURE',
              field: 'dateOfBirth',
              message: 'Date of birth cannot be in the future',
              severity: Step1Severity.hardFail,
            ));
          }
        }
      } catch (_) {
        issues.add(const Step1Issue(
          code: 'DOB_PARSE',
          field: 'dateOfBirth',
          message: 'Cannot parse date. Use DD/MM/YYYY',
          severity: Step1Severity.hardFail,
        ));
      }
    }

    // ── 3. Mobile Number ──
    final mobile = mobileNumber.trim();
    if (mobile.length != 10) {
      issues.add(const Step1Issue(
        code: 'MOBILE_LENGTH',
        field: 'mobileNumber',
        message: 'Mobile number must be exactly 10 digits',
        severity: Step1Severity.hardFail,
      ));
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      issues.add(const Step1Issue(
        code: 'MOBILE_FORMAT',
        field: 'mobileNumber',
        message: 'Indian mobile numbers must start with 6, 7, 8, or 9',
        severity: Step1Severity.hardFail,
      ));
    }

    // ── 4. Current Address ──
    final currAddr = currentAddress.trim();
    if (currAddr.length < 10) {
      issues.add(const Step1Issue(
        code: 'ADDR_SHORT',
        field: 'currentAddress',
        message: 'Address must be at least 10 characters',
        severity: Step1Severity.hardFail,
      ));
    } else if (currAddr.length > 200) {
      issues.add(const Step1Issue(
        code: 'ADDR_LONG',
        field: 'currentAddress',
        message: 'Address must be under 200 characters',
        severity: Step1Severity.hardFail,
      ));
    } else {
      // Address should have at least 2 words
      final addrWords = currAddr.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (addrWords.length < 2) {
        issues.add(const Step1Issue(
          code: 'ADDR_TOO_SIMPLE',
          field: 'currentAddress',
          message: 'Address seems incomplete — add area, city, or PIN code',
          severity: Step1Severity.softFlag,
        ));
      }
    }

    // ── 5. Permanent Address ──
    if (!sameAddress) {
      final permAddr = permanentAddress.trim();
      if (permAddr.length < 10) {
        issues.add(const Step1Issue(
          code: 'PERM_ADDR_SHORT',
          field: 'permanentAddress',
          message: 'Permanent address must be at least 10 characters',
          severity: Step1Severity.hardFail,
        ));
      }
    }

    // ── 6. State ──
    if (stateOfResidence.isEmpty) {
      issues.add(const Step1Issue(
        code: 'STATE_EMPTY',
        field: 'stateOfResidence',
        message: 'State of residence is required',
        severity: Step1Severity.hardFail,
      ));
    }

    // ── 7. Work Type ──
    const validWorkTypes = [
      'platform_worker', 'vendor', 'tradesperson', 'freelancer',
      'salaried', 'self_employed', 'gig_worker', 'unemployed', 'student',
    ];
    if (!validWorkTypes.contains(workType)) {
      issues.add(const Step1Issue(
        code: 'WORK_TYPE_INVALID',
        field: 'workType',
        message: 'Invalid work type selected',
        severity: Step1Severity.hardFail,
      ));
    }

    // ── 8. Self-Declared Income ──
    if (selfDeclaredIncome < 1000) {
      issues.add(const Step1Issue(
        code: 'INCOME_LOW',
        field: 'selfDeclaredIncome',
        message: 'Monthly income must be at least ₹1,000',
        severity: Step1Severity.hardFail,
      ));
    } else if (selfDeclaredIncome > 200000) {
      issues.add(Step1Issue(
        code: 'INCOME_HIGH',
        field: 'selfDeclaredIncome',
        message: 'Monthly income exceeds ₹2,00,000 cap — will be verified against bank data',
        severity: Step1Severity.softFlag,
      ));
    }

    // ── 9. Years in Profession ──
    if (yearsInProfession < 0 || yearsInProfession > 40) {
      issues.add(const Step1Issue(
        code: 'YEARS_RANGE',
        field: 'yearsInProfession',
        message: 'Years in profession must be 0-40',
        severity: Step1Severity.hardFail,
      ));
    }

    // ── 10. Dependents ──
    if (dependents < 0 || dependents > 10) {
      issues.add(const Step1Issue(
        code: 'DEPENDENTS_RANGE',
        field: 'dependents',
        message: 'Dependents must be 0-10',
        severity: Step1Severity.hardFail,
      ));
    }

    // ═══════════════════════════════════════════════════════════════
    // CROSS-INTERNAL CONSISTENCY CHECKS (Spec Section 3)
    // ═══════════════════════════════════════════════════════════════

    // ── CI-1: Age vs Years in Profession ──
    // Spec: years_in_profession > (age - 14) → HARD FAIL
    if (computedAge > 0 && yearsInProfession > (computedAge - 14)) {
      issues.add(Step1Issue(
        code: 'AGE_VS_PROFESSION',
        field: 'yearsInProfession',
        message: 'Claims $yearsInProfession years in profession but is only $computedAge years old — impossible',
        severity: Step1Severity.hardFail,
      ));
    }

    // ── CI-2: Age vs Dependents ──
    // Spec: age < 21 && dependents > 0 → soft flag
    if (computedAge > 0 && computedAge < 21 && dependents > 0) {
      issues.add(Step1Issue(
        code: 'AGE_VS_DEPENDENTS',
        field: 'dependents',
        message: 'Age $computedAge with $dependents dependents — unusual for this age group',
        severity: Step1Severity.softFlag,
      ));
    }

    // ── CI-3: Primary vs Secondary Income ──
    // Spec: secondary_income > primary_income → HARD FAIL
    if (secondaryIncome != null && secondaryIncome > 0) {
      if (secondaryIncome > selfDeclaredIncome) {
        issues.add(Step1Issue(
          code: 'SECONDARY_EXCEEDS_PRIMARY',
          field: 'secondaryIncome',
          message: 'Secondary income (₹${secondaryIncome.toStringAsFixed(0)}) exceeds primary income (₹${selfDeclaredIncome.toStringAsFixed(0)}) — this should be reversed',
          severity: Step1Severity.hardFail,
        ));
      }
    }

    // ── CI-4: State vs Address Consistency ──
    // Spec: state name substring should appear in address (soft flag if not)
    if (stateOfResidence.isNotEmpty && currAddr.length >= 10) {
      final stateUpper = stateOfResidence.toUpperCase();
      final addrUpper = currAddr.toUpperCase();

      // Check if state name (or common abbreviation) is in the address
      final stateAbbreviations = _getStateAbbreviations(stateOfResidence);
      bool stateInAddr = addrUpper.contains(stateUpper);
      if (!stateInAddr) {
        for (final abbr in stateAbbreviations) {
          if (addrUpper.contains(abbr.toUpperCase())) {
            stateInAddr = true;
            break;
          }
        }
      }

      if (!stateInAddr) {
        issues.add(Step1Issue(
          code: 'STATE_ADDR_MISMATCH',
          field: 'currentAddress',
          message: 'Address does not mention "$stateOfResidence" — verify correctness',
          severity: Step1Severity.softFlag,
        ));
      }
    }

    // ── CI-5: Address Comparison (current vs permanent) ──
    if (!sameAddress && permanentAddress.trim().isNotEmpty && currAddr.isNotEmpty) {
      final normalizedCurr = _normalizeAddress(currAddr);
      final normalizedPerm = _normalizeAddress(permanentAddress.trim());
      if (normalizedCurr == normalizedPerm) {
        issues.add(const Step1Issue(
          code: 'ADDR_IDENTICAL',
          field: 'permanentAddress',
          message: 'Current and permanent addresses are identical — consider using "Same as current"',
          severity: Step1Severity.info,
        ));
      }
    }

    // ── CI-6: Unemployed/Student with high income ──
    if ((workType == 'unemployed' || workType == 'student') && selfDeclaredIncome > 20000) {
      issues.add(Step1Issue(
        code: 'WORK_INCOME_MISMATCH',
        field: 'selfDeclaredIncome',
        message: 'Work type "$workType" with income ₹${selfDeclaredIncome.toStringAsFixed(0)} — will be verified against bank data',
        severity: Step1Severity.softFlag,
      ));
    }

    // ── CI-7: Dependents vs Income ratio ──
    if (dependents > 0 && selfDeclaredIncome > 0) {
      final incomePerDependent = selfDeclaredIncome / dependents;
      if (incomePerDependent < 2000) {
        issues.add(Step1Issue(
          code: 'INCOME_PER_DEPENDENT_LOW',
          field: 'dependents',
          message: 'Income per dependent is only ₹${incomePerDependent.toStringAsFixed(0)} — financial stress indicator',
          severity: Step1Severity.softFlag,
        ));
      }
    }

    // Determine overall pass/fail (HARD FAIL = blocking)
    final hasHardFails = issues.any((i) => i.severity == Step1Severity.hardFail);

    return Step1ValidationResult(
      passed: !hasHardFails,
      issues: issues,
      age: computedAge,
    );
  }

  /// Common abbreviations for Indian states
  static List<String> _getStateAbbreviations(String state) {
    final map = {
      'Tamil Nadu': ['TN', 'TAMILNADU', 'CHENNAI'],
      'Karnataka': ['KA', 'KARNATAKA', 'BANGALORE', 'BENGALURU'],
      'Maharashtra': ['MH', 'MAHARASHTRA', 'MUMBAI', 'PUNE'],
      'Andhra Pradesh': ['AP', 'ANDHRA'],
      'Telangana': ['TS', 'TELANGANA', 'HYDERABAD'],
      'Kerala': ['KL', 'KERALA', 'KOCHI', 'TRIVANDRUM'],
      'Gujarat': ['GJ', 'GUJARAT', 'AHMEDABAD'],
      'Rajasthan': ['RJ', 'RAJASTHAN', 'JAIPUR'],
      'Uttar Pradesh': ['UP', 'UTTAR PRADESH'],
      'West Bengal': ['WB', 'KOLKATA'],
      'Delhi': ['DL', 'DELHI', 'NEW DELHI'],
      'Punjab': ['PB', 'PUNJAB'],
      'Haryana': ['HR', 'HARYANA'],
      'Bihar': ['BR', 'BIHAR', 'PATNA'],
      'Madhya Pradesh': ['MP', 'MADHYA PRADESH', 'BHOPAL'],
      'Odisha': ['OD', 'ODISHA', 'BHUBANESWAR'],
      'Jharkhand': ['JH', 'JHARKHAND', 'RANCHI'],
      'Chhattisgarh': ['CG', 'CHHATTISGARH'],
      'Goa': ['GA', 'GOA'],
    };
    return map[state] ?? [state];
  }

  /// Normalize address for comparison
  static String _normalizeAddress(String addr) {
    return addr
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }
}
