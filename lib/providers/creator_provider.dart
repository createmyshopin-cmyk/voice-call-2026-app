import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import '../models/creator.dart';
import '../services/creators_service.dart';

class CreatorProvider with ChangeNotifier {
  String? _accessToken;
  List<Creator> _creators = [];
  bool _isLoading = false;
  String? _error;

  List<Creator> get creators => List.unmodifiable(_creators);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void onAuthChanged(String? accessToken) {
    _accessToken = accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      fetchCreators();
    } else {
      _creators = [];
      _error = null;
      notifyListeners();
    }
  }

  Future<void> fetchCreators() async {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      _error = 'Sign in to see live creators.';
      notifyListeners();
      return;
    }
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = CreatorsService(accessToken: token);
      _creators = await service.fetchActiveCreators();
      _error = null;
    } catch (e) {
      debugPrint('CreatorProvider.fetchCreators error: $e');
      _error = 'Failed to load creators. Pull to refresh.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
