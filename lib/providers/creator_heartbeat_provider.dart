import 'dart:async';

import 'package:flutter/material.dart';

import '../services/creator_heartbeat_service.dart';

/// Toggles creator online/offline via API and sends heartbeat every 30s while online.
class CreatorHeartbeatProvider with ChangeNotifier {
  final CreatorHeartbeatService _service = CreatorHeartbeatService();

  Timer? _timer;
  String? _accessToken;
  bool _isActive = false;

  bool get isActive => _isActive;

  void onAuthChanged(String? accessToken) {
    final previous = _accessToken;
    _accessToken = accessToken;
    if (accessToken == null) {
      unawaited(_goOffline(silent: true));
      stop(localOnly: true);
    } else if (_isActive && previous != accessToken) {
      unawaited(_goOnline());
    }
  }

  /// Start or stop when the creator toggles online in the listener dashboard.
  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    if (active && _accessToken != null) {
      unawaited(_goOnline());
    } else {
      _timer?.cancel();
      _timer = null;
      unawaited(_goOffline());
    }
    notifyListeners();
  }

  /// Called when app is backgrounded/closed — mark offline on server.
  Future<void> goOfflineOnBackground() async {
    if (!_isActive) return;
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    await _goOffline(silent: true);
    notifyListeners();
  }

  Future<void> _goOnline() async {
    final token = _accessToken;
    if (token == null || !_isActive) return;
    try {
      await _service.setOnline(token);
      _restartHeartbeat();
    } catch (e) {
      debugPrint('CreatorHeartbeatProvider: setOnline failed: $e');
    }
  }

  Future<void> _goOffline({bool silent = false}) async {
    final token = _accessToken;
    if (token == null) return;
    try {
      await _service.setOffline(token);
    } catch (e) {
      if (!silent) {
        debugPrint('CreatorHeartbeatProvider: setOffline failed: $e');
      }
    }
  }

  void _restartHeartbeat() {
    _timer?.cancel();
    unawaited(_sendHeartbeat());
    _timer = Timer.periodic(
      CreatorHeartbeatService.heartbeatInterval,
      (_) => unawaited(_sendHeartbeat()),
    );
  }

  Future<void> _sendHeartbeat() async {
    final token = _accessToken;
    if (token == null || !_isActive) return;
    try {
      await _service.sendHeartbeat(token);
    } catch (e) {
      debugPrint('CreatorHeartbeatProvider: heartbeat failed: $e');
    }
  }

  void stop({bool localOnly = false}) {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    if (!localOnly && _accessToken != null) {
      unawaited(_goOffline(silent: true));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
