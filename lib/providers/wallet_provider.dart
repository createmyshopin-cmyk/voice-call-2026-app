import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_config.dart';

class WalletProvider with ChangeNotifier {
  int _balance = 0;
  String? _userId;
  String? _accessToken;
  /// Tracks the user we last seeded for — only reseed on login / user switch.
  String? _currentUserId;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  int get balance => _balance;
  String? get userId => _userId;
  String? get accessToken => _accessToken;

  void _writeBalance(String source, int value) {
    debugPrint(
      '[WalletProvider] $source => balance $_balance -> $value',
    );
    _balance = value;
    notifyListeners();
  }

  void updateAuth(String? userId, String? accessToken, {int? initialCoins}) {
    debugPrint(
      '[WalletProvider] updateAuth userId=$userId '
      'initialCoins=$initialCoins currentUserId=$_currentUserId '
      'currentBalance=$_balance',
    );

    if (userId == null || accessToken == null) {
      _userId = null;
      _accessToken = null;
      _currentUserId = null;
      _writeBalance('updateAuth:logout', 0);
      return;
    }

    final userChanged = _currentUserId != userId;
    final tokenChanged = _accessToken != accessToken;

    _userId = userId;
    _accessToken = accessToken;

    if (userChanged) {
      _currentUserId = userId;
      _writeBalance('updateAuth:userChanged', initialCoins ?? 0);
      loadWallet(reason: 'login');
      return;
    }

    if (tokenChanged) {
      loadWallet(reason: 'tokenRefresh');
      return;
    }

    debugPrint(
      '[WalletProvider] updateAuth skipped balance reload '
      '(auth profile refresh only — wallet balance preserved)',
    );
  }

  /// Sync balance from profile without a network round-trip.
  void setBalance(int coins) {
    _writeBalance('setBalance', coins);
  }

  Future<void> loadWallet({String reason = 'manual'}) async {
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
        final data = response.data as Map<String, dynamic>;
        final serverBalance = (data['coins'] as num?)?.toInt() ??
            (data['coin_balance'] as num?)?.toInt() ??
            0;
        debugPrint(
          '[WalletProvider] loadWallet:$reason => server balance=$serverBalance '
          'raw=$data',
        );
        _writeBalance('loadWallet:$reason', serverBalance);
      }
    } catch (e) {
      debugPrint('[WalletProvider] loadWallet:$reason error: $e');
    }
  }

  Future<bool> deductCoins(int amount, {bool localOnly = false}) async {
    if (_balance < amount) return false;
    if (localOnly || _userId == null) {
      _writeBalance('deductCoins:local', _balance - amount);
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
        await loadWallet(reason: 'deductCoins');
        return true;
      }
    } catch (e) {
      debugPrint('Backend coin deduction error: $e');
      _writeBalance('deductCoins:fallback', _balance - amount);
      return true;
    }
    return false;
  }

  Future<void> addCoins(int amount) async {
    if (_userId == null) {
      _writeBalance('addCoins:local', _balance + amount);
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
        await loadWallet(reason: 'addCoins');
      }
    } catch (e) {
      debugPrint('Backend coin adjust error: $e');
      _writeBalance('addCoins:fallback', _balance + amount);
    }
  }

  /// Authoritative balance from verify RPC or end-call response.
  void setBalanceFromServer(int newBalance) {
    _writeBalance('setBalanceFromServer', newBalance);
  }
}
