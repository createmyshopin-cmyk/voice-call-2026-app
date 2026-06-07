import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import '../../utils/home_responsive.dart';
import 'scale_pressed_button.dart';

class PromoBanner extends StatefulWidget {
  final VoidCallback onRecharge;

  const PromoBanner({super.key, required this.onRecharge});

  static double height(BuildContext context) =>
      HomeResponsive.promoBannerHeight(context);

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = PromoBanner.height(context);
    final marginH = HomeResponsive.w(context, 20);
    final badge = HomeResponsive.w(context, 44);

    return Container(
      height: h,
      margin: EdgeInsets.symmetric(horizontal: marginH),
      padding: EdgeInsets.symmetric(
        horizontal: HomeResponsive.w(context, 10),
        vertical: HomeResponsive.w(context, 8),
      ),
      decoration: BoxDecoration(
        gradient: HomeTheme.primaryGradient,
        borderRadius: BorderRadius.circular(HomeResponsive.w(context, 18)),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.primary.withValues(alpha: 0.22),
            blurRadius: HomeResponsive.w(context, 14),
            offset: Offset(0, HomeResponsive.w(context, 6)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: badge,
            height: badge,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD54F),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '20%\nEXTRA',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: HomeTheme.textPrimary,
                fontSize: HomeResponsive.w(context, 7.5),
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
          SizedBox(width: HomeResponsive.w(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get 20% Extra Coins',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: HomeResponsive.w(context, 14),
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  'On your first recharge today!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: HomeResponsive.w(context, 10),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _float,
            builder: (context, child) {
              return Transform.translate(offset: Offset(0, _float.value), child: child);
            },
            child: const _GiftIllustration(),
          ),
          SizedBox(width: HomeResponsive.w(context, 6)),
          ScalePressedButton(
            onTap: widget.onRecharge,
            pressedScale: 0.96,
            child: Container(
              constraints: BoxConstraints(maxWidth: HomeResponsive.w(context, 108)),
              padding: EdgeInsets.symmetric(
                horizontal: HomeResponsive.w(context, 8),
                vertical: HomeResponsive.w(context, 6),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(HomeResponsive.w(context, 12)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Recharge Now',
                      style: GoogleFonts.poppins(
                        color: HomeTheme.primary,
                        fontSize: HomeResponsive.w(context, 10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: HomeTheme.primary,
                      size: HomeResponsive.w(context, 14),
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

class _GiftIllustration extends StatelessWidget {
  const _GiftIllustration();

  @override
  Widget build(BuildContext context) {
    final s = HomeResponsive.w(context, 32);
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: s * 0.75,
            height: s * 0.65,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Container(
            width: s * 0.8,
            height: s * 0.16,
            color: const Color(0xFFFFD54F),
          ),
          Container(
            width: s * 0.16,
            height: s * 0.75,
            color: const Color(0xFFFFD54F),
          ),
        ],
      ),
    );
  }
}
