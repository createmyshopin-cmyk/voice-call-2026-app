import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/home_theme.dart';
import '../../utils/home_responsive.dart';
import 'coin_icon.dart';
import 'home_animations.dart';
import 'scale_pressed_button.dart';

class WalletHeroCard extends StatefulWidget {
  final int balance;
  final VoidCallback onRecharge;

  const WalletHeroCard({
    super.key,
    required this.balance,
    required this.onRecharge,
  });

  @override
  State<WalletHeroCard> createState() => _WalletHeroCardState();
}

class _WalletHeroCardState extends State<WalletHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
    _loopBounce();
  }

  void _loopBounce() {
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _bounceController.forward(from: 0).then((_) => _loopBounce());
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,##0').format(widget.balance);
    final cardH = HomeResponsive.w(context, 160);
    final marginH = HomeResponsive.w(context, 20);
    final radius = HomeResponsive.w(context, 28);
    final pad = HomeResponsive.w(context, 16);
    final coinArt = HomeResponsive.w(context, 100);

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      offset: const Offset(0, -0.04),
      child: Container(
        height: cardH,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: marginH),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [HomeTheme.primary, HomeTheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: HomeTheme.primary.withValues(alpha: 0.25),
              blurRadius: HomeResponsive.w(context, 30),
              offset: Offset(0, HomeResponsive.w(context, 12)),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: HomeResponsive.w(context, 6),
              right: HomeResponsive.w(context, 8),
              child: AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounce.value),
                    child: child,
                  );
                },
                child: _CoinIllustration(size: coinArt),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, HomeResponsive.w(context, 12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: HomeResponsive.w(context, 16),
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: HomeResponsive.w(context, 6)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CoinIcon(size: HomeResponsive.w(context, 40)),
                        SizedBox(width: HomeResponsive.w(context, 8)),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: HomeResponsive.w(context, 72)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatted,
                                maxLines: 1,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: HomeResponsive.w(context, 52),
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ScalePressedButton(
                          onTap: widget.onRecharge,
                          pressedScale: 0.98,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Coins',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: HomeResponsive.w(context, 18),
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.95),
                                size: HomeResponsive.w(context, 22),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _RechargeButton(onTap: widget.onRecharge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RechargeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RechargeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScalePressedButton(
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        height: HomeResponsive.w(context, 44),
        padding: EdgeInsets.symmetric(horizontal: HomeResponsive.w(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(HomeResponsive.w(context, 14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recharge Now',
              style: GoogleFonts.poppins(
                color: HomeTheme.primary,
                fontSize: HomeResponsive.w(context, 15),
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            SizedBox(width: HomeResponsive.w(context, 4)),
            Icon(
              Icons.arrow_forward_rounded,
              color: HomeTheme.primary,
              size: HomeResponsive.w(context, 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinIllustration extends StatelessWidget {
  final double size;

  const _CoinIllustration({required this.size});

  static const _assetPath = 'assets/illustrations/coin_stack.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _CoinStackFallback(size: size),
    );
  }
}

/// Stacked gold coins — matches reference when PNG asset is absent.
class _CoinStackFallback extends StatelessWidget {
  final double size;

  const _CoinStackFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    final coinW = size * 0.52;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(bottom: 0, child: _coin(coinW, const Color(0xFFE6A800))),
          Positioned(bottom: coinW * 0.22, child: _coin(coinW * 0.92, const Color(0xFFF5C518))),
          Positioned(bottom: coinW * 0.42, child: _coin(coinW * 0.84, const Color(0xFFFFD54F))),
        ],
      ),
    );
  }

  Widget _coin(double width, Color tone) {
    final h = width * 0.22;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone.withValues(alpha: 0.95), tone],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
