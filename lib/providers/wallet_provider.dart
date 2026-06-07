import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/wallet_transaction.dart';
import '../services/api_client.dart' show apiDio, authOptions;

/// Server-authoritative wallet state. Client never invents balance changes.
class WalletProvider with ChangeNotifier {
  int _balance = 0;
  String? _userId;
  String? _accessToken;
  /// Tracks the user we last seeded for — only reseed on login / user switch.
  String? _currentUserId;

  List<WalletTransaction> _transactions = [];
  bool _isLoadingTransactions = false;

  final Dio _dio = apiDio;

  int get balance => _balance;
  String? get userId => _userId;
  String? get accessToken => _accessToken;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoadingTransactions => _isLoadingTransactions;

  int? _parseBalance(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

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
      if (initialCoins != null) {
        _writeBalance('updateAuth:userChanged', initialCoins);
      }
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

  Future<void> loadWallet({
    String reason = 'manual',
    String? accessToken,
  }) async {
    final token = accessToken ?? _accessToken;
    if (token == null) return;
    try {
      final response = await _dio.get(
        '/api/wallet',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is! Map) {
          debugPrint('[WalletProvider] loadWallet:$reason unexpected body: $raw');
          return;
        }
        final data = Map<String, dynamic>.from(raw);
        final serverBalance = _parseBalance(data['coins']) ??
            _parseBalance(data['coin_balance']) ??
            0;
        debugPrint(
          '[WalletProvider] loadWallet:$reason => server balance=$serverBalance',
        );
        _writeBalance('loadWallet:$reason', serverBalance);
      }
    } catch (e) {
      debugPrint('[WalletProvider] loadWallet:$reason error: $e');
    }
  }

  Future<void> fetchTransactions() async {
    final token = _accessToken;
    if (token == null) return;
    _isLoadingTransactions = true;
    notifyListeners();
    try {
      final response = await _dio.get(
        '/api/wallets/transactions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _transactions = data
            .map((json) => WalletTransaction.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint(
          '[WalletProvider] fetchTransactions loaded ${_transactions.length} transactions',
        );
      }
    } catch (e) {
      debugPrint('[WalletProvider] fetchTransactions error: $e');
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Authoritative balance from gift send, recharge verify, or end-call API.
  void setBalanceFromServer(int newBalance) {
    _writeBalance('setBalanceFromServer', newBalance);
  }

  /// Refresh balance from server — use after any financial operation.
  Future<void> refreshFromServer({String reason = 'refresh'}) =>
      loadWallet(reason: reason);
}
