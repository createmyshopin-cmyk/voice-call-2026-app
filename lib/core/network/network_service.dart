import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../services/api_config.dart';
import 'api_diagnostics.dart';
import 'network_status.dart';

/// Low-level connectivity probe — link type + internet + backend reachability.
class NetworkService {
  NetworkService({
    Connectivity? connectivity,
    InternetConnection? internetChecker,
    InternetConnection? backendChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetChecker = internetChecker ?? InternetConnection(),
        _backendChecker = backendChecker ??
            InternetConnection.createInstance(
              customCheckOptions: [
                InternetCheckOption(
                  uri: Uri.parse(apiHealthUrl),
                  timeout: const Duration(seconds: 8),
                  responseStatusFn: (response) =>
                      response.statusCode >= 200 && response.statusCode < 500,
                ),
              ],
              useDefaultOptions: false,
            );

  final Connectivity _connectivity;
  final InternetConnection _internetChecker;
  final InternetConnection _backendChecker;

  final StreamController<NetworkSnapshot> _controller =
      StreamController<NetworkSnapshot>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetSub;
  StreamSubscription<InternetStatus>? _backendSub;
  Timer? _pollTimer;

  NetworkStatus _status = NetworkStatus.connected;
  ConnectionType _connectionType = ConnectionType.unknown;
  bool _internetReachable = true;
  bool _backendReachable = true;
  bool _initialized = false;

  NetworkStatus get status => _status;
  ConnectionType get connectionType => _connectionType;
  bool get internetReachable => _internetReachable;
  bool get backendReachable => _backendReachable;
  bool get isConnected => _status == NetworkStatus.connected;
  bool get isDisconnected => _status == NetworkStatus.disconnected;

  Stream<NetworkSnapshot> get onStatusChanged => _controller.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _refreshStatus();

    _connectivitySub = _connectivity.onConnectivityChanged.listen((_) {
      unawaited(_refreshStatus());
    });

    _internetSub = _internetChecker.onStatusChange.listen((_) {
      unawaited(_refreshStatus());
    });

    _backendSub = _backendChecker.onStatusChange.listen((_) {
      unawaited(_refreshStatus());
    });

    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_refreshStatus()),
    );
  }

  Future<NetworkSnapshot> checkNow() => _refreshStatus();

  Future<NetworkSnapshot> _refreshStatus() async {
    final results = await _connectivity.checkConnectivity();
    final linkType = _mapConnectionType(results);

    bool hasInternet = false;
    bool hasBackend = false;

    try {
      hasInternet = await _internetChecker.hasInternetAccess;
    } catch (e) {
      debugPrint('[NetworkService] internet check failed: $e');
      hasInternet = linkType != ConnectionType.none;
    }

    try {
      hasBackend = await _backendChecker.hasInternetAccess;
    } catch (e) {
      debugPrint('[NetworkService] backend check failed: $e');
      hasBackend = false;
    }

    // Connected only when general internet AND API backend are both reachable.
    final newStatus = (hasInternet && hasBackend)
        ? NetworkStatus.connected
        : NetworkStatus.disconnected;

    final changed = newStatus != _status ||
        linkType != _connectionType ||
        hasInternet != _internetReachable ||
        hasBackend != _backendReachable;

    _status = newStatus;
    _connectionType = linkType;
    _internetReachable = hasInternet;
    _backendReachable = hasBackend;

    final snapshot = NetworkSnapshot(
      status: _status,
      connectionType: _connectionType,
      internetReachable: _internetReachable,
      backendReachable: _backendReachable,
    );

    if (changed) {
      networkLog('connectionType=${snapshot.connectionType.name}');
      networkLog('internetReachable=$hasInternet');
      networkLog('backendReachable=$hasBackend');
      networkLog('status=${snapshot.status.name}');
      debugPrint(
        '[NetworkService] ${snapshot.status.name} '
        'via ${snapshot.connectionType.name} '
        '(internet=$hasInternet backend=$hasBackend)',
      );
      _controller.add(snapshot);
    }

    return snapshot;
  }

  ConnectionType _mapConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectionType.none;
    }
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    }
    return ConnectionType.unknown;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _internetSub?.cancel();
    _backendSub?.cancel();
    _pollTimer?.cancel();
    _controller.close();
  }
}

class NetworkSnapshot {
  final NetworkStatus status;
  final ConnectionType connectionType;
  final bool internetReachable;
  final bool backendReachable;

  const NetworkSnapshot({
    required this.status,
    required this.connectionType,
    this.internetReachable = true,
    this.backendReachable = true,
  });

  bool get isConnected => status == NetworkStatus.connected;
}
