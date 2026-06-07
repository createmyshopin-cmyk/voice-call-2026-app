import 'dart:async';

import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/creator.dart';
import '../services/creators_service.dart';
import '../services/realtime_listener_status_service.dart';

class CreatorProvider with ChangeNotifier {
  CreatorProvider({RealtimeListenerStatusService? realtimeService})
      : _realtime = realtimeService ?? RealtimeListenerStatusService();

  final RealtimeListenerStatusService _realtime;

  String? _accessToken;
  List<Creator> _creators = [];
  bool _isLoading = false;
  String? _error;

  List<Creator> get creators => List.unmodifiable(_creators);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void onAuthChanged(String? accessToken) {
    _accessToken = accessToken;
    _realtime.bind(this);
    if (accessToken != null && accessToken.isNotEmpty) {
      fetchCreators();
      unawaited(_realtime.start());
    } else {
      unawaited(_realtime.stop());
      _creators = [];
      _error = null;
      notifyListeners();
    }
  }

  /// Patch a single creator from Supabase Realtime — no full list refetch.
  void patchCreatorPresence({
    required String userId,
    required bool isOnline,
    String? lastSeenAt,
  }) {
    final index = _creators.indexWhere((c) => c.id == userId);
    if (index < 0) return;

    final current = _creators[index];
    _creators[index] = current.copyWith(
      isOnline: isOnline,
      lastSeenAt: lastSeenAt ?? current.lastSeenAt,
      lastSeenLabel: Creator.presenceLabel(
        isOnline: isOnline,
        lastSeenAt: lastSeenAt ?? current.lastSeenAt,
      ),
      isVoiceAvailable: isOnline,
      isChatAvailable: isOnline,
    );

    debugPrint(
      '[REALTIME] CreatorProvider Updated userId=$userId isOnline=$isOnline',
    );
    notifyListeners();
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
      final ex = ApiException.from(e);
      if (!ex.isNoInternet) {
        _error = ex.message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _realtime.dispose();
    super.dispose();
  }
}
