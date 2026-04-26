import 'dart:convert';
import 'package:flutter/services.dart';
import 'ocr_service.dart';

/// Data-driven Demo OCR Service.
///
/// In production/demo mode: loads from asset JSON files bundled with the app.
/// In test mode: accepts injected data maps via [DemoOcrService.withData()].
///
/// All 18 docTypes across Steps 2–8 are covered:
///   Step 2: aadhaar_front, aadhaar_back, pan, selfie
///   Step 3: bank_statement
///   Step 4: utility_electricity, utility_water, utility_gas
///   Step 5: work_payout, work_rc
///   Step 6: gov_eshram, gov_ration
///   Step 7: insurance_health, insurance_vehicle, insurance_life
///   Step 8: tax_itr, tax_gst
class DemoOcrService implements OcrService {
  /// Optional injected data for testing — bypasses rootBundle
  final Map<String, dynamic>? _injectedExpected;
  final Map<String, dynamic>? _injectedFallback;

  /// Production constructor — loads from app assets
  const DemoOcrService()
      : _injectedExpected = null,
        _injectedFallback = null;

  /// Test constructor — uses injected data maps, no asset loading needed
  const DemoOcrService.withData({
    required Map<String, dynamic> expectedOutputs,
    required Map<String, dynamic> fallbackContracts,
  })  : _injectedExpected = expectedOutputs,
        _injectedFallback = fallbackContracts;

  /// Cached asset data (lazy-loaded once)
  static Map<String, dynamic>? _cachedExpected;
  static Map<String, dynamic>? _cachedFallback;

  Future<Map<String, dynamic>> _getExpectedOutputs() async {
    if (_injectedExpected != null) return _injectedExpected!;
    if (_cachedExpected != null) return _cachedExpected!;
    final raw = await rootBundle.loadString('assets/ocr/expected_outputs.json');
    _cachedExpected = json.decode(raw) as Map<String, dynamic>;
    return _cachedExpected!;
  }

  Future<Map<String, dynamic>> _getFallbackContracts() async {
    if (_injectedFallback != null) return _injectedFallback!;
    if (_cachedFallback != null) return _cachedFallback!;
    final raw = await rootBundle.loadString('assets/ocr/fallback_contracts.json');
    _cachedFallback = json.decode(raw) as Map<String, dynamic>;
    return _cachedFallback!;
  }

  @override
  Future<Map<String, dynamic>> extractDataFromImage(
    String imagePath,
    String docType,
  ) async {
    // Simulate realistic OCR processing time (only in production — skip in tests)
    if (_injectedExpected == null) {
      await Future.delayed(const Duration(milliseconds: 1800));
    }

    // Support forced low-confidence test scenario:
    // Pass docType as e.g. 'pan_lowconf' to simulate fallback path
    final bool forceLowConf = docType.endsWith('_lowconf');
    final String canonicalType =
        forceLowConf ? docType.replaceAll('_lowconf', '') : docType;

    if (forceLowConf) {
      final fallbacks = await _getFallbackContracts();
      if (fallbacks.containsKey(canonicalType)) {
        final result = Map<String, dynamic>.from(fallbacks[canonicalType] as Map);
        result.remove('_fallback_reason');
        return result;
      }
    }

    // Normal path: return from expected outputs
    final outputs = await _getExpectedOutputs();
    if (outputs.containsKey(canonicalType)) {
      return Map<String, dynamic>.from(outputs[canonicalType] as Map);
    }

    // Unknown docType: generic fallback
    return {
      'raw_text': 'Document uploaded successfully.',
      'data': 'Extracted successfully',
      'confidence': 0.80,
    };
  }

  /// Validate a docType against both expected output and fallback contracts.
  /// Used by the OCR test suite.
  Future<OcrValidationResult> validateDocType(String docType) async {
    final outputs = await _getExpectedOutputs();
    final fallbacks = await _getFallbackContracts();

    if (!outputs.containsKey(docType)) {
      return OcrValidationResult(
        docType: docType,
        passed: false,
        reason: 'Missing from expected_outputs: "$docType"',
      );
    }

    final expected = outputs[docType] as Map<String, dynamic>;
    final confidence = (expected['confidence'] as num?)?.toDouble() ?? 0.0;

    if (confidence < 0.70) {
      return OcrValidationResult(
        docType: docType,
        passed: false,
        reason: 'confidence $confidence < 0.70',
      );
    }

    for (final key in expected.keys) {
      if (key == 'confidence') continue;
      final val = expected[key];
      if (val == null || val.toString().isEmpty) {
        return OcrValidationResult(
          docType: docType,
          passed: false,
          reason: 'Key "$key" is null or empty',
        );
      }
    }

    if (!fallbacks.containsKey(docType)) {
      return OcrValidationResult(
        docType: docType,
        passed: false,
        reason: 'No fallback contract for "$docType"',
      );
    }

    return OcrValidationResult(
      docType: docType,
      passed: true,
      reason: 'All checks passed. confidence=$confidence',
    );
  }

  /// Clear static cache — call in tests between runs
  static void clearCache() {
    _cachedExpected = null;
    _cachedFallback = null;
  }
}

class OcrValidationResult {
  final String docType;
  final bool passed;
  final String reason;

  const OcrValidationResult({
    required this.docType,
    required this.passed,
    required this.reason,
  });

  @override
  String toString() => '[${passed ? "PASS" : "FAIL"}] $docType — $reason';
}
