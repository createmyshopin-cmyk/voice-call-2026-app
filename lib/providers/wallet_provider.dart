import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_config.dart';

class WalletProvider with ChangeNotifier {
  int _balance = 0;
  String? _userId;
  String? _accessToken;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  int get balance => _balance;
  String? get userId => _userId;
  String? get accessToken => _accessToken;

  void updateAuth(String? userId, String? accessToken) {
    _userId = userId;
    _accessToken = accessToken;
    if (_userId != null && _accessToken != null) {
      loadWallet();
    } else {
      _balance = 0;
      notifyListeners();
    }
  }

  Future<void> loadWallet() async {
    if (_accessToken == null) return;
    try {
      final response = await _dio.get(
        '/api/wallet',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );
      if (response.statusCode == 200) {
        // Response is { userId: String, name: String, coins: int }
        final data = response.data;
        _balance = data['coins'] as int? ?? 0;
        debugPrint("Coin balance loaded from backend: $_balance");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Load wallet error: $e");
    }
  }

  Future<bool> deductCoins(int amount, {bool localOnly = false}) async {
    if (_balance < amount) return false;
    if (localOnly || _userId == null) {
      _balance -= amount;
      notifyListeners();
      return true;
    }
    try {
      final response = await _dio.post(
        '/api/wallets/adjust',
        data: {
          'userId': _userId,
          'amount': -amount,
          'reason': 'User coin deduction',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadWallet();
        return true;
      }
    } catch (e) {
      debugPrint("Backend coin deduction error: $e");
      // Fallback to local update
      _balance -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> addCoins(int amount) async {
    if (_userId == null) {
      _balance += amount;
      notifyListeners();
      return;
    }
    try {
      final response = await _dio.post(
        '/api/wallets/adjust',
        data: {
          'userId': _userId,
          'amount': amount,
          'reason': 'User recharge package',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadWallet();
      }
    } catch (e) {
      debugPrint("Backend coin adjust error: $e");
      // Fallback to local update
      _balance += amount;
      notifyListeners();
    }
  }

  /// Called after a call ends with the server-returned balance.
  /// Avoids an extra network round-trip for wallet refresh.
  void setBalanceFromServer(int newBalance) {
    _balance = newBalance;
    notifyListeners();
  }
}
