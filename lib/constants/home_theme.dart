import 'package:flutter/material.dart';

/// Premium pink-and-white home screen palette.
abstract final class HomeTheme {
  static const Color primary = Color(0xFFFF1493);
  static const Color secondary = Color(0xFFFF4DA6);
  static const Color background = Color(0xFFFFF8FB);
  static const Color screenBackground = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color onlineGreen = Color(0xFF22C55E);
  static const Color starYellow = Color(0xFFFBBF24);
  static const Color rateButtonBg = Color(0xFFFFF0F6);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];
}
