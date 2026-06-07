import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the API JWT across app restarts (Firebase session restores separately).
class SessionStorage {
  static const _tokenKey = 'access_token';
  static const _verificationIdKey = 'otp_verification_id';
  static const _pendingPhoneKey = 'otp_pending_phone';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> readAccessToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearAccessToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Persists in-flight OTP state so manual entry still works after app backgrounding.
  static Future<void> saveOtpState({
    required String verificationId,
    required String phoneE164,
  }) async {
    await _storage.write(key: _verificationIdKey, value: verificationId);
    await _storage.write(key: _pendingPhoneKey, value: phoneE164);
  }

  static Future<String?> readVerificationId() async {
    return _storage.read(key: _verificationIdKey);
  }

  static Future<String?> readPendingPhone() async {
    return _storage.read(key: _pendingPhoneKey);
  }

  static Future<void> clearOtpState() async {
    await _storage.delete(key: _verificationIdKey);
    await _storage.delete(key: _pendingPhoneKey);
  }
}
