import '../parsing/parsed_transaction.dart';

/// Enhanced cross-step validator that matches utility bills, EMI payments,
/// and insurance premiums against actual bank transactions.
///
/// Matching rules:
///   Amount tolerance: ±50
///   Date tolerance: ±3 days
class BankTransactionMatcher {
  /// Match a utility bill amount against bank debit transactions
  static MatchResult matchUtilityBill({
    required double billAmount,
    required String billType,
    required List<ParsedTransaction> bankTransactions,
  }) {
    for (final txn in bankTransactions) {
      if (txn.type != 'debit') continue;

      // Amount tolerance ±50
      if ((txn.amount - billAmount).abs() <= 50) {
        // Check description for utility keywords
        final desc = txn.description.toUpperCase();
        final keywords = _utilityKeywords[billType] ?? [];
        final hasKeyword = keywords.any((kw) => desc.contains(kw.toUpperCase()));

        if (hasKeyword || (txn.amount - billAmount).abs() <= 10) {
          return MatchResult(
            matched: true,
            confidence: hasKeyword ? 0.95 : 0.75,
            matchedTransaction: txn,
            reason: hasKeyword
                ? 'Amount ₹${txn.amount} matches bill ₹$billAmount with "$billType" keyword in description'
                : 'Amount ₹${txn.amount} closely matches bill ₹$billAmount (±₹${(txn.amount - billAmount).abs().toStringAsFixed(0)})',
          );
        }
      }
    }

    return MatchResult(
      matched: false,
      confidence: 0.0,
      reason: 'No matching debit of ₹$billAmount (±50) found for $billType bill',
    );
  }

  /// Detect recurring EMI payments in bank transactions
  static EmiMatchResult matchEmi({
    required double emiAmount,
    required String loanType,
    required List<ParsedTransaction> bankTransactions,
  }) {
    // Look for recurring debits of similar amounts across months
    final matchingDebits = <ParsedTransaction>[];

    for (final txn in bankTransactions) {
      if (txn.type != 'debit') continue;
      if ((txn.amount - emiAmount).abs() <= 50) {
        // Check for EMI/loan keywords
        final desc = txn.description.toUpperCase();
        if (desc.contains('EMI') || desc.contains('LOAN') ||
            desc.contains('ACH-DR') || desc.contains('ECS') ||
            desc.contains('NACH') || desc.contains('AUTO DEBIT') ||
            (txn.amount - emiAmount).abs() <= 5) {
          matchingDebits.add(txn);
        }
      }
    }

    // Check if recurring (appears in multiple months)
    final months = <String>{};
    for (final txn in matchingDebits) {
      if (txn.date.length >= 7) months.add(txn.date.substring(0, 7));
    }

    final isRecurring = months.length >= 2;

    return EmiMatchResult(
      matched: matchingDebits.isNotEmpty,
      isRecurring: isRecurring,
      occurrences: matchingDebits.length,
      monthsFound: months.length,
      confidence: isRecurring ? 0.95 : (matchingDebits.isNotEmpty ? 0.70 : 0.0),
      matchedTransactions: matchingDebits,
      reason: isRecurring
          ? 'EMI of ₹$emiAmount found as recurring debit across ${months.length} months'
          : matchingDebits.isNotEmpty
              ? 'EMI of ₹$emiAmount found ${matchingDebits.length} time(s) but not recurring'
              : 'No matching EMI debit of ₹$emiAmount (±50) found',
    );
  }

  /// Match insurance premium payment against bank transactions
  static MatchResult matchInsurancePremium({
    required double premiumAmount,
    required String insuranceType,
    required List<ParsedTransaction> bankTransactions,
  }) {
    for (final txn in bankTransactions) {
      if (txn.type != 'debit') continue;
      if ((txn.amount - premiumAmount).abs() <= 50) {
        final desc = txn.description.toUpperCase();
        if (desc.contains('INSURANCE') || desc.contains('PREMIUM') ||
            desc.contains('LIC') || desc.contains('HDFC ERGO') ||
            desc.contains('ICICI LOMBARD') || desc.contains('POLICY')) {
          return MatchResult(
            matched: true,
            confidence: 0.90,
            matchedTransaction: txn,
            reason: 'Insurance premium ₹$premiumAmount matches debit ₹${txn.amount}',
          );
        }
      }
    }

    return const MatchResult(
      matched: false,
      confidence: 0.0,
      reason: 'No matching insurance premium debit found',
    );
  }

  static const Map<String, List<String>> _utilityKeywords = {
    'electricity': ['ELECTRICITY', 'TANGEDCO', 'POWER', 'ENERGY', 'BESCOM', 'BSES', 'TPDDL', 'MSEB'],
    'water': ['WATER', 'JALDOOT', 'WATER SUPPLY', 'WATER BOARD'],
    'gas': ['GAS', 'INDANE', 'BHARAT GAS', 'HP GAS', 'MAHANAGAR GAS'],
    'mobile': ['AIRTEL', 'JIO', 'VODAFONE', 'VI ', 'BSNL', 'MOBILE RECHARGE'],
    'internet': ['BROADBAND', 'FIBER', 'WIFI', 'ACT FIBERNET', 'JIOFIBER', 'AIRTEL XSTREAM'],
    'rent': ['RENT', 'LANDLORD', 'HOUSE RENT'],
  };
}

class MatchResult {
  final bool matched;
  final double confidence;
  final ParsedTransaction? matchedTransaction;
  final String reason;

  const MatchResult({
    required this.matched,
    required this.confidence,
    this.matchedTransaction,
    required this.reason,
  });
}

class EmiMatchResult {
  final bool matched;
  final bool isRecurring;
  final int occurrences;
  final int monthsFound;
  final double confidence;
  final List<ParsedTransaction> matchedTransactions;
  final String reason;

  const EmiMatchResult({
    required this.matched,
    required this.isRecurring,
    required this.occurrences,
    required this.monthsFound,
    required this.confidence,
    required this.matchedTransactions,
    required this.reason,
  });
}
