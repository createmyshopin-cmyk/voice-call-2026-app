import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lightweight native animation overlay for sent gifts.
class GiftSenderAnimation extends StatefulWidget {
  final String animationKey;
  final String emoji;
  final String giftName;
  final int comboCount;

  const GiftSenderAnimation({
    super.key,
    required this.animationKey,
    required this.emoji,
    required this.giftName,
    this.comboCount = 1,
  });

  @override
  State<GiftSenderAnimation> createState() => _GiftSenderAnimationState();
}

class _GiftSenderAnimationState extends State<GiftSenderAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.comboCount > 1 ? 3000 : 2400,
      ),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_mainController);

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _particleController]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ..._buildParticles(),
              Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scale.value,
                  child: _buildMainGift(),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.28,
                child: Opacity(
                  opacity: _opacity.value.clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.comboCount > 1)
                        _PulsingComboBadge(count: widget.comboCount),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1493).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.comboCount > 1
                              ? '${widget.emoji} ${widget.giftName} x${widget.comboCount} Combo'
                              : 'Sent ${widget.giftName}!',
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainGift() {
    final bounce = widget.animationKey == 'cat' ||
            widget.animationKey == 'puppy'
        ? math.sin(_mainController.value * math.pi * 4) * 12
        : 0.0;

    return Transform.translate(
      offset: Offset(0, bounce),
      child: Text(
        widget.emoji,
        style: TextStyle(
          fontSize: widget.animationKey == 'crown' ? 96 : 80,
          shadows: [
            if (widget.animationKey == 'crown' || widget.animationKey == 'diamond')
              Shadow(
                color: Colors.amber.withOpacity(0.8),
                blurRadius: 24,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    final particles = <Widget>[];
    final count = widget.animationKey == 'heart' ? 12 : 8;
    final t = _particleController.value;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + t * math.pi * 2;
      final radius = 80 + 60 * _mainController.value;
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * radius - 40 * _mainController.value;

      final particle = widget.animationKey == 'heart'
          ? '❤️'
          : widget.animationKey == 'diamond'
              ? '✨'
              : widget.animationKey == 'rose'
                  ? '🌸'
                  : '✨';

      particles.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: (1 - _mainController.value).clamp(0.0, 0.8),
            child: Text(particle, style: const TextStyle(fontSize: 18)),
          ),
        ),
      );
    }
    return particles;
  }
}

class _PulsingComboBadge extends StatefulWidget {
  final int count;

  const _PulsingComboBadge({required this.count});

  @override
  State<_PulsingComboBadge> createState() => _PulsingComboBadgeState();
}

class _PulsingComboBadgeState extends State<_PulsingComboBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _pulse.value * 0.1,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'COMBO x${widget.count}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
