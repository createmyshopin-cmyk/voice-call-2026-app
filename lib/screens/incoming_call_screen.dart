import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/call_service.dart';
import '../services/incoming_call_coordinator.dart';
import '../services/incoming_call_ringtone.dart';
import '../utils/api_error_message.dart';
import 'calling_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerAvatar;
  final String channelName;
  final String callRequestId;
  final String agoraToken;
  final String agoraAppId;
  final bool isVideo;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerAvatar,
    required this.channelName,
    required this.callRequestId,
    required this.agoraToken,
    required this.agoraAppId,
    required this.isVideo,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final Animation<double> _slideAnimation;
  Timer? _remoteStatusPollTimer;
  final CallService _callService = CallService();

  @override
  void initState() {
    super.initState();
    if (widget.callRequestId.isNotEmpty) {
      IncomingCallCoordinator.markPresenting(widget.callRequestId);
      _startRemoteStatusPoll();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    );

    IncomingCallRingtone.start();
  }

  void _startRemoteStatusPoll() {
    _remoteStatusPollTimer?.cancel();
    _remoteStatusPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _isAccepting) return;
      final token = context.read<AuthProvider>().accessToken;
      if (token == null) return;
      try {
        final data = await _callService.getCallRequestStatus(
          accessToken: token,
          callRequestId: widget.callRequestId,
        );
        final status = data['status'] as String?;
        if (status == 'cancelled' ||
            status == 'missed' ||
            status == 'rejected' ||
            status == 'accepted') {
          IncomingCallCoordinator.markHandled(widget.callRequestId);
          await IncomingCallRingtone.stop();
          if (mounted) Navigator.pop(context);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    IncomingCallRingtone.stop();
    _remoteStatusPollTimer?.cancel();
    IncomingCallCoordinator.clearPresenting();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool _isAccepting = false;

  Future<void> _accept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.accessToken;
      if (token == null) throw Exception('Not authenticated');

      // Accept via backend → get real callSession.id and confirmed channelName
      final result = await _callService.acceptCallRequest(
        accessToken: token,
        callRequestId: widget.callRequestId,
      );

      IncomingCallCoordinator.markHandled(widget.callRequestId);
      _remoteStatusPollTimer?.cancel();
      await IncomingCallRingtone.stop();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallingScreen(
            channelName: result.channelName.isNotEmpty
                ? result.channelName
                : widget.channelName,
            displayName: widget.callerName,
            avatarUrl: widget.callerAvatar,
            isVideoCall: widget.isVideo,
            callRequestId: widget.callRequestId,
            callSessionId: result.callSessionId,
            agoraToken: result.agoraToken.isNotEmpty
                ? result.agoraToken
                : widget.agoraToken,
            agoraAppId: result.agoraAppId.isNotEmpty
                ? result.agoraAppId
                : widget.agoraAppId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAccepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(callAcceptErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _decline() {
    IncomingCallCoordinator.markHandled(widget.callRequestId);
    IncomingCallRingtone.stop();
    _remoteStatusPollTimer?.cancel();
    final token = context.read<AuthProvider>().accessToken;
    if (token != null) {
      _callService
          .rejectCall(accessToken: token, callRequestId: widget.callRequestId)
          .catchError((_) {});
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent accidental back-press dismissing a live call
      child: Scaffold(
        backgroundColor: const Color(0xFF080E1A),
        body: Stack(
          children: [
            // Radial gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [Color(0xFF1A0A2E), Color(0xFF080E1A)],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Call type label
                  Text(
                    widget.isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pulsing avatar
                  ScaleTransition(
                    scale: _slideAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Three ripple rings
                        ...List.generate(3, (i) {
                          final delay = i * 0.33;
                          return AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              final t = (_pulseController.value + delay) % 1.0;
                              return Transform.scale(
                                scale: 1.0 + t * 1.4,
                                child: Opacity(
                                  opacity: (1.0 - t) * 0.4,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFF1493),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        // Avatar
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1493).withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            radius: 66,
                            backgroundImage: widget.callerAvatar.isNotEmpty
                                ? NetworkImage(widget.callerAvatar)
                                    as ImageProvider
                                : null,
                            backgroundColor: const Color(0xFF1E2637),
                            child: widget.callerAvatar.isEmpty
                                ? Text(
                                    widget.callerName.isNotEmpty
                                        ? widget.callerName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Caller name
                  Text(
                    widget.callerName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isVideo ? 'wants to video call' : 'wants to voice call',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Decline / Accept row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decline button
                        _CallButton(
                          icon: Icons.call_end,
                          label: 'Decline',
                          color: const Color(0xFFFF3B30),
                          onTap: _decline,
                        ),

                        // Accept button
                        _CallButton(
                          icon: widget.isVideo ? Icons.videocam : Icons.call,
                          label: _isAccepting ? '...' : 'Accept',
                          color: const Color(0xFF2ECC71),
                          onTap: _isAccepting ? () {} : _accept,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
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
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 10),
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
