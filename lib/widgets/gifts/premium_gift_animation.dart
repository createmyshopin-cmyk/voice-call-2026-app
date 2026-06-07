import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium moment animation for high-value gifts (creator + sender).
class PremiumGiftAnimation extends StatefulWidget {
  final String animationKey;
  final String emoji;
  final String giftName;
  final int comboCount;

  const PremiumGiftAnimation({
    super.key,
    required this.animationKey,
    required this.emoji,
    required this.giftName,
    this.comboCount = 1,
  });

  @override
  State<PremiumGiftAnimation> createState() => _PremiumGiftAnimationState();
}

class _PremiumGiftAnimationState extends State<PremiumGiftAnimation>
    with TickerProviderStateMixin {
  late AnimationController _main;
  late AnimationController _confetti;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.3), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
    ]).animate(CurvedAnimation(parent: _main, curve: Curves.easeOutCubic));

    _glow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Curves.easeInOut),
    );

    _main.forward();
  }

  @override
  void dispose() {
    _main.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.comboCount > 1
        ? '${widget.giftName} x${widget.comboCount} Combo'
        : widget.giftName;

    return AnimatedBuilder(
      animation: Listenable.merge([_main, _confetti]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ..._confettiPieces(),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1493)
                        .withOpacity(0.35 * _glow.value),
                    blurRadius: 48 * _glow.value,
                    spreadRadius: 8 * _glow.value,
                  ),
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.25 * _glow.value),
                    blurRadius: 64 * _glow.value,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 100),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.26,
              child: Opacity(
                opacity: _main.value > 0.85
                    ? (1.0 - (_main.value - 0.85) / 0.15)
                    : 1.0,
                child: Column(
                  children: [
                    if (widget.comboCount > 1)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'COMBO x${widget.comboCount}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFF1493)),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _confettiPieces() {
    final t = _confetti.value;
    return List.generate(14, (i) {
      final angle = (i / 14) * math.pi * 2 + t * math.pi * 2;
      final r = 90 + 70 * _main.value;
      return Transform.translate(
        offset: Offset(math.cos(angle) * r, math.sin(angle) * r - 30),
        child: Opacity(
          opacity: (1 - _main.value).clamp(0.0, 0.9),
          child: Text(
            i.isEven ? '✨' : '💖',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    });
  }
}
