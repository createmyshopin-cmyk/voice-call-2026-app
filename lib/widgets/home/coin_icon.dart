import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gold coin circle — default small badge or large wallet hero icon.
class CoinIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool showLetter;

  const CoinIcon({
    super.key,
    this.size = 18,
    this.color = const Color(0xFFFDBA21),
    this.showLetter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: size >= 32
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: size * 0.15,
                  offset: Offset(0, size * 0.06),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: showLetter
          ? Text(
              'H',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.45,
                height: 1,
              ),
            )
          : null,
    );
  }
}
