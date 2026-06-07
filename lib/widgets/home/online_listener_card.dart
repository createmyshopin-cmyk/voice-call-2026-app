import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import '../../models/creator.dart';
import '../../utils/home_responsive.dart';
import 'coin_icon.dart';
import 'creator_avatar_image.dart';
import 'pulsing_online_dot.dart';
import 'scale_pressed_button.dart';

class OnlineListenerCard extends StatefulWidget {
  final Creator creator;
  final VoidCallback onTap;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final double cardWidth;

  const OnlineListenerCard({
    super.key,
    required this.creator,
    required this.onTap,
    required this.onVoiceCall,
    required this.onVideoCall,
    this.cardWidth = 165,
  });

  @override
  State<OnlineListenerCard> createState() => _OnlineListenerCardState();
}

class _OnlineListenerCardState extends State<OnlineListenerCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final creator = widget.creator;
    final w = HomeResponsive.w(context, widget.cardWidth);
    final img = HomeResponsive.w(context, 64);

    return ScalePressedButton(
      onTap: widget.onTap,
      pressedScale: 0.98,
      child: Container(
        width: w,
        padding: EdgeInsets.all(HomeResponsive.w(context, 10)),
        decoration: BoxDecoration(
          color: HomeTheme.card,
          borderRadius: BorderRadius.circular(HomeResponsive.w(context, 16)),
          boxShadow: HomeTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CreatorAvatarImage(
                  imageUrl: creator.avatar,
                  size: img,
                  borderRadius: BorderRadius.circular(HomeResponsive.w(context, 12)),
                ),
                if (creator.isOnline)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: PulsingOnlineDot(size: HomeResponsive.w(context, 9)),
                  ),
              ],
            ),
            SizedBox(height: HomeResponsive.w(context, 6)),
            Text(
              creator.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: HomeResponsive.w(context, 13),
                fontWeight: FontWeight.w600,
                color: HomeTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: HomeTheme.starYellow,
                  size: HomeResponsive.w(context, 13),
                ),
                SizedBox(width: HomeResponsive.w(context, 2)),
                Text(
                  creator.rating > 0 ? creator.rating.toStringAsFixed(1) : '—',
                  style: GoogleFonts.poppins(
                    fontSize: HomeResponsive.w(context, 11),
                    color: HomeTheme.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: HomeResponsive.w(context, 6)),
            Row(
              children: [
                Expanded(
                  child: _MiniRateButton(
                    icon: Icons.phone_rounded,
                    rate: creator.ratePerMinute,
                    enabled: creator.isOnline,
                    onTap: widget.onVoiceCall,
                  ),
                ),
                SizedBox(width: HomeResponsive.w(context, 5)),
                Expanded(
                  child: _MiniRateButton(
                    icon: Icons.videocam_rounded,
                    rate: creator.videoRatePerMinute,
                    enabled: creator.isOnline,
                    onTap: widget.onVideoCall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRateButton extends StatelessWidget {
  final IconData icon;
  final int rate;
  final bool enabled;
  final VoidCallback onTap;

  const _MiniRateButton({
    required this.icon,
    required this.rate,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: HomeResponsive.w(context, 26),
      decoration: BoxDecoration(
        color: HomeTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HomeResponsive.w(context, 8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: HomeResponsive.w(context, 11), color: HomeTheme.primary),
          CoinIcon(size: HomeResponsive.w(context, 9)),
          Text(
            '$rate',
            style: GoogleFonts.poppins(
              fontSize: HomeResponsive.w(context, 9),
              fontWeight: FontWeight.w600,
              color: HomeTheme.primary,
            ),
          ),
        ],
      ),
    );

    if (!enabled) return Opacity(opacity: 0.45, child: child);
    return ScalePressedButton(
      onTap: onTap,
      pressedScale: 0.96,
      child: child,
    );
  }
}
