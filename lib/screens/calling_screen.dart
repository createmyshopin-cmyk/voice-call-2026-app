import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/agora_service.dart';
import '../services/agora_token_service.dart';
import '../services/call_service.dart';

class CallingScreen extends StatefulWidget {
  final String channelName;
  final String? displayName;
  final String avatarUrl;
  final bool isVideoCall;
  final String? callRequestId;
  final String? callSessionId;
  final String? agoraToken;
  final String? agoraAppId;

  const CallingScreen({
    super.key,
    required this.channelName,
    this.displayName,
    required this.avatarUrl,
    this.isVideoCall = false,
    this.callRequestId,
    this.callSessionId,
    this.agoraToken,
    this.agoraAppId,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> with TickerProviderStateMixin {
  bool _isRinging = true;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  int _seconds = 0;
  Timer? _timer;

  double _localCardX = 20.0;
  double _localCardY = 80.0;

  RtcEngine? _engine;
  final CallService _callService = CallService();
  final AgoraTokenService _agoraTokenService = AgoraTokenService();
  String? _activeCallSessionId;
  String? _resolvedAgoraToken;
  String? _resolvedAgoraAppId;
  String? _resolvedChannelName;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  int _ringingTimerSeconds = 24;
  Timer? _ringingCountdownTimer;
  Timer? _statusPollTimer;

  final List<String> _quickMessages = [
    "Hey! Can you hear me?",
    "Sorry, my camera is acting up.",
    "Let me call you back in a bit.",
    "Low coin balance, recharging soon!",
    "Great talking to you! 😊",
  ];
  final List<String> _sentMessages = [];
  bool _showMessageOverlay = false;

  bool get _hasActiveSession => _activeCallSessionId != null;

  /// Creator already accepted — session + Agora credentials are ready to join.
  bool get _canJoinImmediately =>
      _hasActiveSession &&
      (_resolvedAgoraToken?.isNotEmpty ?? false) &&
      (_resolvedAgoraAppId?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _activeCallSessionId = widget.callSessionId;
    _resolvedAgoraToken = widget.agoraToken;
    _resolvedAgoraAppId = widget.agoraAppId;
    _resolvedChannelName = widget.channelName;
    _isVideoEnabled = widget.isVideoCall;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (_canJoinImmediately) {
      // Creator accepted — join Agora channel immediately (step 4 → 5).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connectAfterAccepted();
      });
    } else {
      // Caller rings until creator accepts (steps 1 → 2 → 3 → 4 → 5).
      _startRingingCountdown();
      _startCallRequestPolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringingCountdownTimer?.cancel();
    _statusPollTimer?.cancel();
    _pulseController.dispose();
    _disposeAgora();
    super.dispose();
  }

  void _startRingingCountdown() {
    _ringingCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_ringingTimerSeconds > 1) {
        setState(() {
          _ringingTimerSeconds--;
        });
      } else {
        _onRingingTimeout();
      }
    });
  }

  Future<void> _disposeAgora() async {
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
      }
    } catch (e) {
      debugPrint("Agora release error: $e");
    }
  }

  void _startCallRequestPolling() {
    final requestId = widget.callRequestId;
    if (requestId == null || _hasActiveSession) return;

    _statusPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || !_isRinging || _hasActiveSession) return;

      final auth = context.read<AuthProvider>();
      if (auth.accessToken == null) return;

      try {
        final data = await _callService.getCallRequestStatus(
          accessToken: auth.accessToken!,
          callRequestId: requestId,
        );
        final status = data['status'] as String?;
        if (status == 'accepted') {
          final session = data['callSession'] as Map<String, dynamic>?;
          _activeCallSessionId = session?['id'] as String?;
          _resolvedAgoraToken = data['agoraToken'] as String?;
          _resolvedAgoraAppId = data['agoraAppId'] as String?;
          await _connectAfterAccepted();
        } else if (status == 'rejected' ||
            status == 'missed' ||
            status == 'cancelled') {
          _statusPollTimer?.cancel();
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Call request poll error: $e');
      }
    });
  }

  Future<void> _syncCallStatus(String status) async {
    final sessionId = _activeCallSessionId;
    final auth = context.read<AuthProvider>();
    if (sessionId == null || auth.accessToken == null) return;
    try {
      await _callService.updateCallStatus(
        accessToken: auth.accessToken!,
        sessionId: sessionId,
        status: status,
      );
    } catch (e) {
      debugPrint('Call status sync ($status) error: $e');
    }
  }

  Future<void> _connectAfterAccepted() async {
    if (!_isRinging || !mounted) return;
    _ringingCountdownTimer?.cancel();
    _statusPollTimer?.cancel();
    setState(() => _isRinging = false);
    await _syncCallStatus('ringing');
    await _initCall();
  }

  Future<void> _acceptCall() async {
    await _connectAfterAccepted();
  }

  Future<void> _onRingingTimeout() async {
    _ringingCountdownTimer?.cancel();
    await _finalizeCallRequestAsMissed();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _finalizeCallRequestAsMissed() async {
    final auth = context.read<AuthProvider>();
    final requestId = widget.callRequestId;
    if (requestId == null || auth.accessToken == null) return;

    try {
      await _callService.markCallRequestMissed(
        accessToken: auth.accessToken!,
        callRequestId: requestId,
      );
    } catch (e) {
      debugPrint('Failed to mark call as missed: $e');
    }
  }

  Future<void> _finalizeCallRequestAsRejected() async {
    final auth = context.read<AuthProvider>();
    final requestId = widget.callRequestId;
    if (requestId == null || auth.accessToken == null) return;

    try {
      await _callService.rejectCallRequest(
        accessToken: auth.accessToken!,
        callRequestId: requestId,
      );
    } catch (e) {
      debugPrint('Failed to reject call request: $e');
    }
  }

  Future<bool> _requestCallPermissions() async {
    if (kIsWeb) return true;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    if (widget.isVideoCall) {
      final camera = await Permission.camera.request();
      if (!camera.isGranted) return false;
    }

    return true;
  }

  Future<void> _initCall() async {
    await _initAgora();
    _startCallTimer();
  }

  Future<void> _ensureBackendAgoraToken() async {
    final existing = _resolvedAgoraToken ?? widget.agoraToken;
    if (existing != null && existing.isNotEmpty) return;

    final auth = context.read<AuthProvider>();
    if (auth.accessToken == null) return;

    try {
      final result = await _agoraTokenService.fetchToken(
        accessToken: auth.accessToken!,
        channelName: _resolvedChannelName ?? widget.channelName,
      );
      _resolvedAgoraToken = result.token;
      _resolvedChannelName = result.channelName;
    } catch (e) {
      debugPrint('Failed to fetch Agora token from backend: $e');
      rethrow;
    }
  }

  Future<void> _initAgora() async {
    try {
      await _ensureBackendAgoraToken();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get call token from server.'),
            backgroundColor: Colors.red,
          ),
        );
        _endCall();
      }
      return;
    }

    final appId = _resolvedAgoraAppId ?? widget.agoraAppId ?? AgoraService.appId;
    final token = _resolvedAgoraToken ?? widget.agoraToken ?? '';
    final channelName = _resolvedChannelName ?? widget.channelName;

    debugPrint('Joining Agora channel: $channelName');

    if (appId.isEmpty || appId == "YOUR_AGORA_APP_ID") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agora is not configured on the server. Set AGORA_APP_ID in backend .env'),
            backgroundColor: Colors.red,
          ),
        );
        _endCall();
      }
      return;
    }

    final granted = await _requestCallPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone/camera permission is required for calls.'),
            backgroundColor: Colors.red,
          ),
        );
        _endCall();
      }
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() => _isJoined = true);
            _syncCallStatus('ongoing');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            setState(() => _remoteUid = null);
            final endReason = reason == UserOfflineReasonType.userOfflineDropped
                ? 'network_failure'
                : 'creator_hangup';
            _endCall(endedReason: endReason);
          },
        ),
      );

      if (widget.isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: widget.isVideoCall,
          autoSubscribeAudio: true,
          autoSubscribeVideo: widget.isVideoCall,
        ),
      );
    } catch (e) {
      debugPrint("Agora init error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not join voice channel: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _endCall();
      }
    }
  }

  void _startCallTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  // Coin deduction is now handled server-side in POST /api/calls/active/:id/end.
  // The server computes ceil(seconds/60) × ratePerMinute and returns coinsDeducted + newBalance.

  void _endCall({String? endedReason}) async {
    _timer?.cancel();
    _ringingCountdownTimer?.cancel();

    final sessionId = _activeCallSessionId;
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();

    if (_isRinging && widget.callRequestId != null) {
      await _finalizeCallRequestAsRejected();
      await _disposeAgora();
      if (mounted) Navigator.pop(context);
      return;
    }

    await _disposeAgora();

    if (sessionId != null && auth.accessToken != null) {
      try {
        final result = await _callService.endCall(
          accessToken: auth.accessToken!,
          sessionId: sessionId,
          durationSeconds: _seconds,
          endedReason: endedReason,
        );
        debugPrint(
          'Call ended. Coins deducted: ${result.coinsDeducted}, New balance: ${result.newBalance}',
        );
        // Sync wallet from server — prefer server-returned balance for accuracy
        if (result.newBalance != null) {
          wallet.setBalanceFromServer(result.newBalance!);
        } else {
          await wallet.loadWallet();
        }
      } catch (e) {
        debugPrint('Failed to end call session in backend: $e');
        // Refresh wallet from server regardless to stay consistent
        await wallet.loadWallet();
      }
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleMute() async {
    await _engine?.muteLocalAudioStream(!_isMuted);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get _titleLabel => widget.displayName ?? widget.channelName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF080E1A))),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF1493).withOpacity(0.08),
              ),
              child: const SizedBox(),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8A2BE2).withOpacity(0.08),
              ),
              child: const SizedBox(),
            ),
          ),
          if (widget.isVideoCall && !_isRinging) _buildRemoteVideoFeed(),
          _buildVoiceOrRingingUI(),
          if (widget.isVideoCall && !_isRinging) _buildLocalCameraFloatingCard(),
          if (_showMessageOverlay) _buildInCallChatTray(),
          if (_sentMessages.isNotEmpty) _buildFloatingSentTextOverlay(),
        ],
      ),
    );
  }

  Widget _buildRemoteVideoFeed() {
    if (_remoteUid != null && _engine != null) {
      return Positioned.fill(
        child: AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        ),
      );
    }
    return Positioned.fill(child: Image.network(widget.avatarUrl, fit: BoxFit.cover));
  }

  Widget _buildLocalCameraFloatingCard() {
    return Positioned(
      right: _localCardX,
      top: _localCardY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _localCardX -= details.delta.dx;
            _localCardY += details.delta.dy;
          });
        },
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF131A28),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _isVideoEnabled && _engine != null
                ? AgoraVideoView(
                    controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)),
                  )
                : const Center(child: Icon(Icons.videocam_off, color: Colors.white24)),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOrRingingUI() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 80, backgroundImage: NetworkImage(widget.avatarUrl)),
          const SizedBox(height: 24),
          Text(_titleLabel, style: GoogleFonts.poppins(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          if (_isRinging)
            Column(
              children: [
                const Text('Ringing… waiting for answer', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 24),
                FloatingActionButton(
                  onPressed: () => _endCall(endedReason: 'user_hangup'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white), onPressed: _toggleMute),
                const SizedBox(width: 20),
                FloatingActionButton(onPressed: () => _endCall(endedReason: 'user_hangup'), backgroundColor: Colors.red, child: const Icon(Icons.call_end)),
                const SizedBox(width: 20),
                if (widget.isVideoCall) IconButton(icon: const Icon(Icons.flip_camera_ios, color: Colors.white), onPressed: _switchCamera),
              ],
            ),
          const SizedBox(height: 24),
          Text(_isJoined ? _formatTime(_seconds) : 'Connecting...', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => setState(() => _showMessageOverlay = true), child: const Text('Message')),
        ],
      ),
    );
  }

  Widget _buildInCallChatTray() {
    return Positioned(
      bottom: 100, left: 20, right: 20,
      child: Container(
        color: Colors.black87, padding: const EdgeInsets.all(16),
        child: Wrap(
          children: _quickMessages.map((m) => ActionChip(label: Text(m), onPressed: () {
            setState(() { _sentMessages.add(m); _showMessageOverlay = false; });
            Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _sentMessages.remove(m)); });
          })).toList(),
        ),
      ),
    );
  }

  Widget _buildFloatingSentTextOverlay() {
    return Positioned(
      bottom: 200, left: 40, right: 40,
      child: Column(children: _sentMessages.map((m) => Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(m)))).toList()),
    );
  }
}
