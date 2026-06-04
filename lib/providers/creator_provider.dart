import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import '../models/creator.dart';
import '../services/creators_service.dart';

/// Manages the list of active creators fetched from GET /api/creators.
///
/// Wire up in main.dart as:
/// ```dart
/// ChangeNotifierProxyProvider<AuthProvider, CreatorProvider>(
///   create: (_) => CreatorProvider(),
///   update: (_, auth, prev) => prev!..onAuthChanged(auth.accessToken),
/// )
/// ```
class CreatorProvider with ChangeNotifier {
  final CreatorsService _service = CreatorsService();

  List<Creator> _creators = [];
  bool _isLoading = false;
  String? _error;

  List<Creator> get creators => List.unmodifiable(_creators);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Called by ProxyProvider when auth state changes.
  void onAuthChanged(String? accessToken) {
    if (accessToken != null) {
      fetchCreators();
    } else {
      // Signed out — clear the list
      _creators = [];
      _error = null;
      notifyListeners();
    }
  }

  /// Fetches active creators from the backend.
  /// Safe to call multiple times; deduplicates concurrent calls.
  Future<void> fetchCreators() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _service.fetchActiveCreators();
      _creators = list;
      _error = null;
    } catch (e) {
      debugPrint('CreatorProvider.fetchCreators error: $e');
      _error = 'Failed to load creators. Please try again.';
      // Keep existing list if any — don't wipe on retry failure
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
