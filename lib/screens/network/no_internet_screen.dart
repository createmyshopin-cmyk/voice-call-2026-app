import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/home_theme.dart';
import '../../providers/network_provider.dart';

/// Full-screen overlay shown when the device has no internet access.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkProvider>();

    return Material(
      color: HomeTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: HomeTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: HomeTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your WiFi or mobile data.\nWe\'ll reconnect automatically.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.5,
                  color: HomeTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${network.connectionLabel}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: HomeTheme.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: network.isChecking ? null : () => network.retryCheck(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: HomeTheme.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: network.isChecking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Try Again',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
