import 'dart:async';

import 'package:flutter/material.dart';

import '../services/creator_heartbeat_service.dart';

/// Sends POST /api/creators/heartbeat every 30–60s while the creator is online.
class CreatorHeartbeatProvider with ChangeNotifier {
  final CreatorHeartbeatService _service = CreatorHeartbeatService();

  Timer? _timer;
  String? _accessToken;
  bool _isActive = false;

  bool get isActive => _isActive;

  void onAuthChanged(String? accessToken) {
    _accessToken = accessToken;
    if (accessToken == null) {
      stop();
    } else if (_isActive) {
      _restartTimer();
    }
  }

  /// Start or stop heartbeat when the creator toggles online in the listener panel.
  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    if (active && _accessToken != null) {
      _restartTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  void _restartTimer() {
    _timer?.cancel();
    unawaited(_sendOnce());
    _timer = Timer.periodic(
      CreatorHeartbeatService.heartbeatInterval,
      (_) => unawaited(_sendOnce()),
    );
  }

  Future<void> _sendOnce() async {
    final token = _accessToken;
    if (token == null || !_isActive) return;
    try {
      await _service.sendHeartbeat(token);
    } catch (e) {
      debugPrint('CreatorHeartbeatProvider: heartbeat failed: $e');
    }
  }

  void stop() {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
