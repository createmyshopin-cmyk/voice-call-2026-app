import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/call_history_item.dart';
import '../services/call_service.dart';

class CallHistoryProvider with ChangeNotifier {
  final CallService _service = CallService();

  List<CallHistoryItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _accessToken;

  List<CallHistoryItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void onAuthChanged(String? accessToken) {
    _accessToken = accessToken;
    if (accessToken != null) {
      fetchHistory();
    } else {
      _items = [];
      _error = null;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    final token = _accessToken;
    if (token == null || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.fetchCallHistory(accessToken: token);
      _error = null;
    } catch (e) {
      debugPrint('CallHistoryProvider.fetchHistory error: $e');
      final ex = ApiException.from(e);
      if (!ex.isNoInternet) {
        _error = ex.message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
