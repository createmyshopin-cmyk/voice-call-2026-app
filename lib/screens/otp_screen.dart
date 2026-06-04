import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'gender_selection_screen.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneE164;
  final String phoneDisplay;

  const OtpScreen({
    super.key,
    required this.phoneE164,
    required this.phoneDisplay,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  int _timerSeconds = 60;
  Timer? _timer;

  static const Color kSurface = Color(0xFF080E1A);
  static const Color kPrimary = Color(0xFFBA9EFF);
  static const Color kPrimaryDim = Color(0xFF8455EF);
  static const Color kOnSurface = Color(0xFFE0E5F6);
  static const Color kOnSurfaceVariant = Color(0xFFA6ABBB);
  static const Color kSurfaceContainerLow = Color(0xFF0D1320);
  static const Color kSurfaceContainerHighest = Color(0xFF1E2637);
  static const Color kSurfaceContainerLowest = Color(0xFF000000);
  static const Color kOutlineVariant = Color(0xFF424855);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode =>
      _controllers.map((c) => c.text.trim()).join();

  Future<void> _verify() async {
    if (_otpCode.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter the $_otpLength-digit code')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      await auth.verifyPhoneOtp(_otpCode);

      if (!mounted) return;

      final destination = auth.user?.onboardingCompleted == true
          ? const HomeScreen()
          : const GenderSelectionScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Invalid verification code')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.sendPhoneOtp(widget.phoneE164, isResend: true);
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent again')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not resend OTP')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: kOnSurface, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kSurfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined, color: kPrimary, size: 40),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verify Code',
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a $_otpLength-digit code to\n${widget.phoneDisplay}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: kOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_otpLength, (index) {
                    return SizedBox(
                      width: 48,
                      height: 64,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !auth.isLoading,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kOnSurface,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: kSurfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _focusNodes[index].hasFocus
                                  ? kPrimary
                                  : kOutlineVariant.withOpacity(0.3),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < _otpLength - 1) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (_otpCode.length == _otpLength) {
                            _verify();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: auth.isLoading ? null : _verify,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: auth.isLoading
                          ? null
                          : const LinearGradient(colors: [kPrimary, kPrimaryDim]),
                      color: auth.isLoading ? kSurfaceContainerHighest : null,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Verify & Continue',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kSurfaceContainerLowest,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: GoogleFonts.inter(color: kOnSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: _timerSeconds == 0 && !auth.isLoading ? _resend : null,
                      child: Text(
                        _timerSeconds == 0
                            ? 'Resend'
                            : 'Resend in ${_timerSeconds}s',
                        style: GoogleFonts.inter(
                          color: _timerSeconds == 0
                              ? kPrimary
                              : kOnSurfaceVariant.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
