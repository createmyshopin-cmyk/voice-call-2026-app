import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import 'scale_pressed_button.dart';

class HomeErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const HomeErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomeTheme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: HomeTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: HomeTheme.textSecondary.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: HomeTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ScalePressedButton(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: HomeTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
