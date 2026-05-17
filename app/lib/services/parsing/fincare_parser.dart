import 'base_bank_parser.dart';
import 'parsed_transaction.dart';

/// Parser for Fincare Small Finance Bank (FSFB) statements.
/// Format: Date | Narration | Withdrawal (Dr.) | Deposit (Cr.) | Balance
/// Narration is multiline — wraps to next line(s) without a date prefix.
/// IFSC prefix: FSFB
class FincareParser extends BaseBankParser {
  @override
  String get bankName => 'Fincare Small Finance Bank';

  @override
  BankParseResult parse(String rawText) {
    final lines = rawText.split('\n');
    final transactions = <ParsedTransaction>[];

    // Extract metadata
    String accountNumber = '';
    String ifscCode = '';
    String holderName = '';
    String statementPeriod = '';

    final accMatch = RegExp(r'ACCOUNT\s*NO\.?\s*[:\s]*(\d{10,18})', caseSensitive: false).firstMatch(rawText);
    if (accMatch != null) accountNumber = accMatch.group(1)!;

    final ifscMatch = RegExp(r'IFSC\s*CODE\s*[:\s]*(FSFB\d{7})', caseSensitive: false).firstMatch(rawText);
    if (ifscMatch != null) ifscCode = ifscMatch.group(1)!;

    final nameMatch = RegExp(r'NAME\s*[:\s]*(MR\.?\s*\w[\w\s]+)', caseSensitive: false).firstMatch(rawText);
    if (nameMatch != null) {
      holderName = nameMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final periodMatch = RegExp(r'FROM\s*[:\s]*([\d/]+)\s*TO\s*([\d/]+)', caseSensitive: false).firstMatch(rawText);
    if (periodMatch != null) statementPeriod = '${periodMatch.group(1)} to ${periodMatch.group(2)}';

    // Fincare format: DD/MM/YYYY Narration  Amount1  Amount2  Balance
    // The narration often spans multiple lines
    final dateRegex = RegExp(r'^(\d{2}/\d{2}/\d{4})\s+(.*)$');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.contains('Opening Balance') && !RegExp(r'^\d').hasMatch(line)) continue;

      final dateMatch = dateRegex.firstMatch(line);
      if (dateMatch == null) continue;

      final date = dateMatch.group(1)!;
      String rest = dateMatch.group(2)!;

      // Collect continuation lines (no date prefix)
      while (i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        if (next.isEmpty || dateRegex.hasMatch(next) ||
            next.contains('STATEMENT') || next.contains('All values')) {
          break;
        }
        rest += ' $next';
        i++;
      }

      // Extract amounts from the end of the combined text
      // Pattern: narration ... withdrawal deposit balance
      // Amounts are right-aligned numbers
      final amountMatches = RegExp(r'([\d,]+\.\d{2})').allMatches(rest).toList();

      if (amountMatches.length >= 2) {
        final bal = parseAmount(amountMatches.last.group(1));
        final descEnd = amountMatches.first.start;
        final desc = rest.substring(0, descEnd).trim();

        // Fincare uses separate Withdrawal and Deposit columns
        // Check narration keywords to determine type
        double withdrawal = 0;
        double deposit = 0;

        if (amountMatches.length >= 3) {
          // Three amounts: withdrawal, deposit, balance
          withdrawal = parseAmount(amountMatches[amountMatches.length - 3].group(1));
          deposit = parseAmount(amountMatches[amountMatches.length - 2].group(1));
        } else {
          // Two amounts: one of (withdrawal|deposit) + balance
          final amt = parseAmount(amountMatches[amountMatches.length - 2].group(1));
          if (_isLikelyDeposit(desc)) {
            deposit = amt;
          } else {
            withdrawal = amt;
          }
        }

        if (withdrawal > 0 || deposit > 0) {
          transactions.add(ParsedTransaction(
            date: normalizeDate(date),
            description: desc,
            amount: withdrawal > 0 ? withdrawal : deposit,
            type: deposit > 0 ? 'credit' : 'debit',
            balance: bal,
            mode: detectMode(desc),
            transactionId: _extractRrn(desc),
            sender: deposit > 0 ? _extractParty(desc) : '',
            receiver: withdrawal > 0 ? _extractParty(desc) : '',
          ));
        }
      }
    }

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

  bool _isLikelyDeposit(String desc) {
    final d = desc.toUpperCase();
    return d.contains('DEPOSIT') || d.contains('UPI CR') || d.contains('CR-RRN') ||
        d.contains('SALARY') || d.contains('NEFT CR') || d.contains('IMPS CR');
  }

  String _extractRrn(String desc) {
    final match = RegExp(r'RRN[:\s]*(\d{12,})').firstMatch(desc);
    return match?.group(1) ?? '';
  }

  String _extractParty(String desc) {
    // Fincare narration: "...From A/C:22100011629822...MrUsman Khan..."
    // or "...To A/C:19100012744648..."
    final nameMatch = RegExp(r'(?:Mr|Mrs|Ms)\.?\s*(\w[\w\s]+?)(?:-Rem:|$)', caseSensitive: false).firstMatch(desc);
    if (nameMatch != null) return nameMatch.group(1)!.trim();

    // Try UPI party extraction
    final parts = desc.split('/');
    if (parts.length >= 4) return parts[3].trim();
    return '';
  }
}
