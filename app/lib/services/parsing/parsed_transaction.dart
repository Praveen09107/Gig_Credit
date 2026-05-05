/// Structured transaction output from bank statement parsing.
/// All parsers MUST produce this format.
class ParsedTransaction {
  final String date;          // YYYY-MM-DD
  final String description;
  final double amount;
  final String type;          // 'credit' | 'debit'
  final double balance;
  final String transactionId;
  final String mode;          // UPI | IMPS | NEFT | ATM | ACH | OTHER
  final String sender;
  final String receiver;

  const ParsedTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.balance,
    this.transactionId = '',
    this.mode = 'OTHER',
    this.sender = '',
    this.receiver = '',
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'description': description,
    'amount': amount,
    'type': type,
    'balance': balance,
    'transactionId': transactionId,
    'mode': mode,
    'sender': sender,
    'receiver': receiver,
  };
}

/// Result of parsing a full bank statement.
class BankParseResult {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String holderName;
  final String statementPeriod;
  final List<ParsedTransaction> transactions;
  final List<double> monthlyCredits;
  final List<double> monthlyDebits;

  const BankParseResult({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.holderName,
    required this.statementPeriod,
    required this.transactions,
    required this.monthlyCredits,
    required this.monthlyDebits,
  });
}
