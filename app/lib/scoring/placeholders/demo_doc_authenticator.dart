/// P6-03: Demo Document Authenticator
/// Always returns authentic with high confidence for demo purposes.
class DemoDocAuthenticator {
  static Future<AuthResult> authenticate({required String docType}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const AuthResult(isAuthentic: true, confidence: 0.92);
  }
}

class AuthResult {
  final bool isAuthentic;
  final double confidence;
  const AuthResult({required this.isAuthentic, required this.confidence});
}
