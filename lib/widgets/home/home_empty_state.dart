import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import 'scale_pressed_button.dart';

class HomeEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  final String? message;
  final String? subtitle;

  const HomeEmptyState({
    super.key,
    required this.onRefresh,
    this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: HomeTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: HomeTheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message ?? 'No listeners available right now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: HomeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? 'Try again later.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: HomeTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ScalePressedButton(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: HomeTheme.primary),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  color: HomeTheme.primary,
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
