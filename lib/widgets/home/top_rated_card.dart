import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/home_theme.dart';
import '../../models/creator.dart';
import '../../utils/home_responsive.dart';
import 'creator_avatar_image.dart';
import 'pulsing_online_dot.dart';
import 'scale_pressed_button.dart';

/// Compact vertical card for horizontal Top Rated carousel.
class TopRatedCard extends StatefulWidget {
  final Creator creator;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final VoidCallback? onTap;

  const TopRatedCard({
    super.key,
    required this.creator,
    required this.onVoiceCall,
    required this.onVideoCall,
    this.onTap,
  });

  static double cardWidth(BuildContext context) => HomeResponsive.w(context, 156);

  /// Height for the horizontal carousel row — includes buffer for text metrics.
  static double cardHeight(BuildContext context) {
    final pad = HomeResponsive.w(context, 8) * 2;
    final img = HomeResponsive.w(context, 108);
    final gap = HomeResponsive.w(context, 6);
    final textBlock = HomeResponsive.w(context, 52);
    final price = HomeResponsive.w(context, 14);
    final btnGap = HomeResponsive.w(context, 4);
    final buttons = HomeResponsive.w(context, 30);
    return pad + img + gap + textBlock + price + btnGap + buttons + HomeResponsive.w(context, 8);
  }

  @override
  State<TopRatedCard> createState() => _TopRatedCardState();
}

class _TopRatedCardState extends State<TopRatedCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _reviewsLabel(int count) {
    if (count <= 0) return 'New';
    return NumberFormat.decimalPattern().format(count);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final creator = widget.creator;
    final w = TopRatedCard.cardWidth(context);
    final pad = HomeResponsive.w(context, 8);
    final img = HomeResponsive.w(context, 108);
    final radius = HomeResponsive.w(context, 16);
    final imageW = w - pad * 2;

    return ScalePressedButton(
      onTap: widget.onTap ?? () {},
      pressedScale: 0.98,
      child: Container(
        width: w,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: HomeTheme.card,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: HomeTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CreatorAvatarImage(
                  imageUrl: creator.avatar,
                  size: img,
                  width: imageW,
                  height: img,
                  borderRadius: BorderRadius.circular(HomeResponsive.w(context, 12)),
                ),
                if (creator.isOnline)
                  Positioned(
                    top: HomeResponsive.w(context, 4),
                    left: HomeResponsive.w(context, 4),
                    child: _OnlineDot(),
                  ),
              ],
            ),
            SizedBox(height: HomeResponsive.w(context, 6)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    creator.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: HomeResponsive.w(context, 13),
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: HomeTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.verified_rounded,
                  color: HomeTheme.primary,
                  size: HomeResponsive.w(context, 14),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.star_rounded, color: HomeTheme.starYellow, size: HomeResponsive.w(context, 12)),
                SizedBox(width: HomeResponsive.w(context, 2)),
                Expanded(
                  child: Text(
                    creator.rating > 0
                        ? '${creator.rating.toStringAsFixed(1)} (${_reviewsLabel(creator.totalCalls)})'
                        : 'New',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: HomeResponsive.w(context, 10),
                      height: 1.1,
                      color: HomeTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (creator.responseRate != null && creator.responseRate! > 0)
              Text(
                '${creator.responseRate!.round()}% Response',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: HomeResponsive.w(context, 10),
                  height: 1.1,
                  color: HomeTheme.textSecondary,
                ),
              ),
            SizedBox(height: HomeResponsive.w(context, 4)),
            Text(
              '₹${creator.ratePerMinute}/min',
              style: GoogleFonts.poppins(
                fontSize: HomeResponsive.w(context, 11),
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: HomeTheme.primary,
              ),
            ),
            SizedBox(height: HomeResponsive.w(context, 4)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleCallButton(icon: Icons.phone_rounded, onTap: widget.onVoiceCall),
                SizedBox(width: HomeResponsive.w(context, 8)),
                _CircleCallButton(icon: Icons.videocam_rounded, onTap: widget.onVideoCall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HomeResponsive.w(context, 5),
        vertical: HomeResponsive.w(context, 2),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HomeResponsive.w(context, 8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingOnlineDot(size: HomeResponsive.w(context, 6)),
          SizedBox(width: HomeResponsive.w(context, 3)),
          Text(
            'Online',
            style: GoogleFonts.poppins(
              fontSize: HomeResponsive.w(context, 8),
              fontWeight: FontWeight.w600,
              color: HomeTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleCallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = HomeResponsive.w(context, 30);
    return ScalePressedButton(
      onTap: onTap,
      pressedScale: 0.92,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: HomeTheme.primary,
          shape: BoxShape.circle,
          boxShadow: HomeTheme.softShadow,
        ),
        child: Icon(icon, color: Colors.white, size: HomeResponsive.w(context, 14)),
      ),
    );
  }
}
