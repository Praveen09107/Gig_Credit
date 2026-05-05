import 'parsed_transaction.dart';

/// Base class for all bank-specific parsers.
/// Each parser implements [parse] to extract transactions from raw OCR text.
abstract class BaseBankParser {
  /// Human-readable bank name
  String get bankName;

  /// Parse raw text into structured transactions
  BankParseResult parse(String rawText);

  // ── Shared Utilities ─────────────────────────────────────────────────────

  /// Detect transaction mode from description text
  String detectMode(String desc) {
    final d = desc.toUpperCase();
    if (d.contains('UPI'))  return 'UPI';
    if (d.contains('IMPS')) return 'IMPS';
    if (d.contains('NEFT')) return 'NEFT';
    if (d.contains('RTGS')) return 'RTGS';
    if (d.contains('ATM'))  return 'ATM';
    if (d.contains('ACH'))  return 'ACH';
    if (d.contains('ECS'))  return 'ECS';
    if (d.contains('CASH')) return 'CASH';
    return 'OTHER';
  }

  /// Extract sender/receiver from UPI descriptions
  /// e.g. "UPI/P2A/317430171945/AJAY JOSH/India" → sender = "AJAY JOSH"
  String extractUpiParty(String desc) {
    final parts = desc.split('/');
    if (parts.length >= 4) {
      return parts[3].trim();
    }
    return '';
  }

  /// Parse amount string safely — handles "1,23,456.78" and "1234.56"
  double parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0.0;
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Parse date in DD-MM-YYYY or DD/MM/YYYY to YYYY-MM-DD
  String normalizeDate(String raw) {
    final cleaned = raw.trim().replaceAll('/', '-');
    final parts = cleaned.split('-');
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      var year = parts[2];
      if (year.length == 2) year = '20$year';
      return '$year-$month-$day';
    }
    return raw; // Fallback
  }

  /// Aggregate transactions into monthly credit/debit totals
  /// Returns a map of 'YYYY-MM' → total
  Map<String, double> aggregateMonthly(List<ParsedTransaction> txns, String type) {
    final map = <String, double>{};
    for (final t in txns) {
      if (t.type != type) continue;
      final ym = t.date.length >= 7 ? t.date.substring(0, 7) : 'unknown';
      map[ym] = (map[ym] ?? 0) + t.amount;
    }
    return map;
  }

  /// Convert monthly aggregates to sorted list of totals
  List<double> monthlyTotals(Map<String, double> map) {
    final keys = map.keys.toList()..sort();
    return keys.map((k) => map[k]!).toList();
  }
}
