import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/network_service.dart';
import '../providers/creator_provider.dart';
import 'supabase_config.dart';

void realtimeLog(String message) {
  developer.log(message, name: 'REALTIME');
  // ignore: avoid_print
  print('[REALTIME] $message');
}

/// Subscribes to `creator_profiles` INSERT/UPDATE and patches [CreatorProvider].
class RealtimeListenerStatusService {
  RealtimeListenerStatusService({NetworkService? networkService})
      : _networkService = networkService;

  final NetworkService? _networkService;

  CreatorProvider? _creatorProvider;
  RealtimeChannel? _channel;
  StreamSubscription<NetworkSnapshot>? _networkSub;
  bool _hasConnectedOnce = false;
  bool _starting = false;

  void bind(CreatorProvider provider) {
    _creatorProvider = provider;
  }

  Future<void> start() async {
    if (_starting) return;
    if (!SupabaseConfig.isConfigured) {
      realtimeLog('Skipped — SUPABASE_URL / SUPABASE_ANON_KEY not set');
      return;
    }
    _starting = true;
    try {
      await SupabaseConfig.initialize();
      await _subscribe();
      _networkSub ??= _networkService?.onStatusChanged.listen((snapshot) {
        if (snapshot.isConnected) {
          unawaited(_reconnectIfNeeded());
        }
      });
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    await _networkSub?.cancel();
    _networkSub = null;
    await _unsubscribe();
    _hasConnectedOnce = false;
  }

  Future<void> _reconnectIfNeeded() async {
    realtimeLog('Reconnected');
    await _subscribe();
  }

  Future<void> _subscribe() async {
    await _unsubscribe();

    final client = SupabaseConfig.client;
    _channel = client.channel('creator_profiles_presence');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'creator_profiles',
          callback: _handlePayload,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'creator_profiles',
          callback: _handlePayload,
        )
        .subscribe((status, error) {
          if (error != null) {
            realtimeLog('Subscribe error: $error');
            return;
          }
          if (status == RealtimeSubscribeStatus.subscribed) {
            if (_hasConnectedOnce) {
              realtimeLog('Reconnected');
            } else {
              realtimeLog('Connected');
              _hasConnectedOnce = true;
            }
          }
        });
  }

  void _handlePayload(PostgresChangePayload payload) {
    final record = payload.newRecord;
    if (record.isEmpty) return;

    final userId = record['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;

    final isOnline = record['is_online'] == true;
    final lastSeen = record['last_seen_at']?.toString();

    if (isOnline) {
      realtimeLog('Listener Online userId=$userId');
    } else {
      realtimeLog('Listener Offline userId=$userId');
    }

    _creatorProvider?.patchCreatorPresence(
      userId: userId,
      isOnline: isOnline,
      lastSeenAt: lastSeen,
    );
  }

  Future<void> _unsubscribe() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await SupabaseConfig.client.removeChannel(channel);
    }
  }

  void dispose() {
    unawaited(stop());
  }
}
