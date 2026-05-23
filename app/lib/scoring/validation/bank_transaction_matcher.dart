import 'dart:math';
import 'step3_validator.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BankTransactionMatcher — Cross-verification engine for Steps 4-9
///
/// Matches OCR-extracted bill/document data against the canonical bank
/// transaction table from Step 3. This is the core "proof of payment"
/// verification that makes GigCredit's scoring trustworthy.
///
/// Matching rules (from spec):
///   • Amount match:  ±5 INR or ±2% (whichever is larger)
///   • Date match:    ±3 days for utility, ±5 days for EMI, ±7 days for others
///   • Merchant match: keyword substring search in transaction description
/// ─────────────────────────────────────────────────────────────────────────────

/// Result of attempting to match a bill/payment against bank transactions
class TransactionMatchResult {
  final bool matched;
  final CategorizedTransaction? matchedTransaction;
  final double amountDifference;
  final int dateDifference; // in days
  final String matchType; // 'exact' | 'amount_date' | 'keyword' | 'none'
  final double confidence; // 0.0-1.0

  const TransactionMatchResult({
    required this.matched,
    this.matchedTransaction,
    this.amountDifference = 0.0,
    this.dateDifference = 0,
    this.matchType = 'none',
    this.confidence = 0.0,
  });
}

/// Aggregated result for a step's cross-verification
class StepVerificationResult {
  final bool allMatched;
  final int totalItems;
  final int matchedItems;
  final int softFlagItems;
  final int failedItems;
  final List<VerificationItem> items;
  final List<String> warnings;

  const StepVerificationResult({
    required this.allMatched,
    required this.totalItems,
    required this.matchedItems,
    required this.softFlagItems,
    required this.failedItems,
    required this.items,
    required this.warnings,
  });

  double get matchRatio => totalItems > 0 ? matchedItems / totalItems : 0.0;
}

class VerificationItem {
  final String label;
  final double declaredAmount;
  final String? declaredDate;
  final TransactionMatchResult matchResult;
  final String status; // 'matched' | 'soft_flag' | 'not_found'

  const VerificationItem({
    required this.label,
    required this.declaredAmount,
    this.declaredDate,
    required this.matchResult,
    required this.status,
  });
}

class BankTransactionMatcher {
  final List<CategorizedTransaction> _transactions;

  BankTransactionMatcher(this._transactions);

  /// Search for a matching transaction by amount, date, and keyword.
  ///
  /// [amount] — expected payment amount
  /// [date] — expected payment date (DD/MM/YYYY or DD-MM-YYYY)
  /// [keywords] — merchant/description keywords to search for
  /// [amountTolerance] — absolute amount tolerance in INR (default 5)
  /// [amountTolerancePct] — percentage tolerance (default 0.02 = 2%)
  /// [dateTolerance] — date tolerance in days (default 3)
  /// [category] — optional category filter
  TransactionMatchResult findMatch({
    required double amount,
    String? date,
    List<String> keywords = const [],
    double amountTolerance = 5.0,
    double amountTolerancePct = 0.02,
    int dateTolerance = 3,
    TxnCategory? category,
  }) {
    if (_transactions.isEmpty) {
      return const TransactionMatchResult(matched: false, matchType: 'none');
    }

    // Effective tolerance: max of absolute and percentage
    final effectiveTolerance = max(amountTolerance, amount * amountTolerancePct);

    CategorizedTransaction? bestMatch;
    double bestConfidence = 0.0;
    String bestMatchType = 'none';
    double bestAmountDiff = double.infinity;
    int bestDateDiff = 999;

    for (final txn in _transactions) {
      // Optional category filter
      if (category != null && txn.category != category) continue;

      double confidence = 0.0;
      bool amountMatched = false;
      bool dateMatched = false;
      bool keywordMatched = false;

      // ── Amount matching ──
      final amountDiff = (txn.amount - amount).abs();
      if (amountDiff <= effectiveTolerance) {
        amountMatched = true;
        // Higher confidence for closer matches
        confidence += 0.4 * (1.0 - (amountDiff / max(effectiveTolerance, 1.0)));
      }

      // ── Date matching ──
      int dateDiff = 999;
      if (date != null && date.isNotEmpty) {
        dateDiff = _daysDifference(date, txn.date);
        if (dateDiff <= dateTolerance) {
          dateMatched = true;
          confidence += 0.3 * (1.0 - (dateDiff / max(dateTolerance, 1)));
        }
      } else {
        // No date provided — don't penalize
        confidence += 0.15;
      }

      // ── Keyword matching ──
      if (keywords.isNotEmpty) {
        final desc = txn.description.toUpperCase();
        int keywordHits = 0;
        for (final kw in keywords) {
          if (desc.contains(kw.toUpperCase())) keywordHits++;
        }
        if (keywordHits > 0) {
          keywordMatched = true;
          confidence += 0.3 * (keywordHits / keywords.length);
        }
      } else {
        confidence += 0.1;
      }

      // ── Category bonus ──
      if (category != null && txn.category == category) {
        confidence += 0.1;
      }

      // Update best match
      if (confidence > bestConfidence) {
        bestConfidence = confidence;
        bestMatch = txn;
        bestAmountDiff = amountDiff;
        bestDateDiff = dateDiff;

        if (amountMatched && dateMatched && keywordMatched) {
          bestMatchType = 'exact';
        } else if (amountMatched && dateMatched) {
          bestMatchType = 'amount_date';
        } else if (amountMatched && keywordMatched) {
          bestMatchType = 'amount_keyword';
        } else if (keywordMatched) {
          bestMatchType = 'keyword';
        } else if (amountMatched) {
          bestMatchType = 'amount_only';
        }
      }
    }

    // Threshold: confidence ≥ 0.40 = match, 0.25-0.39 = soft, < 0.25 = no match
    final matched = bestConfidence >= 0.40;

    return TransactionMatchResult(
      matched: matched,
      matchedTransaction: bestMatch,
      amountDifference: bestAmountDiff,
      dateDifference: bestDateDiff,
      matchType: bestMatchType,
      confidence: bestConfidence.clamp(0.0, 1.0),
    );
  }

  /// Find all transactions matching a specific category.
  List<CategorizedTransaction> findByCategory(TxnCategory category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  /// Detect recurring debits (potential undisclosed EMIs).
  /// Looks for debits of similar amounts appearing monthly.
  List<DetectedRecurring> detectRecurringDebits({
    double amountTolerance = 50.0,
    int minOccurrences = 3,
  }) {
    final debits = _transactions.where((t) => t.type == 'debit').toList();
    final clusters = <double, List<CategorizedTransaction>>{};

    for (final txn in debits) {
      bool added = false;
      for (final key in clusters.keys.toList()) {
        if ((txn.amount - key).abs() <= amountTolerance) {
          clusters[key]!.add(txn);
          added = true;
          break;
        }
      }
      if (!added) {
        clusters[txn.amount] = [txn];
      }
    }

    return clusters.entries
        .where((e) => e.value.length >= minOccurrences)
        .map((e) => DetectedRecurring(
              avgAmount: e.key,
              occurrences: e.value.length,
              transactions: e.value,
              category: e.value.first.category,
            ))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP-SPECIFIC VERIFICATION METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Step 4: Verify utility bills against bank transactions.
  StepVerificationResult verifyUtilityBills(List<Map<String, dynamic>> bills) {
    final items = <VerificationItem>[];
    final warnings = <String>[];

    for (final bill in bills) {
      final billType = bill['type'] as String? ?? '';
      final amount = (bill['amount'] as num?)?.toDouble() ?? 0.0;
      final dueDate = bill['due_date'] as String?;

      // Map bill type to transaction category
      final category = _billTypeToCategory(billType);
      final keywords = _billTypeKeywords(billType);

      final result = findMatch(
        amount: amount,
        date: dueDate,
        keywords: keywords,
        amountTolerance: 5.0,
        amountTolerancePct: 0.02,
        dateTolerance: 3,
        category: category,
      );

      String status;
      if (result.matched) {
        status = 'matched';
      } else if (result.confidence >= 0.25) {
        status = 'soft_flag';
        warnings.add('$billType bill (₹${amount.toStringAsFixed(0)}) — partial match found (${(result.confidence * 100).toStringAsFixed(0)}% confidence)');
      } else {
        status = 'not_found';
        warnings.add('$billType bill (₹${amount.toStringAsFixed(0)}) — no matching bank transaction found');
      }

      items.add(VerificationItem(
        label: billType,
        declaredAmount: amount,
        declaredDate: dueDate,
        matchResult: result,
        status: status,
      ));

      // ═══════════════════════════════════════════════════════════════
      // GAP 5 FIX: Consecutive month check for utility bills
      // Spec says "6 consecutive months from current month" must have
      // matching bill payments in bank. If not, soft-flag it.
      // ═══════════════════════════════════════════════════════════════
      if (status == 'matched' || status == 'soft_flag') {
        final consecutiveResult = checkConsecutiveMonths(
          amount: amount,
          keywords: keywords,
          category: category,
          requiredMonths: 6,
        );
        if (!consecutiveResult['consecutive']) {
          warnings.add('$billType: only ${consecutiveResult['found_months']}/${consecutiveResult['required_months']} consecutive months found — expected 6 months of regular payments');
        }
      }
    }

    final matched = items.where((i) => i.status == 'matched').length;
    final softFlag = items.where((i) => i.status == 'soft_flag').length;
    final failed = items.where((i) => i.status == 'not_found').length;

    return StepVerificationResult(
      allMatched: failed == 0,
      totalItems: items.length,
      matchedItems: matched,
      softFlagItems: softFlag,
      failedItems: failed,
      items: items,
      warnings: warnings,
    );
  }

  /// GAP 5: Check if utility bill payments appear in N consecutive months.
  ///
  /// Scans bank transactions backwards from the current month and checks
  /// if matching payments (by amount ±10% or keywords) exist in each month.
  ///
  /// Returns: {'consecutive': bool, 'found_months': int, 'required_months': int}
  Map<String, dynamic> checkConsecutiveMonths({
    required double amount,
    required List<String> keywords,
    TxnCategory? category,
    int requiredMonths = 6,
  }) {
    final now = DateTime.now();
    int consecutiveFound = 0;

    // Scan backwards from current month
    for (int monthOffset = 0; monthOffset < requiredMonths; monthOffset++) {
      final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
      final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      bool foundInMonth = false;
      for (final txn in _transactions) {
        // Category filter
        if (category != null && txn.category != category) continue;

        // Parse transaction date
        final txnDate = _parseDate(txn.date);
        if (txnDate == null) continue;

        // Check if transaction is in the target month
        if (txnDate.year != targetMonth.year || txnDate.month != targetMonth.month) continue;

        // Amount match (±10% for monthly recurring)
        final amountDiff = (txn.amount - amount).abs();
        final tolerance = max(10.0, amount * 0.10);
        if (amountDiff <= tolerance) {
          foundInMonth = true;
          break;
        }

        // Keyword match fallback
        if (keywords.isNotEmpty) {
          final desc = txn.description.toUpperCase();
          for (final kw in keywords) {
            if (desc.contains(kw.toUpperCase())) {
              foundInMonth = true;
              break;
            }
          }
          if (foundInMonth) break;
        }
      }

      if (foundInMonth) {
        consecutiveFound++;
      } else {
        break; // Consecutive chain broken
      }
    }

    return {
      'consecutive': consecutiveFound >= requiredMonths,
      'found_months': consecutiveFound,
      'required_months': requiredMonths,
    };
  }

  /// Step 7: Verify insurance premiums against bank transactions.
  StepVerificationResult verifyInsurancePremiums(List<Map<String, dynamic>> premiums) {
    final items = <VerificationItem>[];
    final warnings = <String>[];

    for (final premium in premiums) {
      final type = premium['type'] as String? ?? '';
      final amount = (premium['amount'] as num?)?.toDouble() ?? 0.0;
      final date = premium['date'] as String?;

      final result = findMatch(
        amount: amount,
        date: date,
        keywords: _insuranceKeywords(type),
        amountTolerance: 10.0,
        amountTolerancePct: 0.05,
        dateTolerance: 7,
        category: TxnCategory.insurance,
      );

      String status;
      if (result.matched) {
        status = 'matched';
      } else if (result.confidence >= 0.25) {
        status = 'soft_flag';
        warnings.add('$type insurance premium (₹${amount.toStringAsFixed(0)}) — partial match');
      } else {
        status = 'not_found';
        warnings.add('$type insurance premium (₹${amount.toStringAsFixed(0)}) — no matching transaction');
      }

      items.add(VerificationItem(
        label: '$type insurance',
        declaredAmount: amount,
        declaredDate: date,
        matchResult: result,
        status: status,
      ));
    }

    final matched = items.where((i) => i.status == 'matched').length;
    final softFlag = items.where((i) => i.status == 'soft_flag').length;
    final failed = items.where((i) => i.status == 'not_found').length;

    return StepVerificationResult(
      allMatched: failed == 0,
      totalItems: items.length,
      matchedItems: matched,
      softFlagItems: softFlag,
      failedItems: failed,
      items: items,
      warnings: warnings,
    );
  }

  /// Step 8: Verify ITR declared income against bank average.
  Map<String, dynamic> verifyItrIncome({
    required double itrAnnualIncome,
    required double bankAvgMonthlyCredit,
  }) {
    final itrMonthly = itrAnnualIncome / 12;
    final ratio = bankAvgMonthlyCredit > 0 ? itrMonthly / bankAvgMonthlyCredit : 0.0;

    // Spec: 60%-140% tolerance
    final withinRange = ratio >= 0.60 && ratio <= 1.40;

    return {
      'itr_monthly': itrMonthly,
      'bank_monthly': bankAvgMonthlyCredit,
      'ratio': ratio,
      'within_range': withinRange,
      'deviation_pct': ((ratio - 1.0) * 100).abs(),
      'status': withinRange ? 'matched' : (ratio < 0.60 ? 'itr_low' : 'itr_high'),
    };
  }

  /// Step 9: Verify EMI payments against bank transactions + detect undisclosed.
  StepVerificationResult verifyEmiPayments(List<Map<String, dynamic>> declaredEmis) {
    final items = <VerificationItem>[];
    final warnings = <String>[];

    for (final emi in declaredEmis) {
      final type = emi['type'] as String? ?? '';
      final amount = (emi['amount'] as num?)?.toDouble() ?? 0.0;
      final date = emi['date'] as String?;

      final result = findMatch(
        amount: amount,
        date: date,
        keywords: _emiKeywords(type),
        amountTolerance: 10.0,
        amountTolerancePct: 0.05,
        dateTolerance: 5,
        category: TxnCategory.loanEmi,
      );

      String status;
      if (result.matched) {
        status = 'matched';
      } else if (result.confidence >= 0.25) {
        status = 'soft_flag';
        warnings.add('$type EMI (₹${amount.toStringAsFixed(0)}) — partial match');
      } else {
        status = 'not_found';
        warnings.add('$type EMI (₹${amount.toStringAsFixed(0)}) — no matching transaction found');
      }

      items.add(VerificationItem(
        label: '$type EMI',
        declaredAmount: amount,
        declaredDate: date,
        matchResult: result,
        status: status,
      ));
    }

    // ── Auto-detect undisclosed EMIs ──
    final recurring = detectRecurringDebits(amountTolerance: 100, minOccurrences: 3);
    for (final r in recurring) {
      if (r.category == TxnCategory.loanEmi) {
        // Check if this recurring debit is already declared
        final isDeclared = declaredEmis.any((emi) {
          final emiAmt = (emi['amount'] as num?)?.toDouble() ?? 0;
          return (emiAmt - r.avgAmount).abs() < 200;
        });

        if (!isDeclared) {
          warnings.add('⚠️ Undisclosed recurring debit detected: ₹${r.avgAmount.toStringAsFixed(0)}/month (${r.occurrences} occurrences) — possible undeclared EMI');
        }
      }
    }

    final matched = items.where((i) => i.status == 'matched').length;
    final softFlag = items.where((i) => i.status == 'soft_flag').length;
    final failed = items.where((i) => i.status == 'not_found').length;

    return StepVerificationResult(
      allMatched: failed == 0,
      totalItems: items.length,
      matchedItems: matched,
      softFlagItems: softFlag,
      failedItems: failed,
      items: items,
      warnings: warnings,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  static TxnCategory? _billTypeToCategory(String billType) {
    switch (billType.toLowerCase()) {
      case 'electricity': case 'eb': return TxnCategory.utilityElectricity;
      case 'gas': case 'lpg': return TxnCategory.utilityGas;
      case 'mobile': return TxnCategory.utilityMobile;
      case 'internet': case 'wifi': case 'broadband': return TxnCategory.utilityInternet;
      case 'water': return TxnCategory.utilityWater;
      case 'rent': return TxnCategory.rent;
      default: return null;
    }
  }

  static List<String> _billTypeKeywords(String billType) {
    switch (billType.toLowerCase()) {
      case 'electricity': case 'eb':
        return ['TANGEDCO', 'TNEB', 'BESCOM', 'ELECTRICITY', 'TATA POWER', 'EB BILL', 'ENERGY'];
      case 'gas': case 'lpg':
        return ['INDANE', 'BHARAT GAS', 'HP GAS', 'LPG', 'GAS'];
      case 'mobile':
        return ['AIRTEL', 'JIO', 'VODAFONE', 'BSNL', 'RECHARGE', 'MOBILE'];
      case 'internet': case 'wifi': case 'broadband':
        return ['BROADBAND', 'WIFI', 'JIOFIBER', 'ACT', 'AIRTEL FIBER', 'INTERNET'];
      case 'water':
        return ['WATER', 'CMWSSB', 'BWSSB'];
      case 'rent':
        return ['RENT', 'LANDLORD', 'RENTAL'];
      default:
        return [billType.toUpperCase()];
    }
  }

  static List<String> _insuranceKeywords(String type) {
    switch (type.toLowerCase()) {
      case 'health':
        return ['HEALTH', 'STAR HEALTH', 'NIVA BUPA', 'MEDICAL', 'HEALTH INS'];
      case 'life':
        return ['LIC', 'LIFE', 'SBI LIFE', 'HDFC LIFE', 'MAX LIFE', 'TATA AIA'];
      case 'vehicle':
        return ['VEHICLE', 'MOTOR', 'BAJAJ ALLIANZ', 'ICICI LOMBARD', 'VEHICLE INS'];
      default:
        return ['INSURANCE', 'PREMIUM', 'POLICY'];
    }
  }

  static List<String> _emiKeywords(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return ['HOME LOAN', 'HOUSING', 'MORTGAGE', 'HDFC LTD', 'SBI HOME'];
      case 'vehicle': case 'auto':
        return ['VEHICLE LOAN', 'AUTO LOAN', 'CAR LOAN', 'BIKE LOAN'];
      case 'personal':
        return ['PERSONAL LOAN', 'BAJAJ FINSERV', 'FLEXI LOAN'];
      case 'gold':
        return ['GOLD LOAN', 'MUTHOOT', 'MANAPPURAM'];
      case 'education':
        return ['EDUCATION LOAN', 'STUDENT LOAN', 'VIDYA LAKSHMI'];
      default:
        return ['EMI', 'LOAN', 'INSTALMENT', 'REPAYMENT'];
    }
  }

  /// Calculate days difference between two date strings.
  static int _daysDifference(String date1, String date2) {
    final d1 = _parseDate(date1);
    final d2 = _parseDate(date2);
    if (d1 == null || d2 == null) return 999; // Unknown
    return d1.difference(d2).inDays.abs();
  }

  /// Parse date from common Indian formats.
  static DateTime? _parseDate(String date) {
    final clean = date.trim();

    // DD/MM/YYYY
    final slashMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$').firstMatch(clean);
    if (slashMatch != null) {
      try {
        int year = int.parse(slashMatch.group(3)!);
        if (year < 100) year += 2000;
        return DateTime(year, int.parse(slashMatch.group(2)!), int.parse(slashMatch.group(1)!));
      } catch (_) {}
    }

    // DD-MM-YYYY or YYYY-MM-DD
    final dashMatch = RegExp(r'^(\d{1,4})-(\d{1,2})-(\d{1,4})$').firstMatch(clean);
    if (dashMatch != null) {
      try {
        final first = int.parse(dashMatch.group(1)!);
        final second = int.parse(dashMatch.group(2)!);
        final third = int.parse(dashMatch.group(3)!);
        if (first > 31) {
          return DateTime(first, second, third); // YYYY-MM-DD
        } else {
          return DateTime(third, second, first); // DD-MM-YYYY
        }
      } catch (_) {}
    }

    return null;
  }
}

/// A detected recurring debit pattern (potential undisclosed EMI).
class DetectedRecurring {
  final double avgAmount;
  final int occurrences;
  final List<CategorizedTransaction> transactions;
  final TxnCategory category;

  const DetectedRecurring({
    required this.avgAmount,
    required this.occurrences,
    required this.transactions,
    required this.category,
  });
}
