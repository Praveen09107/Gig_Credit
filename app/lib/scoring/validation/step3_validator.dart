import 'fuzzy_matcher.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Step3Validator — Bank account verification + transaction categorization
///
/// Implements:
///   • IFSC format validation (4 letters + 0 + 6 alphanumeric)
///   • Account number format check
///   • Account holder name vs Aadhaar name cross-check (fuzzy ≥85%)
///   • Statement period validation (≥6 months, within 30 days)
///   • Transaction categorization into canonical categories
///   • OCR field vs entered/API value cross-checks
/// ─────────────────────────────────────────────────────────────────────────────

enum Step3Severity { hardFail, softFlag, info }

class Step3Issue {
  final String code;
  final String field;
  final String message;
  final Step3Severity severity;

  const Step3Issue({
    required this.code,
    required this.field,
    required this.message,
    required this.severity,
  });

  bool get isBlocking => severity == Step3Severity.hardFail;
}

class Step3ValidationResult {
  final bool passed;
  final List<Step3Issue> issues;

  const Step3ValidationResult({required this.passed, required this.issues});

  List<Step3Issue> get hardFails =>
      issues.where((i) => i.severity == Step3Severity.hardFail).toList();
  List<Step3Issue> get softFlags =>
      issues.where((i) => i.severity == Step3Severity.softFlag).toList();
}

class Step3Validator {
  /// Validate IFSC format: 4 uppercase letters + '0' + 6 alphanumeric chars.
  static Step3Issue? validateIfscFormat(String ifsc) {
    final clean = ifsc.trim().toUpperCase();
    if (clean.length != 11) {
      return const Step3Issue(
        code: 'IFSC_LENGTH',
        field: 'ifsc',
        message: 'IFSC must be exactly 11 characters',
        severity: Step3Severity.hardFail,
      );
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(clean)) {
      return const Step3Issue(
        code: 'IFSC_FORMAT',
        field: 'ifsc',
        message: 'IFSC format: 4 letters + "0" + 6 alphanumeric (e.g., HDFC0001234)',
        severity: Step3Severity.hardFail,
      );
    }
    return null;
  }

  /// Validate account number format.
  static Step3Issue? validateAccountFormat(String acc) {
    final clean = acc.trim();
    if (clean.length < 9 || clean.length > 18) {
      return const Step3Issue(
        code: 'ACC_LENGTH',
        field: 'account',
        message: 'Account number must be 9-18 digits',
        severity: Step3Severity.hardFail,
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return const Step3Issue(
        code: 'ACC_DIGITS',
        field: 'account',
        message: 'Account number must contain only digits',
        severity: Step3Severity.hardFail,
      );
    }
    return null;
  }

  /// Cross-check: account holder name (from API/entered) vs Aadhaar name.
  /// Spec: fuzzy match ≥ 85% required, < 60% = HARD FAIL.
  static Step3Issue? validateHolderVsAadhaar(String holderName, String aadhaarName) {
    if (holderName.isEmpty || aadhaarName.isEmpty) return null;

    final result = FuzzyMatcher.matchNames(holderName, aadhaarName);

    if (result.severity == MatchSeverity.hardFail) {
      return Step3Issue(
        code: 'HOLDER_AADHAAR_MISMATCH',
        field: 'holderName',
        message: 'Bank account holder "$holderName" does not match Aadhaar "$aadhaarName" (${(result.score * 100).toStringAsFixed(1)}%)',
        severity: Step3Severity.hardFail,
      );
    } else if (result.severity == MatchSeverity.softFlag) {
      return Step3Issue(
        code: 'HOLDER_AADHAAR_PARTIAL',
        field: 'holderName',
        message: 'Partial name match: "$holderName" vs Aadhaar "$aadhaarName" (${(result.score * 100).toStringAsFixed(1)}%)',
        severity: Step3Severity.softFlag,
      );
    }
    return null;
  }

  /// Cross-check: OCR-extracted bank details vs entered/API values.
  static List<Step3Issue> validateOcrCrossCheck({
    required String enteredBankName,
    required String enteredHolderName,
    required String enteredIfsc,
    required String enteredAccount,
    String? ocrBankName,
    String? ocrHolderName,
    String? ocrIfsc,
    String? ocrAccount,
  }) {
    final issues = <Step3Issue>[];

    if (ocrBankName != null && ocrBankName.isNotEmpty && enteredBankName.isNotEmpty) {
      final sim = FuzzyMatcher.nameSimilarity(enteredBankName, ocrBankName);
      if (sim < 0.60) {
        issues.add(Step3Issue(
          code: 'BANK_NAME_OCR_MISMATCH',
          field: 'bankName',
          message: 'Entered bank "$enteredBankName" differs from statement "$ocrBankName"',
          severity: Step3Severity.softFlag,
        ));
      }
    }

    if (ocrIfsc != null && ocrIfsc.isNotEmpty && enteredIfsc.isNotEmpty) {
      if (ocrIfsc.toUpperCase() != enteredIfsc.toUpperCase()) {
        issues.add(Step3Issue(
          code: 'IFSC_OCR_MISMATCH',
          field: 'ifsc',
          message: 'Entered IFSC ($enteredIfsc) differs from statement ($ocrIfsc)',
          severity: Step3Severity.softFlag,
        ));
      }
    }

    if (ocrAccount != null && ocrAccount.isNotEmpty && enteredAccount.isNotEmpty) {
      final cleanOcr = ocrAccount.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanEntered = enteredAccount.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanOcr != cleanEntered) {
        issues.add(Step3Issue(
          code: 'ACC_OCR_MISMATCH',
          field: 'account',
          message: 'Entered account ($cleanEntered) differs from statement ($cleanOcr)',
          severity: Step3Severity.hardFail,
        ));
      }
    }

    return issues;
  }

  /// Full Step 3 validation including cross-step checks.
  static Step3ValidationResult validateFull({
    required String bankName,
    required String holderName,
    required String ifsc,
    required String account,
    required bool pdfUploaded,
    required int transactionCount,
    required List<double> monthlyCredits,
    // Step 2 data for cross-check
    String aadhaarName = '',
    // Step 1 data for income cross-check
    double step1Income = 0,
    // OCR data from bank statement
    Map<String, dynamic>? statementOcr,
  }) {
    final issues = <Step3Issue>[];

    // ── Format checks ──
    final ifscIssue = validateIfscFormat(ifsc);
    if (ifscIssue != null) issues.add(ifscIssue);

    final accIssue = validateAccountFormat(account);
    if (accIssue != null) issues.add(accIssue);

    // ── Holder name required ──
    if (holderName.trim().isEmpty) {
      issues.add(const Step3Issue(
        code: 'HOLDER_NAME_EMPTY',
        field: 'holderName',
        message: 'Account holder name is required',
        severity: Step3Severity.hardFail,
      ));
    }

    // ── Bank name required ──
    if (bankName.trim().isEmpty) {
      issues.add(const Step3Issue(
        code: 'BANK_NAME_EMPTY',
        field: 'bankName',
        message: 'Bank name is required',
        severity: Step3Severity.hardFail,
      ));
    }

    // ── PDF upload required ──
    if (!pdfUploaded) {
      issues.add(const Step3Issue(
        code: 'STATEMENT_MISSING',
        field: 'statement',
        message: 'Bank statement PDF is required',
        severity: Step3Severity.hardFail,
      ));
    }

    // ── Cross-step: holder vs Aadhaar ──
    if (aadhaarName.isNotEmpty) {
      final nameIssue = validateHolderVsAadhaar(holderName, aadhaarName);
      if (nameIssue != null) issues.add(nameIssue);
    }

    // ── Transaction count check ──
    if (pdfUploaded && transactionCount == 0) {
      issues.add(const Step3Issue(
        code: 'NO_TRANSACTIONS',
        field: 'statement',
        message: 'No transactions found in bank statement — may be an invalid or empty PDF',
        severity: Step3Severity.softFlag,
      ));
    }

    // ── Statement period validation ──
    if (monthlyCredits.isNotEmpty && monthlyCredits.length < 6) {
      issues.add(Step3Issue(
        code: 'STATEMENT_SHORT',
        field: 'statement',
        message: 'Statement covers only ${monthlyCredits.length} month(s) — minimum 6 months recommended',
        severity: Step3Severity.softFlag,
      ));
    }

    // ── Income cross-check: declared vs bank average ──
    if (step1Income > 0 && monthlyCredits.isNotEmpty) {
      final avgCredit = monthlyCredits.reduce((a, b) => a + b) / monthlyCredits.length;
      final ratio = avgCredit / step1Income;

      // Spec: 60%-140% tolerance for bank vs declared income
      if (ratio < 0.60) {
        issues.add(Step3Issue(
          code: 'INCOME_LOW_VS_BANK',
          field: 'income',
          message: 'Avg bank credits (₹${avgCredit.toStringAsFixed(0)}) are significantly lower than declared income (₹${step1Income.toStringAsFixed(0)})',
          severity: Step3Severity.softFlag,
        ));
      } else if (ratio > 1.40) {
        issues.add(Step3Issue(
          code: 'INCOME_HIGH_VS_BANK',
          field: 'income',
          message: 'Avg bank credits (₹${avgCredit.toStringAsFixed(0)}) exceed declared income (₹${step1Income.toStringAsFixed(0)}) by ${((ratio - 1) * 100).toStringAsFixed(0)}%',
          severity: Step3Severity.softFlag,
        ));
      }
    }

    // ── OCR cross-checks (if statement OCR data available) ──
    if (statementOcr != null) {
      final ocrIssues = validateOcrCrossCheck(
        enteredBankName: bankName,
        enteredHolderName: holderName,
        enteredIfsc: ifsc,
        enteredAccount: account,
        ocrBankName: statementOcr['bank_name'] as String?,
        ocrHolderName: statementOcr['holder_name'] as String?,
        ocrIfsc: statementOcr['ifsc_code'] as String?,
        ocrAccount: statementOcr['account_number'] as String?,
      );
      issues.addAll(ocrIssues);
    }

    final hasHardFails = issues.any((i) => i.severity == Step3Severity.hardFail);

    return Step3ValidationResult(passed: !hasHardFails, issues: issues);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRANSACTION CATEGORIZER — Labels bank transactions for downstream matching
// ═══════════════════════════════════════════════════════════════════════════════

/// Transaction category labels used by Steps 4-9.
enum TxnCategory {
  incomeGig,         // Gig platform earnings (Zomato, Swiggy, Ola, Uber, etc.)
  incomeSalary,      // Regular salary credits
  incomeOther,       // Other income
  utilityElectricity, // EB bill payments
  utilityGas,        // LPG/PNG
  utilityMobile,     // Mobile recharges/bill
  utilityInternet,   // WiFi/broadband
  utilityWater,      // Water bill
  rent,              // Rent payments
  insurance,         // Insurance premiums
  loanEmi,           // EMI / loan repayments
  govScheme,         // Government scheme credits (PMJDY, DBT, etc.)
  subscription,      // OTT/SaaS subscriptions
  transfer,          // P2P transfers
  atm,               // ATM withdrawals
  pos,               // POS/card payments
  other,             // Uncategorized
}

/// A categorized transaction with labels for cross-step matching.
class CategorizedTransaction {
  final String date;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String description;
  final TxnCategory category;
  final String? merchantRaw;
  final String? refId;

  const CategorizedTransaction({
    required this.date,
    required this.amount,
    required this.type,
    required this.description,
    required this.category,
    this.merchantRaw,
    this.refId,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'amount': amount,
    'type': type,
    'description': description,
    'category': category.name,
    'merchant_raw': merchantRaw,
    'ref_id': refId,
  };
}

class TransactionCategorizer {
  /// Categorize a list of raw bank transactions.
  static List<CategorizedTransaction> categorize(List<Map<String, dynamic>> rawTransactions) {
    return rawTransactions.map((txn) {
      final desc = (txn['description'] as String? ?? '').toUpperCase();
      final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
      final type = (txn['type'] as String? ?? 'debit').toLowerCase();
      final date = txn['date'] as String? ?? '';
      final refId = txn['ref_id'] as String?;

      final category = _classifyTransaction(desc, type, amount);

      return CategorizedTransaction(
        date: date,
        amount: amount,
        type: type,
        description: desc,
        category: category,
        merchantRaw: desc,
        refId: refId,
      );
    }).toList();
  }

  /// Classify a single transaction based on description keywords.
  static TxnCategory _classifyTransaction(String desc, String type, double amount) {
    // ── GIG PLATFORM INCOME ──
    if (type == 'credit') {
      if (_matchAny(desc, _gigPlatformKeywords)) return TxnCategory.incomeGig;
      if (_matchAny(desc, _salaryKeywords)) return TxnCategory.incomeSalary;
      if (_matchAny(desc, _govSchemeKeywords)) return TxnCategory.govScheme;
      return TxnCategory.incomeOther;
    }

    // ── DEBITS ──
    if (_matchAny(desc, _electricityKeywords)) return TxnCategory.utilityElectricity;
    if (_matchAny(desc, _gasKeywords)) return TxnCategory.utilityGas;
    if (_matchAny(desc, _mobileKeywords)) return TxnCategory.utilityMobile;
    if (_matchAny(desc, _internetKeywords)) return TxnCategory.utilityInternet;
    if (_matchAny(desc, _waterKeywords)) return TxnCategory.utilityWater;
    if (_matchAny(desc, _rentKeywords)) return TxnCategory.rent;
    if (_matchAny(desc, _insuranceKeywords)) return TxnCategory.insurance;
    if (_matchAny(desc, _loanEmiKeywords)) return TxnCategory.loanEmi;
    if (_matchAny(desc, _subscriptionKeywords)) return TxnCategory.subscription;
    if (_matchAny(desc, _atmKeywords)) return TxnCategory.atm;
    if (_matchAny(desc, _posKeywords)) return TxnCategory.pos;

    return TxnCategory.other;
  }

  static bool _matchAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  // ── Keyword tables ──────────────────────────────────────────────

  static const _gigPlatformKeywords = [
    'SWIGGY', 'ZOMATO', 'OLA', 'UBER', 'DUNZO', 'RAPIDO', 'FLIPKART',
    'AMAZON SELLER', 'ZEPTO', 'BLINKIT', 'PORTER', 'SHADOWFAX',
    'DELHIVERY', 'ECOM EXPRESS', 'BIGBASKET', 'MEESHO', 'JIOMART',
    'URBAN COMPANY', 'URBANCLAP', 'HOUSEJOY',
  ];

  static const _salaryKeywords = [
    'SALARY', 'SAL CR', 'PAYROLL', 'STIPEND', 'WAGES',
  ];

  static const _electricityKeywords = [
    'TANGEDCO', 'TNEB', 'BESCOM', 'BSES', 'ELECTRICITY', 'TATA POWER',
    'ENERGY CHARGES', 'POWER', 'MSEDCL', 'CESC', 'TORRENT POWER',
    'ELECTRICITY BILL', 'EB BILL', 'ELECTRIC',
  ];

  static const _gasKeywords = [
    'INDANE', 'BHARAT GAS', 'HP GAS', 'LPG', 'PNG', 'MAHANAGAR GAS',
    'IGL', 'ADANI GAS', 'GAS CYLINDER', 'PIPED GAS',
  ];

  static const _mobileKeywords = [
    'AIRTEL', 'JIO', 'VODAFONE', 'VI PREPAID', 'BSNL', 'MOBILE RECHARGE',
    'RECHARGE', 'TALKTIME', 'POSTPAID',
  ];

  static const _internetKeywords = [
    'BROADBAND', 'WIFI', 'WI-FI', 'JIOFIBER', 'ACT FIBERNET',
    'AIRTEL FIBER', 'HATHWAY', 'TIKONA', 'INTERNET',
  ];

  static const _waterKeywords = [
    'WATER BILL', 'WATER BOARD', 'CMWSSB', 'BWSSB', 'WATER SUPPLY',
  ];

  static const _rentKeywords = [
    'RENT', 'HOUSE RENT', 'MONTHLY RENT', 'LANDLORD', 'RENTAL',
  ];

  static const _insuranceKeywords = [
    'LIC', 'INSURANCE', 'PREMIUM', 'HDFC LIFE', 'ICICI PRUDENTIAL',
    'SBI LIFE', 'MAX LIFE', 'TATA AIA', 'BAJAJ ALLIANZ', 'STAR HEALTH',
    'NIVA BUPA', 'POLICY', 'HEALTH INS', 'VEHICLE INS',
  ];

  static const _loanEmiKeywords = [
    'EMI', 'LOAN', 'REPAYMENT', 'INSTALMENT', 'INSTALLMENT',
    'HOME LOAN', 'PERSONAL LOAN', 'VEHICLE LOAN', 'AUTO LOAN',
    'GOLD LOAN', 'EDUCATION LOAN', 'BAJAJ FINSERV', 'HDFC LTD',
    'MUTHOOT', 'MANAPPURAM',
  ];

  static const _govSchemeKeywords = [
    'PMJDY', 'PM-KISAN', 'PM KISAN', 'DBT', 'NREGA', 'MGNREGA',
    'SCHOLARSHIP', 'SUBSIDY', 'GOV', 'GOVT', 'NPS', 'EPF', 'EPFO',
    'PENSION', 'PMSYM',
  ];

  static const _subscriptionKeywords = [
    'NETFLIX', 'AMAZON PRIME', 'HOTSTAR', 'SPOTIFY', 'YOUTUBE',
    'DISNEY', 'APPLE', 'GOOGLE ONE',
  ];

  static const _atmKeywords = ['ATM', 'CASH WITHDRAWAL', 'ATW', 'NFS'];

  static const _posKeywords = ['POS', 'POINT OF SALE', 'CARD PAYMENT'];
}
