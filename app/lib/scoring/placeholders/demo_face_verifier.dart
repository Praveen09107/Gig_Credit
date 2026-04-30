import 'dart:math';

class DemoFaceVerifierResult {
  final bool matched;
  final String? error;
  
  DemoFaceVerifierResult(this.matched, [this.error]);
}

class DemoFaceVerifier {
  static Future<DemoFaceVerifierResult> verify({
    required String aadhaarPath,
    required String panPath,
    required String selfiePath,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate a successful verification most of the time
    final isMatch = Random().nextDouble() > 0.1;
    
    return DemoFaceVerifierResult(isMatch, isMatch ? null : 'Face mismatch. Please try again.');
  }
}
