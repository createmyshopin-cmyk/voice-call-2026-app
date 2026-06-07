import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import '../../models/creator.dart';
import '../../utils/home_responsive.dart';
import 'creator_avatar_image.dart';
import 'pulsing_online_dot.dart';
import 'scale_pressed_button.dart';

class RecentJoinedAvatar extends StatelessWidget {
  final Creator creator;
  final VoidCallback onTap;

  const RecentJoinedAvatar({
    super.key,
    required this.creator,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = HomeResponsive.w(context, 52);
    final itemW = HomeResponsive.w(context, 68);

    return ScalePressedButton(
      onTap: onTap,
      pressedScale: 0.95,
      child: SizedBox(
        width: itemW,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(HomeResponsive.w(context, 2)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: HomeTheme.primary,
                      width: HomeResponsive.w(context, 2),
                    ),
                  ),
                  child: CreatorAvatarImage(imageUrl: creator.avatar, size: size),
                ),
                if (creator.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(HomeResponsive.w(context, 2)),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: PulsingOnlineDot(size: HomeResponsive.w(context, 9)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: HomeResponsive.w(context, 5)),
            Text(
              creator.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: HomeResponsive.w(context, 11),
                fontWeight: FontWeight.w500,
                color: HomeTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
