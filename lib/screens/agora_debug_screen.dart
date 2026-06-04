import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/agora_service.dart';
import '../services/call_service.dart';

/// Developer tool to test Agora RTC join/leave and event callbacks.
class AgoraDebugScreen extends StatefulWidget {
  const AgoraDebugScreen({super.key});

  @override
  State<AgoraDebugScreen> createState() => _AgoraDebugScreenState();
}

class _AgoraDebugScreenState extends State<AgoraDebugScreen> {
  final _channelController = TextEditingController(text: 'debug_ch_${DateTime.now().millisecondsSinceEpoch}');
  final _callService = CallService();
  final _eventLog = <String>[];

  RtcEngine? _engine;
  bool _isJoining = false;
  bool _isInChannel = false;

  int? _localUid;
  int? _remoteUid;
  String _connectionState = 'disconnected';
  String _joinSuccess = '—';
  String _lastUserJoined = '—';
  String _lastUserOffline = '—';
  String? _activeChannel;
  String? _appId;

  @override
  void dispose() {
    _channelController.dispose();
    _releaseEngine();
    super.dispose();
  }

  void _log(String message) {
    final line = '${DateTime.now().toIso8601String().substring(11, 19)}  $message';
    debugPrint('[AgoraDebug] $message');
    setState(() {
      _eventLog.insert(0, line);
      if (_eventLog.length > 50) _eventLog.removeLast();
    });
  }

  Future<bool> _requestMicPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _releaseEngine() async {
    try {
      if (_engine != null) {
        if (_isInChannel) await _engine!.leaveChannel();
        await _engine!.release();
      }
    } catch (e) {
      debugPrint('AgoraDebug release error: $e');
    }
    _engine = null;
    _isInChannel = false;
  }

  Future<void> _joinChannel() async {
    final channelName = _channelController.text.trim();
    if (channelName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a channel name')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    if (_isJoining || _isInChannel) return;

    setState(() {
      _isJoining = true;
      _joinSuccess = '—';
      _lastUserJoined = '—';
      _lastUserOffline = '—';
      _remoteUid = null;
      _localUid = null;
      _connectionState = 'connecting';
    });

    try {
      final tokenPayload = await _callService.fetchAgoraToken(
        accessToken: auth.accessToken!,
        channelName: channelName,
      );

      final token = tokenPayload['token'] as String? ?? '';
      final appId = tokenPayload['appId'] as String? ?? '';
      final resolvedChannel = tokenPayload['channelName'] as String? ?? channelName;

      if (appId.isEmpty || appId == AgoraService.appId) {
        throw Exception('Server Agora App ID not configured');
      }
      if (token.isEmpty) {
        throw Exception('Empty token from server');
      }

      final granted = await _requestMicPermission();
      if (!granted) {
        throw Exception('Microphone permission denied');
      }

      await _releaseEngine();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
          ) {
            if (!mounted) return;
            setState(() {
              _connectionState = '${state.name} (${reason.name})';
            });
            _log('connectionState: ${state.name}, reason: ${reason.name}');
          },
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            final uid = connection.localUid;
            setState(() {
              _isInChannel = true;
              _isJoining = false;
              _localUid = uid;
              _activeChannel = connection.channelId;
              _joinSuccess = 'yes (${elapsed}ms, uid=$uid)';
              _connectionState = 'joined';
            });
            _log('onJoinChannelSuccess: channel=${connection.channelId}, uid=$uid, elapsed=${elapsed}ms');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (!mounted) return;
            setState(() {
              _remoteUid = remoteUid;
              _lastUserJoined = 'uid=$remoteUid (${elapsed}ms)';
            });
            _log('onUserJoined: remoteUid=$remoteUid, elapsed=${elapsed}ms');
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            if (!mounted) return;
            setState(() {
              _remoteUid = null;
              _lastUserOffline = 'uid=$remoteUid (${reason.name})';
            });
            _log('onUserOffline: remoteUid=$remoteUid, reason=${reason.name}');
          },
          onError: (ErrorCodeType err, String msg) {
            _log('onError: ${err.name} — $msg');
          },
        ),
      );

      await _engine!.enableAudio();

      setState(() {
        _appId = appId;
        _activeChannel = resolvedChannel;
      });

      _log('joinChannel → $resolvedChannel');

      await _engine!.joinChannel(
        token: token,
        channelId: resolvedChannel,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      _log('join failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Join failed: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isJoining = false;
          _connectionState = 'error';
        });
      }
      await _releaseEngine();
    }
  }

  Future<void> _leaveChannel() async {
    if (_engine == null || !_isInChannel) return;

    try {
      _log('leaveChannel');
      await _engine!.leaveChannel();
    } catch (e) {
      _log('leave error: $e');
    }

    if (mounted) {
      setState(() {
        _isInChannel = false;
        _isJoining = false;
        _remoteUid = null;
        _connectionState = 'disconnected';
        _joinSuccess = 'left channel';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text('Agora Debug', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _channelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Channel name',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E2637),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                onPressed: () {
                  _channelController.text = 'debug_ch_${DateTime.now().millisecondsSinceEpoch}';
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_isJoining || _isInChannel) ? null : _joinChannel,
                  icon: _isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.login),
                  label: Text(_isJoining ? 'Joining…' : 'Join channel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isInChannel ? _leaveChannel : null,
                  icon: const Icon(Icons.logout),
                  label: const Text('Leave channel'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _statusCard(),
          const SizedBox(height: 16),
          Text('Event log', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: _eventLog.isEmpty
                ? const Center(child: Text('No events yet', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: _eventLog.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _eventLog[i],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2637),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Active channel', _activeChannel ?? '—'),
          _row('App ID', _appId != null ? '${_appId!.substring(0, 8)}…' : '—'),
          const Divider(color: Colors.white12, height: 24),
          _row('Local UID', _localUid?.toString() ?? '—'),
          _row('Remote UID', _remoteUid?.toString() ?? '—'),
          _row('Connection state', _connectionState),
          _row('Join success', _joinSuccess),
          _row('User joined', _lastUserJoined),
          _row('User offline', _lastUserOffline),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
