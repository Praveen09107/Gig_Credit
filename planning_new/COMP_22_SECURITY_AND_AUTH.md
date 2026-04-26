# ================================================================================
# GIGCREDIT — COMPONENT: SECURITY AND AUTHENTICATION
# Document 22 | planning_new
# ================================================================================

## 1. HMAC-SHA256 AUTHENTICATION PROTOCOL

### 1.1 How It Works

Every API request from the app to the backend is signed with HMAC-SHA256:

```
message = "{device_id}:{unix_timestamp}:{sha256(request_body)}"
signature = HMAC-SHA256(message, shared_secret)
```

### 1.2 Request Headers

| Header          | Value                              |
|-----------------|--------------------------------------|
| X-Api-Key       | Server API key (shared)              |
| X-Device-Id     | SHA256 of device fingerprint         |
| X-Timestamp     | Unix timestamp (seconds)             |
| X-Signature     | HMAC-SHA256 signature                |
| Content-Type    | application/json                     |

### 1.3 Shared Secrets (Demo)

```
HMAC_SECRET = "gigcredit-demo-hmac-secret-2026"
SERVER_API_KEY = "gigcredit-demo-api-key-2026"
```

**For production**: Use unique per-device keys derived from device registration.

---

## 2. DEMO SIMPLIFICATIONS

For the hackathon, security is implemented but simplified:

| Security Feature          | Production Level    | Demo Level               |
|--------------------------|---------------------|--------------------------|
| HMAC authentication      | Full implementation | Implemented, can disable |
| API key rotation         | Auto-rotate         | Static key               |
| Certificate pinning      | Enabled             | Disabled                 |
| Root detection           | Block app           | Warning only             |
| Data encryption at rest  | AES-256             | Hive encryption          |
| Request body encryption  | TLS 1.3 only        | TLS (HTTPS on Render)    |
| Rate limiting            | Per-device limits   | Global limit             |
| Replay attack prevention | Timestamp + nonce   | Timestamp only (5 min)   |

---

## 3. ON-DEVICE DATA PROTECTION

### 3.1 Secure Storage
```dart
// Small secrets (keys, tokens)
final secureStorage = FlutterSecureStorage();
await secureStorage.write(key: 'hmac_secret', value: HMAC_SECRET);

// Structured data (verified profile, scores)
final hiveBox = await Hive.openEncryptedBox('gigcredit_secure',
  encryptionCipher: HiveAesCipher(encryptionKey));
```

### 3.2 Data Deletion
After final report is displayed:
```dart
Future<void> deleteAllSensitiveData() async {
  // Delete document images
  await _clearDirectory('cache/uploads/');
  
  // Delete OCR text
  await hiveBox.delete('ocr_results');
  
  // Delete feature vector
  await hiveBox.delete('feature_vector');
  
  // Delete raw transactions
  await hiveBox.delete('transactions');
  
  // KEEP: final score report, LLM explanation
}
```
