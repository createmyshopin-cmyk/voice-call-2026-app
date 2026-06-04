import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/phone_utils.dart';
import 'gender_selection_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

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
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final auth = context.read<AuthProvider>();
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    try {
      final e164 = toE164Phone(_phoneController.text);
      await auth.sendPhoneOtp(e164);

      if (!mounted) return;

      if (auth.hasFirebaseSession) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GenderSelectionScreen()),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneE164: e164,
            phoneDisplay: formatPhoneForDisplay(e164),
          ),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to send OTP')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kPrimary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF5E2C91).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: kSurfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.graphic_eq,
                        color: kPrimary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome back.',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: kOnSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your phone number to continue.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: kOnSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: kSurfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kOutlineVariant.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: kOutlineVariant.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+91',
                                        style: GoogleFonts.manrope(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: kOnSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    enabled: !auth.isLoading,
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: kOnSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Phone Number',
                                      hintStyle: GoogleFonts.manrope(
                                        color: kOnSurfaceVariant.withOpacity(0.5),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: auth.isLoading ? null : _sendOtp,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: auth.isLoading
                                    ? null
                                    : const LinearGradient(
                                        colors: [kPrimary, kPrimaryDim],
                                      ),
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
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Send OTP',
                                            style: GoogleFonts.manrope(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: kSurfaceContainerLowest,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: kSurfaceContainerLowest,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
