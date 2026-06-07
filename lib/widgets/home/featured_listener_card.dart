import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/home_theme.dart';
import '../../models/creator.dart';
import '../../utils/home_responsive.dart';
import 'creator_avatar_image.dart';
import 'presence_status_badge.dart';
import 'scale_pressed_button.dart';

/// Full-width featured listener card — image left, details right (reference layout).
class FeaturedListenerCard extends StatefulWidget {
  final Creator creator;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final VoidCallback? onTap;

  const FeaturedListenerCard({
    super.key,
    required this.creator,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onVoiceCall,
    required this.onVideoCall,
    this.onTap,
  });

  static double cardHeight(BuildContext context) => HomeResponsive.w(context, 200);

  @override
  State<FeaturedListenerCard> createState() => _FeaturedListenerCardState();
}

class _FeaturedListenerCardState extends State<FeaturedListenerCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    _heartController.forward().then((_) => _heartController.reverse());
    widget.onFavoriteToggle();
  }

  String _reviewsLabel(int count) {
    if (count <= 0) return 'New';
    final formatted = NumberFormat.decimalPattern().format(count);
    return '$formatted Reviews';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final creator = widget.creator;
    final marginH = HomeResponsive.w(context, 20);
    final h = FeaturedListenerCard.cardHeight(context);
    final radius = HomeResponsive.w(context, 20);
    final imageW = HomeResponsive.w(context, 140);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: marginH),
      child: SizedBox(
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                height: h,
                decoration: BoxDecoration(
                  color: HomeTheme.card,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: HomeTheme.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    SizedBox(
                      width: imageW,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CreatorAvatarImage(
                            imageUrl: creator.avatar,
                            size: imageW,
                            width: imageW,
                            height: h,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.zero,
                          ),
                          Positioned(
                            top: HomeResponsive.w(context, 10),
                            left: HomeResponsive.w(context, 10),
                            child: PresenceStatusBadge(isOnline: creator.isOnline),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          HomeResponsive.w(context, 12),
                          HomeResponsive.w(context, 12),
                          HomeResponsive.w(context, 36),
                          HomeResponsive.w(context, 12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    creator.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: HomeResponsive.w(context, 17),
                                      fontWeight: FontWeight.w700,
                                      color: HomeTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.verified_rounded,
                                  color: HomeTheme.primary,
                                  size: HomeResponsive.w(context, 18),
                                ),
                              ],
                            ),
                            SizedBox(height: HomeResponsive.w(context, 2)),
                            Text(
                              creator.languagesLabelBullet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: HomeResponsive.w(context, 13),
                                color: HomeTheme.textSecondary,
                              ),
                            ),
                            SizedBox(height: HomeResponsive.w(context, 6)),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: HomeTheme.starYellow,
                                  size: HomeResponsive.w(context, 15),
                                ),
                                SizedBox(width: HomeResponsive.w(context, 4)),
                                Flexible(
                                  child: Text(
                                    creator.rating > 0
                                        ? '${creator.rating.toStringAsFixed(1)} (${_reviewsLabel(creator.totalCalls)})'
                                        : 'New listener',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: HomeResponsive.w(context, 12),
                                      color: HomeTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (creator.responseRate != null && creator.responseRate! > 0) ...[
                              SizedBox(height: HomeResponsive.w(context, 2)),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    color: HomeTheme.onlineGreen,
                                    size: HomeResponsive.w(context, 14),
                                  ),
                                  SizedBox(width: HomeResponsive.w(context, 4)),
                                  Text(
                                    '${creator.responseRate!.round()}% Response Rate',
                                    style: GoogleFonts.poppins(
                                      fontSize: HomeResponsive.w(context, 12),
                                      color: HomeTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: _OutlinedRateButton(
                                    icon: Icons.phone_rounded,
                                    rate: creator.ratePerMinute,
                                    label: creator.isOnline ? 'Voice Call' : 'Listener Offline',
                                    enabled: creator.isOnline && creator.isVoiceAvailable,
                                    onTap: widget.onVoiceCall,
                                  ),
                                ),
                                SizedBox(width: HomeResponsive.w(context, 8)),
                                Expanded(
                                  child: _OutlinedRateButton(
                                    icon: Icons.videocam_rounded,
                                    rate: creator.videoRatePerMinute,
                                    label: creator.isOnline ? 'Video Call' : 'Listener Offline',
                                    enabled: creator.isOnline && creator.isVoiceAvailable,
                                    onTap: widget.onVideoCall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: HomeResponsive.w(context, 10),
              right: HomeResponsive.w(context, 10),
              child: ScalePressedButton(
                onTap: _toggleFavorite,
                pressedScale: 0.92,
                child: ScaleTransition(
                  scale: _heartScale,
                  child: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: HomeTheme.primary,
                    size: HomeResponsive.w(context, 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedRateButton extends StatelessWidget {
  final IconData icon;
  final int rate;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _OutlinedRateButton({
    required this.icon,
    required this.rate,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: HomeResponsive.w(context, 36),
      padding: EdgeInsets.symmetric(horizontal: HomeResponsive.w(context, 6)),
      decoration: BoxDecoration(
        color: HomeTheme.rateButtonBg,
        borderRadius: BorderRadius.circular(HomeResponsive.w(context, 12)),
        border: Border.all(color: HomeTheme.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: HomeResponsive.w(context, 14), color: HomeTheme.primary),
          SizedBox(width: HomeResponsive.w(context, 4)),
          Flexible(
            child: Text(
              '₹$rate/min $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: HomeResponsive.w(context, 10),
                fontWeight: FontWeight.w600,
                color: HomeTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (!enabled) return Opacity(opacity: 0.45, child: child);
    return ScalePressedButton(onTap: onTap, pressedScale: 0.96, child: child);
  }
}
