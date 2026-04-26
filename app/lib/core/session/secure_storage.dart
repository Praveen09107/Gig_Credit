import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// P4-01: Secure Storage Wrapper
/// Encrypts and persists verified_profile, step_progress, and auth session on-device.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyProfile = 'gc_verified_profile';
  static const _keySteps = 'gc_step_progress';
  static const _keyAuth = 'gc_auth_session';
  static const _keyTimestamp = 'gc_session_ts';
  static const _keyCredits = 'gc_credits';

  // ── Write ──

  static Future<void> saveProfile(Map<String, dynamic> profileJson) async {
    await _storage.write(key: _keyProfile, value: jsonEncode(profileJson));
    await _storage.write(key: _keyTimestamp, value: DateTime.now().toUtc().toIso8601String());
  }

  static Future<void> saveStepProgress(Map<int, String> stepStatusMap) async {
    final encoded = stepStatusMap.map((k, v) => MapEntry(k.toString(), v));
    await _storage.write(key: _keySteps, value: jsonEncode(encoded));
  }

  static Future<void> saveAuthSession({required String userId, required String token}) async {
    await _storage.write(key: _keyAuth, value: jsonEncode({'userId': userId, 'token': token}));
  }

  static Future<void> saveCredits(Map<String, dynamic> credits) async {
    await _storage.write(key: _keyCredits, value: jsonEncode(credits));
  }

  // ── Read ──

  static Future<Map<String, dynamic>?> loadProfile() async {
    final raw = await _storage.read(key: _keyProfile);
    if (raw == null) return null;

    // Check expiry: 24 hours
    final tsRaw = await _storage.read(key: _keyTimestamp);
    if (tsRaw != null) {
      final ts = DateTime.parse(tsRaw);
      if (DateTime.now().toUtc().difference(ts).inHours > 24) {
        await clearAll(); // Session expired
        return null;
      }
    }

    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<int, String>?> loadStepProgress() async {
    final raw = await _storage.read(key: _keySteps);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
  }

  static Future<Map<String, dynamic>?> loadAuthSession() async {
    final raw = await _storage.read(key: _keyAuth);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> loadCredits() async {
    final raw = await _storage.read(key: _keyCredits);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Clear ──

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
