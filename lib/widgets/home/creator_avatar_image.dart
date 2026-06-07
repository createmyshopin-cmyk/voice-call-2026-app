import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../constants/avatar_assets.dart';

/// Network or local asset avatar with caching and placeholder.
class CreatorAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CreatorAvatarImage({
    super.key,
    required this.imageUrl,
    required this.size,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    final placeholder = Container(
      width: w,
      height: h,
      color: const Color(0xFFF3F4F6),
      child: Icon(Icons.person, size: size * 0.45, color: const Color(0xFF9CA3AF)),
    );

    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          imageUrl,
          width: w,
          height: h,
          fit: fit,
          errorBuilder: (_, __, ___) => Image.asset(
            AvatarAssets.defaultAvatar,
            width: w,
            height: h,
            fit: fit,
          ),
        ),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memW = (w * dpr).round();
    final memH = (h * dpr).round();

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: w,
        height: h,
        fit: fit,
        memCacheWidth: memW,
        memCacheHeight: memH,
        fadeInDuration: const Duration(milliseconds: 220),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}
