/// P6-02: Demo Face Verifier
/// Always returns a high similarity match for demo purposes.
class DemoFaceVerifier {
  static Future<FaceMatchResult> verify({
    required String selfieBase64,
    required String docFaceBase64,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const FaceMatchResult(similarity: 0.95, matched: true);
  }
}

class FaceMatchResult {
  final double similarity;
  final bool matched;
  const FaceMatchResult({required this.similarity, required this.matched});
}
