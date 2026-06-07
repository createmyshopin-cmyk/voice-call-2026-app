import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/gift_engagement_config.dart';
import '../../providers/gift_provider.dart';
import 'gift_sender_animation.dart';
import 'premium_gift_animation.dart';

/// Renders queued sender animations (max 5) without stacking overlap.
class GiftAnimationLayer extends StatelessWidget {
  const GiftAnimationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GiftProvider>(
      builder: (context, gifts, _) {
        final items = gifts.animationQueue.active;
        if (items.isEmpty) return const SizedBox.shrink();

        return Stack(
          children: [
            for (var i = 0; i < items.length; i++)
              Positioned.fill(
                key: ValueKey(items[i].id),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 1.0 - (i * 0.12),
                    child: items[i].isPremium
                        ? PremiumGiftAnimation(
                            animationKey: items[i].animationKey,
                            emoji: items[i].emoji,
                            giftName: items[i].giftName,
                            comboCount: items[i].comboCount,
                          )
                        : GiftSenderAnimation(
                            animationKey: items[i].animationKey,
                            emoji: items[i].emoji,
                            giftName: items[i].giftName,
                            comboCount: items[i].comboCount,
                          ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class GiftMilestoneToast extends StatefulWidget {
  const GiftMilestoneToast({super.key});

  @override
  State<GiftMilestoneToast> createState() => _GiftMilestoneToastState();
}

class _GiftMilestoneToastState extends State<GiftMilestoneToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  String? _visibleMsg;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncMessage(String? msg) {
    if (msg == null) {
      _visibleMsg = null;
      return;
    }
    if (msg != _visibleMsg) {
      _visibleMsg = msg;
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GiftEngagementConfig.enableMilestones) {
      return const SizedBox.shrink();
    }

    final msg = context.watch<GiftProvider>().milestoneToast;
    _syncMessage(msg);
    if (_visibleMsg == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1493).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _visibleMsg!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GiftStreakBadge extends StatelessWidget {
  const GiftStreakBadge({super.key});

  static String labelForCount(int count) {
    if (count <= 0) return '';
    final noun = count == 1 ? 'Gift' : 'Gifts';
    return '🎁 $count $noun Sent';
  }

  @override
  Widget build(BuildContext context) {
    if (!GiftEngagementConfig.enableGiftStreak) {
      return const SizedBox.shrink();
    }

    final count = context.watch<GiftProvider>().sessionGiftCount;
    if (count <= 0) return const SizedBox.shrink();

    return Positioned(
      top: -10,
      left: -8,
      right: -8,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF1493)),
          ),
          child: Text(
            labelForCount(count),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small combo badge on the gift button — pulse scale, 3s client-side.
class GiftComboBadge extends StatefulWidget {
  const GiftComboBadge({super.key});

  @override
  State<GiftComboBadge> createState() => _GiftComboBadgeState();
}

class _GiftComboBadgeState extends State<GiftComboBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  GiftComboState? _shown;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!GiftEngagementConfig.enableGiftCombo) {
      return const SizedBox.shrink();
    }

    final combo = context.watch<GiftProvider>().activeComboBadge;
    if (combo == null || combo.count <= 1) {
      _shown = null;
      return const SizedBox.shrink();
    }
    _shown = combo;

    return Positioned(
      bottom: -8,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulse.value * 0.12),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              '${combo.giftEmoji} x${combo.count}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny particle burst on gift send — respects [GiftEngagementConfig].
class GiftMicroParticleBurst extends StatefulWidget {
  const GiftMicroParticleBurst({super.key});

  @override
  State<GiftMicroParticleBurst> createState() => _GiftMicroParticleBurstState();
}

class _GiftMicroParticleBurstState extends State<GiftMicroParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _lastToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!GiftEngagementConfig.enableMicroCelebrations) {
      return const SizedBox.shrink();
    }

    final token = context.watch<GiftProvider>().microCelebrationToken;
    if (token != _lastToken && token > 0) {
      _lastToken = token;
      _controller.forward(from: 0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.value <= 0) return const SizedBox.shrink();
        final t = _controller.value;
        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(6, (i) {
            final angle = (i / 6) * 3.14159 * 2;
            final r = 18 + 22 * t;
            return Positioned(
              left: 26 + r * (i.isEven ? 1 : -1) * 0.35,
              top: 26 + r * (i.isOdd ? 1 : -1) * 0.35,
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Text(
                  i.isEven ? '✨' : '💖',
                  style: TextStyle(fontSize: 10 + 4 * (1 - t)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
