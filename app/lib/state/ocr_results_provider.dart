import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Accumulates OCR extraction results across all steps.
/// Used by CrossStepValidator to check consistency between documents.
///
/// Key = docType (e.g., 'aadhaar_front', 'pan', 'bank_statement')
/// Value = extracted data map from DemoOcrService
final ocrResultsProvider = StateNotifierProvider<OcrResultsNotifier, Map<String, Map<String, dynamic>>>((ref) {
  return OcrResultsNotifier();
});

class OcrResultsNotifier extends StateNotifier<Map<String, Map<String, dynamic>>> {
  OcrResultsNotifier() : super({});

  /// Store OCR result for a specific document type
  void addResult(String docType, Map<String, dynamic> data) {
    state = {...state, docType: data};
  }

  /// Remove a specific document's OCR data (e.g., on re-upload)
  void removeResult(String docType) {
    final updated = Map<String, Map<String, dynamic>>.from(state);
    updated.remove(docType);
    state = updated;
  }

  /// Clear all accumulated OCR data
  void clear() {
    state = {};
  }

  /// Check if a specific docType has been extracted
  bool hasResult(String docType) => state.containsKey(docType);
}
