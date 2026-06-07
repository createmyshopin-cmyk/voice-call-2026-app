import 'package:flutter/foundation.dart';
import '../models/gift_item.dart';
import '../services/gift_service.dart';

class GiftCatalogProvider with ChangeNotifier {
  final GiftService _service = GiftService();

  List<GiftItem> _gifts = [];
  bool _isLoading = false;
  String? _error;
  String? _loadedForToken;
  bool _loadedThisLaunch = false;

  List<GiftItem> get gifts => List.unmodifiable(_gifts);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCatalog => _gifts.isNotEmpty;

  /// Refresh catalog once per app launch (or when token changes).
  Future<void> ensureLoaded(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    if (_loadedThisLaunch && _loadedForToken == accessToken && _gifts.isNotEmpty) {
      return;
    }
    await loadCatalog(accessToken, force: true);
    _loadedThisLaunch = true;
  }

  Future<void> loadCatalog(String accessToken, {bool force = false}) async {
    if (!force && _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _service.fetchCatalog(accessToken);
      _gifts = items..sort((a, b) => a.coinCost.compareTo(b.coinCost));
      _loadedForToken = accessToken;
    } catch (e) {
      _error = e.toString();
      debugPrint('[GiftCatalogProvider] load failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
