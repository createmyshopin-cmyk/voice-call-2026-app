import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/home_theme.dart';
import '../../models/creator.dart';
import '../../utils/home_responsive.dart';
import 'creator_avatar_image.dart';
import 'presence_status_badge.dart';
import 'scale_pressed_button.dart';

/// Compact full-width listener row — matches reference list sections.
class ListenerListRowCard extends StatefulWidget {
  final Creator creator;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  const ListenerListRowCard({
    super.key,
    required this.creator,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  static double rowHeight(BuildContext context) => HomeResponsive.w(context, 124);

  @override
  State<ListenerListRowCard> createState() => _ListenerListRowCardState();
}

class _ListenerListRowCardState extends State<ListenerListRowCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    final avatar = HomeResponsive.w(context, 72);
    final radius = HomeResponsive.w(context, 16);
    final rowH = ListenerListRowCard.rowHeight(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(marginH, 0, marginH, HomeResponsive.w(context, 12)),
      child: ScalePressedButton(
        onTap: widget.onTap,
        pressedScale: 0.99,
        child: SizedBox(
          height: rowH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: rowH,
                padding: EdgeInsets.all(HomeResponsive.w(context, 10)),
                decoration: BoxDecoration(
                  color: HomeTheme.card,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: HomeTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CreatorAvatarImage(
                          imageUrl: creator.avatar,
                          size: avatar,
                          borderRadius: BorderRadius.circular(HomeResponsive.w(context, 14)),
                        ),
                        Positioned(
                          top: HomeResponsive.w(context, 4),
                          left: HomeResponsive.w(context, 4),
                          child: PresenceStatusBadge(
                            isOnline: creator.isOnline,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: HomeResponsive.w(context, 10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  creator.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: HomeResponsive.w(context, 15),
                                    fontWeight: FontWeight.w700,
                                    color: HomeTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.verified_rounded,
                                color: HomeTheme.primary,
                                size: HomeResponsive.w(context, 16),
                              ),
                            ],
                          ),
                          Text(
                            creator.languagesLabelBullet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: HomeResponsive.w(context, 12),
                              color: HomeTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: HomeResponsive.w(context, 2)),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: HomeTheme.starYellow,
                                size: HomeResponsive.w(context, 13),
                              ),
                              SizedBox(width: HomeResponsive.w(context, 3)),
                              Flexible(
                                child: Text(
                                  creator.rating > 0
                                      ? '${creator.rating.toStringAsFixed(1)} (${_reviewsLabel(creator.totalCalls)})'
                                      : 'New listener',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: HomeResponsive.w(context, 11),
                                    color: HomeTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (creator.responseRate != null && creator.responseRate! > 0)
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: HomeTheme.onlineGreen,
                                  size: HomeResponsive.w(context, 12),
                                ),
                                SizedBox(width: HomeResponsive.w(context, 3)),
                                Text(
                                  '${creator.responseRate!.round()}% Response Rate',
                                  style: GoogleFonts.poppins(
                                    fontSize: HomeResponsive.w(context, 11),
                                    color: HomeTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: HomeResponsive.w(context, 4)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RateLine(
                          rate: creator.ratePerMinute,
                          label: 'Voice Call',
                        ),
                        SizedBox(height: HomeResponsive.w(context, 2)),
                        _RateLine(
                          rate: creator.videoRatePerMinute,
                          label: 'Video Call',
                        ),
                      ],
                    ),
                    SizedBox(width: HomeResponsive.w(context, 8)),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircleActionButton(
                          icon: Icons.phone_rounded,
                          enabled: creator.isOnline,
                          onTap: widget.onVoiceCall,
                        ),
                        SizedBox(height: HomeResponsive.w(context, 6)),
                        _CircleActionButton(
                          icon: Icons.videocam_rounded,
                          enabled: creator.isOnline,
                          onTap: widget.onVideoCall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: HomeResponsive.w(context, 8),
                right: HomeResponsive.w(context, 8),
                child: ScalePressedButton(
                  onTap: widget.onFavoriteToggle,
                  pressedScale: 0.9,
                  child: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: HomeTheme.primary,
                    size: HomeResponsive.w(context, 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateLine extends StatelessWidget {
  final int rate;
  final String label;

  const _RateLine({required this.rate, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      '₹$rate/min $label',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: HomeResponsive.w(context, 10),
        fontWeight: FontWeight.w600,
        color: HomeTheme.primary,
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = HomeResponsive.w(context, 34);
    final child = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: enabled ? HomeTheme.primary : const Color(0xFF9CA3AF),
        shape: BoxShape.circle,
        boxShadow: enabled ? HomeTheme.softShadow : null,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: HomeResponsive.w(context, 16),
      ),
    );

    if (!enabled) return Opacity(opacity: 0.5, child: child);
    return ScalePressedButton(
      onTap: onTap,
      pressedScale: 0.92,
      child: child,
    );
  }
}
