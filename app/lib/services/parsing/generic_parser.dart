import 'base_bank_parser.dart';
import 'parsed_transaction.dart';

/// Generic fallback parser for unknown bank formats.
/// Uses heuristic date + amount detection to extract transactions
/// from any bank statement that doesn't match Axis/Canara/Fincare.
class GenericParser extends BaseBankParser {
  @override
  String get bankName => 'Unknown Bank';

  @override
  BankParseResult parse(String rawText) {
    final lines = rawText.split('\n');
    final transactions = <ParsedTransaction>[];

    String accountNumber = '';
    String ifscCode = '';
    String holderName = '';

    // Try to extract IFSC
    final ifscMatch = RegExp(r'IFSC\s*(?:Code)?\s*[:\s]*([A-Z]{4}\d{7})', caseSensitive: false).firstMatch(rawText);
    if (ifscMatch != null) ifscCode = ifscMatch.group(1)!;

    // Try to extract account number
    final accMatch = RegExp(r'(?:Account|A/C)\s*(?:No\.?|Number)\s*[:\s]*(\d{9,18})', caseSensitive: false).firstMatch(rawText);
    if (accMatch != null) accountNumber = accMatch.group(1)!;

    // Date patterns: DD/MM/YYYY, DD-MM-YYYY, DD Mon YYYY
    final datePatterns = [
      RegExp(r'^(\d{2}[/-]\d{2}[/-]\d{4})'),        // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'^(\d{2}\s+\w{3}\s+\d{4})'),           // DD Mon YYYY
      RegExp(r'^(\d{4}[/-]\d{2}[/-]\d{2})'),          // YYYY-MM-DD
    ];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.length < 15) continue;

      String? dateStr;
      int dateEnd = 0;

      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(trimmed);
        if (match != null) {
          dateStr = match.group(1)!;
          dateEnd = match.end;
          break;
        }
      }

      if (dateStr == null) continue;

      final rest = trimmed.substring(dateEnd).trim();

      // Find all amounts in the rest of the line
      final amounts = <_AmountMatch>[];
      for (final m in RegExp(r'([\d,]+\.\d{2})').allMatches(rest)) {
        amounts.add(_AmountMatch(
          value: parseAmount(m.group(1)),
          position: m.start,
          raw: m.group(1)!,
        ));
      }

      if (amounts.isEmpty) continue;

      // Description is text before the first amount
      final desc = rest.substring(0, amounts.first.position).trim();
      if (desc.isEmpty) continue;

      // Determine credit vs debit
      final isCredit = _isLikelyCredit(desc);
      final balance = amounts.length >= 2 ? amounts.last.value : 0.0;
      final txnAmount = amounts.length >= 2
          ? amounts[amounts.length - 2].value
          : amounts.first.value;

      if (txnAmount > 0) {
        transactions.add(ParsedTransaction(
          date: normalizeDate(dateStr),
          description: desc,
          amount: txnAmount,
          type: isCredit ? 'credit' : 'debit',
          balance: balance,
          mode: detectMode(desc),
          transactionId: _extractId(desc),
          sender: isCredit ? extractUpiParty(desc) : '',
          receiver: !isCredit ? extractUpiParty(desc) : '',
        ));
      }
    }

    final creditMap = aggregateMonthly(transactions, 'credit');
    final debitMap = aggregateMonthly(transactions, 'debit');

    return BankParseResult(
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      holderName: holderName,
      statementPeriod: '',
      transactions: transactions,
      monthlyCredits: monthlyTotals(creditMap),
      monthlyDebits: monthlyTotals(debitMap),
    );
  }

  bool _isLikelyCredit(String desc) {
    final d = desc.toUpperCase();
    return d.contains('/CR') || d.contains('CR-') || d.contains('DEPOSIT') ||
        d.contains('SALARY') || d.contains('INTEREST') || d.contains('REFUND') ||
        d.contains('CREDITED') || d.contains('INT.PD');
  }

  String _extractId(String desc) {
    final match = RegExp(r'(\d{12,18})').firstMatch(desc);
    return match?.group(1) ?? '';
  }
}

class _AmountMatch {
  final double value;
  final int position;
  final String raw;
  _AmountMatch({required this.value, required this.position, required this.raw});
}
