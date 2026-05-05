import 'base_bank_parser.dart';
import 'parsed_transaction.dart';

/// Parser for Canara Bank statements.
/// Format: Txn Date | Value Date | Cheque No | Description | Branch Code | Debit | Credit | Balance
/// Amount format uses Indian commas: "60,311.52"
class CanaraParser extends BaseBankParser {
  @override
  String get bankName => 'Canara Bank';

  @override
  BankParseResult parse(String rawText) {
    final lines = rawText.split('\n');
    final transactions = <ParsedTransaction>[];

    // Extract metadata
    String accountNumber = '';
    String ifscCode = '';
    String holderName = '';
    String statementPeriod = '';

    final accMatch = RegExp(r'Account\s*Number\s*[:\s]*(\d{10,16})', caseSensitive: false).firstMatch(rawText);
    if (accMatch != null) accountNumber = accMatch.group(1)!;

    final ifscMatch = RegExp(r'IFSC\s*Code\s*[:\s]*(CNRB\d{7})', caseSensitive: false).firstMatch(rawText);
    if (ifscMatch != null) ifscCode = ifscMatch.group(1)!;

    // Name from "Account Holders' Name" line
    final nameMatch = RegExp(r"Account\s*Holders['']?\s*Name\s+(\w[\w\s]+)", caseSensitive: false).firstMatch(rawText);
    if (nameMatch != null) {
      holderName = nameMatch.group(1)!.trim();
    } else if (lines.length > 1) {
      holderName = lines[1].trim(); // Fallback: second line
    }

    final periodMatch = RegExp(r'From\s+(\d{1,2}\s+\w+\s+\d{4})\s+To\s+(\d{1,2}\s+\w+\s+\d{4})', caseSensitive: false).firstMatch(rawText);
    if (periodMatch != null) statementPeriod = '${periodMatch.group(1)} to ${periodMatch.group(2)}';

    // Canara format: "DD-MM-YYYY HH:MM:SS  DD Mon YYYY  ChequeNo  Description  BranchCode  Debit  Credit  Balance"
    // The date-time pattern is very distinctive
    final txnRegex = RegExp(
      r'(\d{2}-\d{2}-\d{4})\s+\d{2}:\d{2}:\d{2}\s+(\d{1,2}\s+\w{3}\s+\d{4})\s+(\d+)\s+(.*?)\s+(\d{4})\s+([\d,]*\.?\d*)\s+([\d,]*\.?\d*)\s*$',
    );

    // Simpler line-by-line approach
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Try to match Canara format
      final match = txnRegex.firstMatch(trimmed);
      if (match != null) {
        final date = match.group(1)!;
        final chequeNo = match.group(3) ?? '';
        final desc = match.group(4)?.trim() ?? '';
        final debitStr = match.group(6) ?? '';
        final creditStr = match.group(7) ?? '';

        final debit = parseAmount(debitStr);
        final credit = parseAmount(creditStr);

        if (debit > 0 || credit > 0) {
          transactions.add(ParsedTransaction(
            date: normalizeDate(date),
            description: desc,
            amount: debit > 0 ? debit : credit,
            type: debit > 0 ? 'debit' : 'credit',
            balance: 0, // Balance parsing needs trailing number
            transactionId: chequeNo,
            mode: detectMode(desc),
            sender: credit > 0 ? extractUpiParty(desc) : '',
            receiver: debit > 0 ? extractUpiParty(desc) : '',
          ));
        }
        continue;
      }

      // Alternative: simpler pattern for Canara — date at start, amounts at end
      final simpleDateMatch = RegExp(r'^(\d{2}-\d{2}-\d{4})').firstMatch(trimmed);
      if (simpleDateMatch != null) {
        final date = simpleDateMatch.group(1)!;

        // Find amounts (numbers with commas and decimals) at the end
        final amounts = RegExp(r'([\d,]+\.\d{2})').allMatches(trimmed).toList();
        if (amounts.length >= 2) {
          // Last number is balance, second-to-last is the transaction amount
          final balStr = amounts.last.group(1)!;
          final amtStr = amounts[amounts.length - 2].group(1)!;
          final bal = parseAmount(balStr);
          final amt = parseAmount(amtStr);

          // Description is between the date and the first amount
          final descEnd = amounts.first.start;
          final desc = trimmed.substring(simpleDateMatch.end, descEnd).trim();

          // Determine type: if balance goes up vs previous, it's credit
          // Heuristic: check for UPI/CR or UPI/DR in description
          final isCredit = desc.toUpperCase().contains('/CR/') ||
              desc.toUpperCase().contains('CR-') ||
              desc.toUpperCase().contains('DEPOSIT') ||
              desc.toUpperCase().contains('SALARY');

          if (amt > 0) {
            transactions.add(ParsedTransaction(
              date: normalizeDate(date),
              description: desc,
              amount: amt,
              type: isCredit ? 'credit' : 'debit',
              balance: bal,
              mode: detectMode(desc),
              transactionId: '',
              sender: isCredit ? extractUpiParty(desc) : '',
              receiver: !isCredit ? extractUpiParty(desc) : '',
            ));
          }
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
}
