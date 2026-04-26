import 'dart:convert';
import 'package:crypto/crypto.dart';

class HmacSigner {
  // In a real app this would be loaded from a secure encalve/env. For the hackathon, we use a mocked secret.
  static const String _secretKey = 'GC_HACKATHON_DEMO_SECRET_KEY_2024';

  /// Generates HMAC-SHA256 signature headers for secure API requests.
  /// Phase 9 Polish: Actually generates a cryptographic hash.
  static Map<String, String> generateSecureHeaders(String payload) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    
    // Create signature payload: timestamp + payload body
    final signaturePayload = '$timestamp.$payload';
    
    // Hash using HMAC-SHA256
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(signaturePayload);
    final hmacSha256 = Hmac(sha256, key); // HMAC-SHA256
    final digest = hmacSha256.convert(bytes);
    
    // Hex string of the signature
    final signature = digest.toString();

    return {
      'X-Api-Key': 'DEMO_KEY',
      'X-Device-Id': 'DEV-SIMULATOR',
      'X-Timestamp': timestamp,
      'X-Signature': signature,
    };
  }
}
