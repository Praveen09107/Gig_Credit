import 'base_bank_parser.dart';
import 'parsed_transaction.dart';

/// Parser for Axis Bank statements.
/// Format: Tran Date | Chq No | Particulars | Debit | Credit | Balance | Init.Br
/// Multiline: narration wraps to next line without a date prefix.
class AxisParser extends BaseBankParser {
  @override
  String get bankName => 'Axis Bank';

  @override
  BankParseResult parse(String rawText) {
    final lines = rawText.split('\n');
    final transactions = <ParsedTransaction>[];

    // Extract metadata
    String accountNumber = '';
    String ifscCode = '';
    String holderName = '';
    String statementPeriod = '';

    final accMatch = RegExp(r'Account\s*No\s*[:\s]*(\d{10,18})', caseSensitive: false).firstMatch(rawText);
    if (accMatch != null) accountNumber = accMatch.group(1)!;

    final ifscMatch = RegExp(r'IFSC\s*Code\s*[:\s]*(UTIB\d{7})', caseSensitive: false).firstMatch(rawText);
    if (ifscMatch != null) ifscCode = ifscMatch.group(1)!;

    // Name is typically the first line
    if (lines.isNotEmpty) holderName = lines[0].trim();

    final periodMatch = RegExp(r'From\s*:\s*([\d\-/]+)\s*To\s*:\s*([\d\-/]+)', caseSensitive: false).firstMatch(rawText);
    if (periodMatch != null) statementPeriod = '${periodMatch.group(1)} to ${periodMatch.group(2)}';

    // Transaction parsing — Axis uses DD-MM-YYYY as line start
    final dateRegex = RegExp(r'^(\d{2}-\d{2}-\d{4})\s+(.*)$');
    String pendingNarration = '';
    String pendingDate = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.contains('OPENING BALANCE') || line.contains('Tran Date')) continue;

      final dateMatch = dateRegex.firstMatch(line);

      if (dateMatch != null) {
        // If we had a pending multiline narration from a previous date-line, finalize it
        // (handled below when we parse the amounts from the current date-line)

        final date = dateMatch.group(1)!;
        final rest = dateMatch.group(2)!;

        // Try to extract amounts from the rest of the line
        // Pattern: Particulars ... Debit Credit Balance InitBr
        // Amounts are at the end, separated by spaces
        final amountRegex = RegExp(r'([\d,]+\.\d{2})\s+([\d,]+\.\d{2})\s+\d+\s*$');
        final threeAmtMatch = amountRegex.firstMatch(rest);

        // Try two-amount pattern (debit or credit might be empty)
        final twoAmtRegex = RegExp(r'([\d,]+\.\d{2})\s+\d+\s*$');

        if (threeAmtMatch != null) {
          // Has both a transaction amount and a balance
          final amt1 = parseAmount(threeAmtMatch.group(1));
          final bal = parseAmount(threeAmtMatch.group(2));
          final desc = rest.substring(0, threeAmtMatch.start).trim();

          // Determine if credit or debit based on position in the original format
          // In Axis: columns are Particulars | Debit | Credit | Balance
          // If there are 3 numbers, we need context. Check if balance increased.
          // Simpler: look at the column positions from the raw text

          // Use a heuristic: look at the raw text for column alignment
          // For now, determine by checking description keywords
          final isCredit = _isLikelyCredit(desc, rest);

          transactions.add(ParsedTransaction(
            date: normalizeDate(date),
            description: desc,
            amount: amt1,
            type: isCredit ? 'credit' : 'debit',
            balance: bal,
            mode: detectMode(desc),
            transactionId: _extractTxnId(desc),
            sender: isCredit ? extractUpiParty(desc) : '',
            receiver: !isCredit ? extractUpiParty(desc) : '',
          ));
        } else {
          // Single amount + balance pattern
          final parts = rest.split(RegExp(r'\s{2,}'));
          if (parts.length >= 2) {
            // Try to find numeric values
            final nums = <double>[];
            String desc = '';
            for (final p in parts) {
              final v = parseAmount(p);
              if (v > 0) {
                nums.add(v);
              } else {
                desc += ' $p';
              }
            }
            desc = desc.trim();

            if (nums.length >= 2) {
              final amt = nums[0];
              final bal = nums.last;
              final isCredit = _isLikelyCredit(desc, rest);

              transactions.add(ParsedTransaction(
                date: normalizeDate(date),
                description: desc,
                amount: amt,
                type: isCredit ? 'credit' : 'debit',
                balance: bal,
                mode: detectMode(desc),
                transactionId: _extractTxnId(desc),
                sender: isCredit ? extractUpiParty(desc) : '',
                receiver: !isCredit ? extractUpiParty(desc) : '',
              ));
            } else if (nums.length == 1 && desc.isNotEmpty) {
              // Could be interest or single entry
              transactions.add(ParsedTransaction(
                date: normalizeDate(date),
                description: desc,
                amount: nums[0],
                type: _isLikelyCredit(desc, rest) ? 'credit' : 'debit',
                balance: 0,
                mode: detectMode(desc),
                transactionId: _extractTxnId(desc),
              ));
            }
          }
        }
      }
    }

    // Build monthly aggregates
    final creditMap = aggregateMonthly(transactions, 'credit');
    final debitMap = aggregateMonthly(transactions, 'debit');

    return BankParseResult(
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      holderName: holderName,
      statementPeriod: statementPeriod,
      transactions: transactions,
      monthlyCredits: monthlyTotals(creditMap),
      monthlyDebits: monthlyTotals(debitMap),
    );
  }

  bool _isLikelyCredit(String desc, String fullLine) {
    final d = desc.toUpperCase();
    // Credits: deposits, incoming UPI, interest, salary
    if (d.contains('INT.PD') || d.contains('INTEREST')) return true;
    if (d.contains('SALARY') || d.contains('CR')) return true;
    if (d.contains('P2A') && !d.contains('DR')) return true;
    if (d.contains('TAB ')) return true; // Cash deposit at branch
    // Check column position — in Axis format, credit column is after debit
    // If the amount appears more to the right, it's likely credit
    return false;
  }

  String _extractTxnId(String desc) {
    final match = RegExp(r'(\d{12,18})').firstMatch(desc);
    return match?.group(1) ?? '';
  }
}
