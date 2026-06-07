import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

/// Persists auth session (JWT token + user data) using flutter_secure_storage.
/// Called on login → saves. Called on app start → restores. Called on logout → clears.
class SessionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );

  static const _keyToken    = 'gc_auth_token';
  static const _keyUserId   = 'gc_user_id';
  static const _keyUserName = 'gc_user_name';
  static const _keyMobile   = 'gc_user_mobile';
  static const _keyCreatedAt = 'gc_created_at';

  /// Persist session after successful OTP verification
  static Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    await _storage.write(key: _keyToken,     value: token);
    await _storage.write(key: _keyUserId,    value: user.id);
    await _storage.write(key: _keyUserName,  value: user.name ?? '');
    await _storage.write(key: _keyMobile,    value: user.mobile);
    await _storage.write(key: _keyCreatedAt, value: DateTime.now().toIso8601String());
  }

  /// Load session on app start — returns null if no session stored
  static Future<Map<String, String>?> loadSession() async {
    final token = await _storage.read(key: _keyToken);
    if (token == null || token.isEmpty) return null;

    final userId    = await _storage.read(key: _keyUserId)    ?? '';
    final name      = await _storage.read(key: _keyUserName)  ?? '';
    final mobile    = await _storage.read(key: _keyMobile)    ?? '';
    final createdAt = await _storage.read(key: _keyCreatedAt) ?? '';

    return {
      'token':     token,
      'userId':    userId,
      'name':      name,
      'mobile':    mobile,
      'createdAt': createdAt,
    };
  }

  /// Clear all stored session data on logout
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  /// Check if a valid session exists
  static Future<bool> hasSession() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }
}
