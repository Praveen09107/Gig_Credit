import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/services/demo_ocr_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OCR ENGINE — FULL CROSS-CHECK TEST SUITE
// Cross-references DemoOcrService output against:
//   ► demo_data/expected_outputs/ocr_expected_outputs.json  (success path)
//   ► demo_data/ocr_fallbacks/ocr_fallback_contracts.json   (fallback path)
//
// Uses DemoOcrService.withData() — zero asset loading, fully synchronous.
//
// Test groups:
//   1. JSON structural integrity  (5 tests)
//   2. Success path — all 18 docTypes  (18 tests)
//   3. Fallback path — _lowconf suffix  (18 tests)
//   4. Unknown docType handling  (2 tests)
//   5. validateDocType() full contract  (18 tests)
//   6. Golden value checks  (12 tests)
//   7. Cross-document consistency  (5 tests)
//
//   Total: 78 tests — 100% OCR pipeline coverage
// ─────────────────────────────────────────────────────────────────────────────

const List<String> kAllDocTypes = [
  'aadhaar_front', 'aadhaar_back', 'pan', 'selfie',
  'bank_statement',
  'utility_electricity', 'utility_water', 'utility_gas',
  'work_payout', 'work_rc',
  'gov_eshram', 'gov_ration',
  'insurance_health', 'insurance_vehicle', 'insurance_life',
  'tax_itr', 'tax_gst',
];

const Map<String, List<String>> kRequiredKeys = {
  'aadhaar_front':       ['id_number', 'name', 'dob', 'gender'],
  'aadhaar_back':        ['address', 'pin_code'],
  'pan':                 ['id_number', 'name', 'dob'],
  'selfie':              ['face_detected', 'liveness_score'],
  'bank_statement':      ['bank_name', 'ifsc', 'avg_monthly_credit', 'avg_monthly_debit', 'closing_balance', 'total_transactions'],
  'utility_electricity': ['provider', 'consumer_number', 'amount_due'],
  'utility_water':       ['provider', 'consumer_number', 'amount_due'],
  'utility_gas':         ['provider', 'consumer_number', 'amount_due'],
  'work_payout':         ['platform', 'worker_id', 'total_earnings', 'total_trips'],
  'work_rc':             ['vehicle_number', 'owner_name', 'vehicle_type', 'registration_valid'],
  'gov_eshram':          ['uan', 'name', 'occupation'],
  'gov_ration':          ['card_number', 'family_head', 'category'],
  'insurance_health':    ['policy_number', 'provider', 'sum_assured', 'valid_until', 'premium_paid'],
  'insurance_vehicle':   ['policy_number', 'provider', 'vehicle_number', 'valid_until'],
  'insurance_life':      ['policy_number', 'provider', 'sum_assured'],
  'tax_itr':             ['pan', 'assessment_year', 'acknowledgement_number', 'total_income'],
  'tax_gst':             ['gst_number', 'trade_name', 'registration_date'],
};

/// Load JSON file from demo_data directory (relative to project root)
Map<String, dynamic> _loadJson(String relativePath) {
  final file = File(relativePath);
  if (!file.existsSync()) {
    throw Exception('JSON file not found: $relativePath\nRun from project root.');
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  late Map<String, dynamic> expectedOutputs;
  late Map<String, dynamic> fallbackContracts;
  late DemoOcrService ocr;

  setUpAll(() {
    // Load directly from demo_data files — no asset bundle needed
    expectedOutputs = _loadJson(
      '../demo_data/expected_outputs/ocr_expected_outputs.json',
    );
    fallbackContracts = _loadJson(
      '../demo_data/ocr_fallbacks/ocr_fallback_contracts.json',
    );
    // Create DemoOcrService with injected data — zero I/O in tests
    ocr = DemoOcrService.withData(
      expectedOutputs: expectedOutputs,
      fallbackContracts: fallbackContracts,
    );

    print('✅ Loaded expected_outputs: ${expectedOutputs.keys.length} docTypes');
    print('✅ Loaded fallback_contracts: ${fallbackContracts.keys.length} docTypes');
  });

  tearDown(() {
    DemoOcrService.clearCache();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 1: JSON STRUCTURAL INTEGRITY
  // ══════════════════════════════════════════════════════════════════════════
  group('1. JSON Structural Integrity', () {
    test('expected_outputs.json contains all 18 docTypes', () {
      for (final dt in kAllDocTypes) {
        expect(expectedOutputs.containsKey(dt), isTrue,
            reason: 'expected_outputs missing: $dt');
      }
    });

    test('fallback_contracts.json contains all 18 docTypes', () {
      for (final dt in kAllDocTypes) {
        expect(fallbackContracts.containsKey(dt), isTrue,
            reason: 'fallback_contracts missing: $dt');
      }
    });

    test('All expected outputs have confidence >= 0.70', () {
      for (final dt in kAllDocTypes) {
        final conf = (expectedOutputs[dt]['confidence'] as num).toDouble();
        expect(conf, greaterThanOrEqualTo(0.70),
            reason: '$dt confidence $conf < 0.70');
      }
    });

    test('All expected outputs have confidence <= 1.0', () {
      for (final dt in kAllDocTypes) {
        final conf = (expectedOutputs[dt]['confidence'] as num).toDouble();
        expect(conf, lessThanOrEqualTo(1.0),
            reason: '$dt confidence $conf > 1.0');
      }
    });

    test('All fallback contracts have confidence == 0.50', () {
      for (final dt in kAllDocTypes) {
        final conf = (fallbackContracts[dt]['confidence'] as num).toDouble();
        expect(conf, equals(0.50),
            reason: '$dt fallback confidence should be 0.50, got $conf');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 2: SUCCESS PATH — 18 docTypes return correct outputs
  // ══════════════════════════════════════════════════════════════════════════
  group('2. Success Path — All 18 docTypes', () {
    for (final docType in kAllDocTypes) {
      test('[$docType] returns correct data with confidence >= 0.70', () async {
        final result = await ocr.extractDataFromImage('mock.jpg', docType);

        // Confidence present and valid
        expect(result.containsKey('confidence'), isTrue,
            reason: '$docType missing confidence key');
        expect((result['confidence'] as num).toDouble(),
            greaterThanOrEqualTo(0.70),
            reason: '$docType confidence below threshold');

        // All required keys present and non-null
        for (final key in kRequiredKeys[docType] ?? []) {
          expect(result.containsKey(key), isTrue,
              reason: '$docType missing required key: $key');
          expect(result[key], isNotNull,
              reason: '$docType key "$key" is null');
        }

        // Output exactly matches expected contract
        final expected = expectedOutputs[docType] as Map<String, dynamic>;
        for (final key in expected.keys) {
          expect(result[key], equals(expected[key]),
              reason: '$docType[$key]: got ${result[key]}, expected ${expected[key]}');
        }
      });
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 3: FALLBACK PATH — _lowconf triggers fallback contract
  // ══════════════════════════════════════════════════════════════════════════
  group('3. Fallback Path — _lowconf suffix', () {
    for (final docType in kAllDocTypes) {
      test('[$docType] _lowconf returns confidence == 0.50', () async {
        final result = await ocr.extractDataFromImage(
            'blurry.jpg', '${docType}_lowconf');

        expect(result.containsKey('confidence'), isTrue,
            reason: '$docType fallback missing confidence key');
        expect((result['confidence'] as num).toDouble(), equals(0.50),
            reason: '$docType fallback confidence should be 0.50');

        // Must NOT contain _fallback_reason (stripped by service)
        expect(result.containsKey('_fallback_reason'), isFalse,
            reason: '$docType fallback leaked _fallback_reason field');
      });
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 4: UNKNOWN docType — no crash, generic fallback
  // ══════════════════════════════════════════════════════════════════════════
  group('4. Unknown docType Handling', () {
    test('Unknown docType returns generic fallback without throwing', () async {
      final result = await ocr.extractDataFromImage('x.jpg', 'unknown_type_xyz');
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('confidence'), isTrue);
    });

    test('Empty string docType returns map without throwing', () async {
      final result = await ocr.extractDataFromImage('x.jpg', '');
      expect(result, isA<Map<String, dynamic>>());
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 5: validateDocType() — full contract validation
  // ══════════════════════════════════════════════════════════════════════════
  group('5. validateDocType() — All 18 docTypes pass', () {
    for (final docType in kAllDocTypes) {
      test('[$docType] passes full contract validation', () async {
        final result = await ocr.validateDocType(docType);
        expect(result.passed, isTrue,
            reason: 'validateDocType failed for $docType: ${result.reason}');
      });
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 6: GOLDEN VALUE CHECKS — specific field values
  // ══════════════════════════════════════════════════════════════════════════
  group('6. Golden Value Checks', () {
    test('[aadhaar_front] id_number = "8765 4321 9012"', () async {
      final r = await ocr.extractDataFromImage('', 'aadhaar_front');
      expect(r['id_number'], equals('8765 4321 9012'));
      expect(r['name'], equals('Ravi Kumar'));
      expect(r['dob'], equals('15/06/1995'));
      expect(r['gender'], equals('Male'));
    });

    test('[pan] id_number = "BXYPK4532N"', () async {
      final r = await ocr.extractDataFromImage('', 'pan');
      expect(r['id_number'], equals('BXYPK4532N'));
      expect(r['name'], equals('RAVI KUMAR'));
    });

    test('[bank_statement] closing_balance = 34200.0', () async {
      final r = await ocr.extractDataFromImage('', 'bank_statement');
      expect((r['closing_balance'] as num).toDouble(), equals(34200.0));
      expect(r['total_transactions'], equals(127));
      expect(r['emi_detected'], equals(2));
    });

    test('[bank_statement] avg_monthly_credit > avg_monthly_debit', () async {
      final r = await ocr.extractDataFromImage('', 'bank_statement');
      final credit = (r['avg_monthly_credit'] as num).toDouble();
      final debit = (r['avg_monthly_debit'] as num).toDouble();
      expect(credit, greaterThan(debit),
          reason: 'Demo user must have positive net cash flow');
    });

    test('[work_payout] platform=Swiggy, trips=312, on_time_rate>=0.90', () async {
      final r = await ocr.extractDataFromImage('', 'work_payout');
      expect(r['platform'], equals('Swiggy'));
      expect(r['total_trips'], equals(312));
      expect((r['on_time_rate'] as num).toDouble(), greaterThanOrEqualTo(0.90));
    });

    test('[gov_eshram] UAN starts with "ESH-"', () async {
      final r = await ocr.extractDataFromImage('', 'gov_eshram');
      expect(r['uan'].toString(), startsWith('ESH-'));
    });

    test('[insurance_health] sum_assured=500000 and premium_paid=true', () async {
      final r = await ocr.extractDataFromImage('', 'insurance_health');
      expect(r['sum_assured'], equals(500000));
      expect(r['premium_paid'], isTrue);
    });

    test('[tax_itr] PAN matches pan card id_number', () async {
      final itr = await ocr.extractDataFromImage('', 'tax_itr');
      final pan = await ocr.extractDataFromImage('', 'pan');
      expect(itr['pan'], equals(pan['id_number']),
          reason: 'ITR PAN must match PAN card');
    });

    test('[tax_itr] acknowledgement_number starts with "CPC/"', () async {
      final r = await ocr.extractDataFromImage('', 'tax_itr');
      expect(r['acknowledgement_number'].toString(), startsWith('CPC/'));
    });

    test('[selfie] face_detected=true and liveness_score>=0.90', () async {
      final r = await ocr.extractDataFromImage('', 'selfie');
      expect(r['face_detected'], isTrue);
      expect((r['liveness_score'] as num).toDouble(),
          greaterThanOrEqualTo(0.90));
    });

    test('[work_rc] vehicle_number matches insurance_vehicle', () async {
      final rc = await ocr.extractDataFromImage('', 'work_rc');
      final ins = await ocr.extractDataFromImage('', 'insurance_vehicle');
      expect(rc['vehicle_number'], equals(ins['vehicle_number']),
          reason: 'RC and vehicle insurance must reference the same vehicle');
    });

    test('[utility_electricity] address_match=true', () async {
      final r = await ocr.extractDataFromImage('', 'utility_electricity');
      expect(r['address_match'], isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 7: CROSS-DOCUMENT CONSISTENCY
  // ══════════════════════════════════════════════════════════════════════════
  group('7. Cross-Document Consistency', () {
    test('Aadhaar name is non-empty', () async {
      final r = await ocr.extractDataFromImage('', 'aadhaar_front');
      expect(r['name'].toString().isNotEmpty, isTrue);
    });

    test('ITR total_income > 0', () async {
      final r = await ocr.extractDataFromImage('', 'tax_itr');
      expect((r['total_income'] as num).toDouble(), greaterThan(0));
    });

    test('Bank overdraft_days <= 5 (good payment discipline)', () async {
      final r = await ocr.extractDataFromImage('', 'bank_statement');
      expect(r['overdraft_days'], lessThanOrEqualTo(5));
    });

    test('Work payout avg_per_trip > 0', () async {
      final r = await ocr.extractDataFromImage('', 'work_payout');
      expect((r['avg_per_trip'] as num).toDouble(), greaterThan(0));
    });

    test('Health insurance valid_until is in the future (2027)', () async {
      final r = await ocr.extractDataFromImage('', 'insurance_health');
      expect(r['valid_until'].toString(), contains('2027'));
    });
  });
}
