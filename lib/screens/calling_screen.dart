import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../screens/recharge_screen.dart';
import '../services/agora_service.dart';
import '../services/agora_token_service.dart';
import '../services/call_service.dart';
import '../services/incoming_call_coordinator.dart';

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
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = false;
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

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  late AnimationController _breathingController;
  late AnimationController _waveformController;
  late AnimationController _screenEntryController;

  int _ringingTimerSeconds = 24;
  Timer? _ringingCountdownTimer;
  Timer? _statusPollTimer;

  // Gift & chat system state
  final List<String> _quickMessages = [
    "Hey! Can you hear me?",
    "Sorry, my camera is acting up.",
    "Let me call you back in a bit.",
    "Low coin balance, recharging soon!",
    "Great talking to you! 😊",
  ];
  final List<String> _sentMessages = [];
  bool _showMessageOverlay = false;

  bool _showGiftAnim = false;
  String _currentGiftName = '';
  String _currentGiftIcon = '';

  String _networkQuality = 'Good';

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

    // Pulse animation for online indicator
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

    // End call breathing controller
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Waveform controller
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Entry animation
    _screenEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (_canJoinImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connectAfterAccepted();
      });
    } else {
      _startRingingCountdown();
      _startCallRequestPolling();
    }

    _screenEntryController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringingCountdownTimer?.cancel();
    _statusPollTimer?.cancel();
    _pulseController.dispose();
    _breathingController.dispose();
    _waveformController.dispose();
    _screenEntryController.dispose();
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
          onNetworkQuality: (RtcConnection connection, int remoteUid, QualityType localQuality, QualityType remoteQuality) {
            String qText = 'Good';
            if (localQuality == QualityType.qualityExcellent || localQuality == QualityType.qualityGood) {
              qText = 'Good';
            } else if (localQuality == QualityType.qualityPoor || localQuality == QualityType.qualityBad) {
              qText = 'Poor';
            } else {
              qText = 'Fair';
            }
            if (mounted) {
              setState(() {
                _networkQuality = qText;
              });
            }
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

  void _endCall({String? endedReason}) async {
    _timer?.cancel();
    _ringingCountdownTimer?.cancel();

    final requestId = widget.callRequestId;
    if (requestId != null && requestId.isNotEmpty) {
      IncomingCallCoordinator.markHandled(requestId);
    }

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
        if (result.newBalance != null) {
          wallet.setBalanceFromServer(result.newBalance!);
        } else {
          await wallet.loadWallet();
        }
      } catch (e) {
        debugPrint('Failed to end call session in backend: $e');
        await wallet.loadWallet();
      }
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleMute() async {
    await _engine?.muteLocalAudioStream(!_isMuted);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    await _engine?.setEnableSpeakerphone(!_isSpeakerOn);
    setState(() => _isSpeakerOn = !_isSpeakerOn);
  }

  Future<void> _toggleVideo() async {
    if (_engine == null) return;
    if (_isVideoEnabled) {
      await _engine!.disableVideo();
      setState(() => _isVideoEnabled = false);
    } else {
      final camera = await Permission.camera.request();
      if (camera.isGranted) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
        setState(() => _isVideoEnabled = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required for video calls.')),
          );
        }
      }
    }
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatCoins(int amount) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(amount);
  }

  String get _titleLabel => widget.displayName ?? 'Priya Sharma';

  // Floating gift selection sheet
  void _showGiftSelectionSheet(WalletProvider wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gift a Smile',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF222222),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF777777)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gifts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final gift = _gifts[index];
                  return InkWell(
                    onTap: () => _sendGift(gift, wallet),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF1493).withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(gift.icon, style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 8),
                          Text(
                            gift.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF1493),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${gift.price} C',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _sendGift(GiftItem gift, WalletProvider wallet) {
    if (wallet.balance < gift.price) {
      Navigator.pop(context);
      _showInsufficientCoinsSheet(gift.price);
      return;
    }

    wallet.setBalanceFromServer(wallet.balance - gift.price);
    Navigator.pop(context);

    setState(() {
      _currentGiftName = gift.name;
      _currentGiftIcon = gift.icon;
      _showGiftAnim = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(gift.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Sent ${gift.name} to Priya Sharma!'),
          ],
        ),
        backgroundColor: const Color(0xFFFF1493),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showGiftAnim = false;
        });
      }
    });
  }

  void _showInsufficientCoinsSheet(int requiredCoins) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1493).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFF1493),
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Insufficient Coins',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need at least $requiredCoins Coins to send this gift.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoinRechargeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1493),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Recharge Now',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'More Call Options',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoreOptionItem(
                    icon: Icons.flip_camera_ios_rounded,
                    label: 'Flip Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _switchCamera();
                    },
                    isEnabled: _isVideoEnabled,
                  ),
                  _buildMoreOptionItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'In-call Chat',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _showMessageOverlay = true);
                    },
                    isEnabled: true,
                  ),
                  _buildMoreOptionItem(
                    icon: Icons.security_rounded,
                    label: 'Privacy Settings',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy settings are auto-managed by standard Agora encryption.')),
                      );
                    },
                    isEnabled: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: Stack(
        children: [
          // 1. Blurred Portrait image Background OR Remote Video Feed
          Positioned.fill(
            child: (_isVideoEnabled && _remoteUid != null && _engine != null)
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : Image.network(
                    widget.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      color: const Color(0xFF080E1A),
                      child: Center(
                        child: Icon(Icons.person, size: 100, color: Colors.white24),
                      ),
                    ),
                  ),
          ),
          if (!(_isVideoEnabled && _remoteUid != null))
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x59000000), // rgba(0,0,0,0.35)
                    Color(0xA6000000), // rgba(0,0,0,0.65)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Local camera feed in a floating card if video is active
          if (_isVideoEnabled && !_isRinging && _isJoined)
            _buildLocalCameraFloatingCard(),

          // 3. Main call interface inside a Safe Area
          SafeArea(
            child: FadeTransition(
              opacity: _screenEntryController.drive(CurveTween(curve: Curves.easeIn)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row (Back button, Balance Pill)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGlassBackButton(),
                        _buildWalletBalancePill(wallet.balance),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Middle layout: profile, duration, badges
                  Expanded(
                    child: Stack(
                      children: [
                        // Center Top Profile Column
                        Align(
                          alignment: Alignment.topCenter,
                          child: _buildProfileSection(),
                        ),

                        // HD Badge (Left) & Network Badge (Right)
                        Positioned(
                          left: 20,
                          top: 170,
                          child: _buildHdBadge(),
                        ),
                        Positioned(
                          right: 20,
                          top: 170,
                          child: _buildNetworkBadge(),
                        ),

                        // Dynamic call state overlay (Ringing text etc.)
                        if (_isRinging)
                          Align(
                            alignment: Alignment.center,
                            child: _buildRingingOverlay(),
                          ),
                      ],
                    ),
                  ),

                  // Coin Charging Card
                  Align(
                    alignment: Alignment.center,
                    child: _buildCoinChargingCard(wallet.balance),
                  ),

                  const SizedBox(height: 20),

                  // Neon Audio Reactive Waveform
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 60,
                      child: _isRinging
                          ? const SizedBox()
                          : ReactiveWaveform(controller: _waveformController),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Call Controls row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCallControlsRow(),
                  ),

                  const SizedBox(height: 24),

                  // Gift Section Panel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _screenEntryController,
                        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                      )),
                      child: _buildGiftSectionCard(wallet),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick messages overlay
          if (_showMessageOverlay) _buildInCallChatTray(),
          if (_sentMessages.isNotEmpty) _buildFloatingSentTextOverlay(),

          // Sent Gift Particle / Float Animation Overlay
          if (_showGiftAnim) _buildGiftAnimationOverlay(),
        ],
      ),
    );
  }

  Widget _buildGlassBackButton() {
    return ScalePressedButton(
      onTap: () {
        // Back button functions as minimization or hanging up based on ringing
        if (_isRinging) {
          _endCall(endedReason: 'user_hangup');
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildWalletBalancePill(int balance) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: balance.toDouble(), end: balance.toDouble()),
      duration: const Duration(milliseconds: 800),
      builder: (context, val, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'C',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatCoins(val.toInt()),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Listener Avatar Stack
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF4DA6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1493).withOpacity(0.25),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.network(
                        widget.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Container(
                          color: const Color(0xFF131A28),
                          child: const Icon(Icons.person, color: Colors.white54, size: 40),
                        ),
                      ),
                    ),
                  ),
                  // Pulse online green dot
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseScale.value,
                              child: Opacity(
                                opacity: _pulseOpacity.value,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2ECC71),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),

              const SizedBox(height: 16),

              // Listener Name with verified pink check
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _titleLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFFFF1493),
                    size: 26,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Call Duration
              Text(
                _isJoined ? _formatTime(_seconds) : (_isRinging ? 'Ringing...' : 'Connecting...'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHdBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF2ECC71),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'HD',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _networkQuality,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.signal_cellular_alt_rounded,
            color: Color(0xFF2ECC71),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildRingingOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(seconds: 1),
          builder: (context, val, child) {
            return Text(
              'Waiting for answer (${_ringingTimerSeconds}s)…',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCoinChargingCard(int balance) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: balance.toDouble(), end: balance.toDouble()),
      duration: const Duration(milliseconds: 800),
      builder: (context, val, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Call Charges
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'C',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Call Charges',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹18 / min',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF1493),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Vertical Divider
              Container(
                height: 36,
                width: 1,
                color: Colors.white.withOpacity(0.15),
              ),
              const SizedBox(width: 24),
              // Remaining Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Balance',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'C',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCoins(val.toInt()),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallControlsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const preferredGlass = 72.0;
        const preferredEnd = 90.0;
        const endCallRatio = preferredEnd / preferredGlass;
        const preferredTotal = 4 * preferredGlass + preferredEnd;

        final glassSize = constraints.maxWidth >= preferredTotal
            ? preferredGlass
            : constraints.maxWidth / (4 + endCallRatio);
        final endSize = glassSize * endCallRatio;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GlassIconButton(
              icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              label: 'Speaker',
              isActive: _isSpeakerOn,
              onTap: _toggleSpeaker,
              size: glassSize,
            ),
            GlassIconButton(
              icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: 'Mute',
              isActive: _isMuted,
              onTap: _toggleMute,
              size: glassSize,
            ),
            BreathingGlowButton(
              controller: _breathingController,
              size: endSize,
              onTap: () => _endCall(endedReason: 'user_hangup'),
              child: Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: endSize * 0.42,
              ),
            ),
            GlassIconButton(
              icon: _isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              label: 'Video',
              isActive: _isVideoEnabled,
              onTap: _toggleVideo,
              size: glassSize,
            ),
            GlassIconButton(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              onTap: _showMoreOptionsSheet,
              size: glassSize,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGiftSectionCard(WalletProvider wallet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gift Box Icon Circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFFFF1493),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gift a Smile',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Send a gift and make their day!',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button
          ScalePressedButton(
            onTap: () => _showGiftSelectionSheet(wallet),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF1493),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.send_rounded, color: Color(0xFFFF1493), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Send Gift',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF1493),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalCameraFloatingCard() {
    return Positioned(
      right: _localCardX,
      top: _localCardY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _localCardX = math.max(10, math.min(MediaQuery.of(context).size.width - 130, _localCardX - details.delta.dx));
            _localCardY = math.max(60, math.min(MediaQuery.of(context).size.height - 250, _localCardY + details.delta.dy));
          });
        },
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF131A28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _engine != null
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : const Center(child: Icon(Icons.videocam_off, color: Colors.white24)),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftAnimationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 2000),
          builder: (context, val, child) {
            final opacity = val < 0.2 ? val / 0.2 : (val > 0.8 ? (1.0 - val) / 0.2 : 1.0);
            final scale = 0.5 + 1.5 * val;
            final yOffset = -300 * val;

            return Center(
              child: Transform.translate(
                offset: Offset(0, yOffset),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentGiftIcon,
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1493).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Sent $_currentGiftName!',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInCallChatTray() {
    return Positioned(
      bottom: 240,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Messages',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: () => setState(() => _showMessageOverlay = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickMessages.map((m) => ActionChip(
                backgroundColor: Colors.white10,
                side: BorderSide.none,
                label: Text(m, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _sentMessages.add(m);
                    _showMessageOverlay = false;
                  });
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _sentMessages.remove(m));
                  });
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSentTextOverlay() {
    return Positioned(
      bottom: 320,
      left: 40,
      right: 40,
      child: Column(
        children: _sentMessages.map((m) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF1493).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            m,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        )).toList(),
      ),
    );
  }
}

// --- Dynamic Neon Audio Waveform Widget ---
class ReactiveWaveform extends StatelessWidget {
  final AnimationController controller;
  const ReactiveWaveform({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(24, (index) {
            final t = controller.value * 2 * math.pi;
            final wave1 = math.sin(t + index * 0.5);
            final wave2 = math.cos(2 * t - index * 0.3);
            final amplitude = 8.0 + 32.0 * (0.5 * wave1 + 0.5 * wave2).abs();

            return Container(
              width: 3.5,
              height: amplitude,
              decoration: BoxDecoration(
                color: const Color(0xFFFF1493),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1493).withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// --- Glassmorphism Icon Button with scale animation on click ---
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String label;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.isActive = false,
    required this.onTap,
    required this.label,
    this.size = 72,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive
                    ? const Color(0xFFFF1493).withOpacity(0.85)
                    : Colors.black.withOpacity(0.35),
                border: Border.all(
                  color: widget.isActive
                      ? const Color(0xFFFF1493).withOpacity(0.5)
                      : Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.36,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- End Call Breathing Glow Container ---
class BreathingGlowButton extends StatelessWidget {
  final AnimationController controller;
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const BreathingGlowButton({
    super.key,
    required this.controller,
    required this.child,
    required this.onTap,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    return ScalePressedButton(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, childWidget) {
          final val = controller.value;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF1493),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1493).withOpacity(0.3 + 0.3 * val),
                  blurRadius: 12 + 18 * val,
                  spreadRadius: 2 * val,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

// --- Scale pressed button widget used for scale transitions ---
class ScalePressedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ScalePressedButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<ScalePressedButton> createState() => _ScalePressedButtonState();
}

class _ScalePressedButtonState extends State<ScalePressedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class GiftItem {
  final String icon;
  final String name;
  final int price;

  const GiftItem({required this.icon, required this.name, required this.price});
}

final List<GiftItem> _gifts = const [
  GiftItem(icon: '🌟', name: 'Super Star', price: 50),
  GiftItem(icon: '🎈', name: 'Love Balloon', price: 100),
  GiftItem(icon: '🌹', name: 'Sweet Rose', price: 200),
  GiftItem(icon: '👑', name: 'Shiny Crown', price: 500),
  GiftItem(icon: '💎', name: 'Magic Diamond', price: 1000),
  GiftItem(icon: '🏰', name: 'Fantasy Castle', price: 5000),
];
