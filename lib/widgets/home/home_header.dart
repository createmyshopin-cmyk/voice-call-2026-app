import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/avatar_assets.dart';
import '../../constants/home_theme.dart';
import '../../utils/home_responsive.dart';
import 'home_animations.dart';
import 'profile_avatar.dart';
import 'scale_pressed_button.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.unreadCount = 0,
    this.onAvatarTap,
    this.onNotificationTap,
  });

  String _resolveAvatar() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) return avatarUrl!;
    return AvatarAssets.defaultAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().isEmpty ? 'there' : userName.trim();

    final marginTop = HomeResponsive.w(context, 16);
    final headerHeight = HomeResponsive.w(context, 72);
    final horizontalPadding = HomeResponsive.w(context, 20);
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.only(top: marginTop),
        child: SizedBox(
          height: headerHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                ScalePressedButton(
                  pressedScale: 0.95,
                  onTap: onAvatarTap ?? () {},
                  child: ProfileAvatar(imageUrl: _resolveAvatar()),
                ),
                SizedBox(width: HomeResponsive.w(context, 12)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi $displayName 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: HomeResponsive.w(context, 24),
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Ready to connect today?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: HomeResponsive.w(context, 15),
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: HomeTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ScalePressedButton(
                  onTap: onNotificationTap ?? () {},
                  child: SizedBox(
                    width: HomeResponsive.w(context, 44),
                    height: HomeResponsive.w(context, 44),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: HomeResponsive.w(context, 44),
                          height: HomeResponsive.w(context, 44),
                          decoration: BoxDecoration(
                            color: HomeTheme.screenBackground,
                            borderRadius: BorderRadius.circular(
                              HomeResponsive.w(context, 22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: HomeResponsive.w(context, 8),
                                offset: Offset(0, HomeResponsive.w(context, 2)),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: HomeTheme.textPrimary,
                            size: HomeResponsive.w(context, 24),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -HomeResponsive.w(context, 2),
                            right: -HomeResponsive.w(context, 2),
                            child: _NotificationBadge(count: unreadCount),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatefulWidget {
  final int count;

  const _NotificationBadge({required this.count});

  @override
  State<_NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<_NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.count > 9 ? '9+' : '${widget.count}';
    final badgeSize = HomeResponsive.w(context, 20);
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: HomeTheme.primary,
          borderRadius: BorderRadius.circular(HomeResponsive.w(context, 10)),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: HomeResponsive.w(context, 12),
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
