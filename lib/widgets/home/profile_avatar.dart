import 'package:flutter/material.dart';

import '../../utils/home_responsive.dart';
import 'creator_avatar_image.dart';

/// Header profile avatar — 48×48 circle, white border, soft shadow.
class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double designSize;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.designSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final size = HomeResponsive.w(context, designSize);
    final borderWidth = HomeResponsive.w(context, 2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: HomeResponsive.w(context, 8),
            offset: Offset(0, HomeResponsive.w(context, 2)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CreatorAvatarImage(
        imageUrl: imageUrl,
        size: size,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}
