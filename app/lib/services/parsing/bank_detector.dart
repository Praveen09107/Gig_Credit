import 'base_bank_parser.dart';
import 'axis_parser.dart';
import 'canara_parser.dart';
import 'fincare_parser.dart';
import 'generic_parser.dart';
import 'parsed_transaction.dart';

/// Detects the bank from raw OCR text and routes to the correct parser.
///
/// Detection uses IFSC prefix and keyword matching:
///   UTIB → Axis Bank
///   CNRB → Canara Bank
///   FSFB → Fincare Small Finance Bank
///   else → Generic fallback parser
class BankDetector {
  /// Bank detection keywords mapped to IFSC prefixes
  static const Map<String, String> _ifscPrefixes = {
    'UTIB': 'AXIS',
    'CNRB': 'CANARA',
    'FSFB': 'FINCARE',
  };

  static const Map<String, List<String>> _keywords = {
    'AXIS': ['axis bank', 'axis account', 'utib'],
    'CANARA': ['canara bank', 'canara', 'cnrb'],
    'FINCARE': ['fincare', 'fsfb', 'fincare small finance'],
  };

  /// Detect bank type from raw text. Returns bank identifier string.
  static String detect(String rawText) {
    final upper = rawText.toUpperCase();

    // 1. Try IFSC prefix (most reliable)
    final ifscMatch = RegExp(r'IFSC\s*(?:Code)?\s*[:\s]*([A-Z]{4})\d{7}', caseSensitive: false).firstMatch(rawText);
    if (ifscMatch != null) {
      final prefix = ifscMatch.group(1)!.toUpperCase();
      if (_ifscPrefixes.containsKey(prefix)) {
        return _ifscPrefixes[prefix]!;
      }
    }

    // 2. Try keyword matching
    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (upper.contains(kw.toUpperCase())) {
          return entry.key;
        }
      }
    }

    return 'GENERIC';
  }

  /// Get the correct parser for detected bank type
  static BaseBankParser getParser(String bankType) {
    switch (bankType) {
      case 'AXIS':    return AxisParser();
      case 'CANARA':  return CanaraParser();
      case 'FINCARE': return FincareParser();
      default:        return GenericParser();
    }
  }

  /// Full pipeline: detect bank → route to parser → return structured result
  static BankParseResult parseStatement(String rawText) {
    final bankType = detect(rawText);
    final parser = getParser(bankType);
    return parser.parse(rawText);
  }
}
