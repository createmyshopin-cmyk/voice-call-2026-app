import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the API JWT across app restarts (Firebase session restores separately).
class SessionStorage {
  static const _tokenKey = 'access_token';
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
}
