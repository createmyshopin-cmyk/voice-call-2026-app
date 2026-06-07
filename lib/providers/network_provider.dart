import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../core/network/network_service.dart';
import '../core/network/network_status.dart';

typedef NetworkRecoveryCallback = Future<void> Function();

/// Exposes live connectivity state and triggers data refresh on reconnect.
class NetworkProvider with ChangeNotifier {
  NetworkProvider(this._service) {
    _subscription = _service.onStatusChanged.listen(_onSnapshot);
  }

  final NetworkService _service;
  late final StreamSubscription<NetworkSnapshot> _subscription;

  NetworkStatus _status = NetworkStatus.connected;
  ConnectionType _connectionType = ConnectionType.unknown;
  bool _isChecking = false;
  int _recoveryTick = 0;

  final List<NetworkRecoveryCallback> _recoveryCallbacks = [];

  NetworkStatus get status => _status;
  ConnectionType get connectionType => _connectionType;
  bool get isConnected => _status == NetworkStatus.connected;
  bool get isDisconnected => _status == NetworkStatus.disconnected;
  bool get isChecking => _isChecking;

  /// Increments each time connectivity is restored — widgets can watch this.
  int get recoveryTick => _recoveryTick;

  String get connectionLabel {
    switch (_connectionType) {
      case ConnectionType.wifi:
        return 'WiFi';
      case ConnectionType.mobile:
        return 'Mobile Data';
      case ConnectionType.none:
        return 'No Connection';
      case ConnectionType.unknown:
        return 'Unknown';
    }
  }

  NetworkService get service => _service;

  Future<void> initialize() async {
    await _service.initialize();
    _applySnapshot(
      NetworkSnapshot(
        status: _service.status,
        connectionType: _service.connectionType,
      ),
    );
  }

  void registerRecoveryCallback(NetworkRecoveryCallback callback) {
    if (!_recoveryCallbacks.contains(callback)) {
      _recoveryCallbacks.add(callback);
    }
  }

  void unregisterRecoveryCallback(NetworkRecoveryCallback callback) {
    _recoveryCallbacks.remove(callback);
  }

  Future<void> retryCheck() async {
    _isChecking = true;
    notifyListeners();
    try {
      final snapshot = await _service.checkNow();
      _applySnapshot(snapshot);
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void _onSnapshot(NetworkSnapshot snapshot) {
    final wasDisconnected = _status == NetworkStatus.disconnected;
    _applySnapshot(snapshot);

    if (wasDisconnected && snapshot.isConnected) {
      unawaited(_runRecovery());
    }
  }

  void _applySnapshot(NetworkSnapshot snapshot) {
    final changed = _status != snapshot.status ||
        _connectionType != snapshot.connectionType;
    _status = snapshot.status;
    _connectionType = snapshot.connectionType;
    if (changed) notifyListeners();
  }

  Future<void> _runRecovery() async {
    _recoveryTick++;
    notifyListeners();
    debugPrint('[NetworkProvider] Internet restored — recovery tick $_recoveryTick');

    for (final callback in List<NetworkRecoveryCallback>.from(_recoveryCallbacks)) {
      try {
        await callback();
      } catch (e) {
        debugPrint('[NetworkProvider] recovery callback error: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
