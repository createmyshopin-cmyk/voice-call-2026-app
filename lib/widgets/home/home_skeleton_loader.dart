import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/home_theme.dart';
import '../../utils/home_responsive.dart';

class HomeSkeletonLoader extends StatelessWidget {
  final bool contentOnly;

  const HomeSkeletonLoader({super.key, this.contentOnly = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (!contentOnly) ...[
            const _HeaderSkeleton(),
            SizedBox(height: HomeResponsive.w(context, 8)),
            _WalletSkeleton(),
            SizedBox(height: 24),
          ],
          _SectionTitleSkeleton(),
          SizedBox(height: 12),
          _FeaturedSkeleton(),
          SizedBox(height: 24),
          _SectionTitleSkeleton(),
          SizedBox(height: 12),
          _OnlineGridSkeleton(),
          SizedBox(height: 24),
          _SectionTitleSkeleton(),
          SizedBox(height: 12),
          _TopRatedSkeleton(),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: HomeTheme.card,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: HomeResponsive.w(context, 16),
        left: HomeResponsive.w(context, 20),
        right: HomeResponsive.w(context, 20),
      ),
      child: SizedBox(
        height: HomeResponsive.w(context, 72),
        child: Row(
          children: [
            _Bone(
              width: HomeResponsive.w(context, 48),
              height: HomeResponsive.w(context, 48),
              radius: HomeResponsive.w(context, 24),
            ),
            SizedBox(width: HomeResponsive.w(context, 12)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(
                    width: HomeResponsive.w(context, 160),
                    height: HomeResponsive.w(context, 24),
                    radius: 8,
                  ),
                  SizedBox(height: HomeResponsive.w(context, 4)),
                  _Bone(
                    width: HomeResponsive.w(context, 200),
                    height: HomeResponsive.w(context, 15),
                    radius: 6,
                  ),
                ],
              ),
            ),
            _Bone(
              width: HomeResponsive.w(context, 44),
              height: HomeResponsive.w(context, 44),
              radius: HomeResponsive.w(context, 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: HomeResponsive.w(context, 20)),
      child: _Bone(
        width: double.infinity,
        height: HomeResponsive.w(context, 160),
        radius: HomeResponsive.w(context, 28),
      ),
    );
  }
}

class _SectionTitleSkeleton extends StatelessWidget {
  const _SectionTitleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _Bone(width: 140, height: 18, radius: 8),
          _Bone(width: 60, height: 14, radius: 6),
        ],
      ),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    final w = HomeResponsive.w(context, 240);
    final h = HomeResponsive.w(context, 320);
    return SizedBox(
      height: h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: HomeResponsive.w(context, 20)),
        children: [
          _Bone(width: w, height: h, radius: HomeResponsive.w(context, 24)),
          SizedBox(width: HomeResponsive.w(context, 12)),
          _Bone(width: w, height: h, radius: HomeResponsive.w(context, 24)),
        ],
      ),
    );
  }
}

class _OnlineGridSkeleton extends StatelessWidget {
  const _OnlineGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: const [
          Expanded(child: _Bone(width: double.infinity, height: 180, radius: 16)),
          SizedBox(width: 12),
          Expanded(child: _Bone(width: double.infinity, height: 180, radius: 16)),
        ],
      ),
    );
  }
}

class _TopRatedSkeleton extends StatelessWidget {
  const _TopRatedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [
          _Bone(width: 300, height: 90, radius: 18),
          SizedBox(width: 12),
          _Bone(width: 300, height: 90, radius: 18),
        ],
      ),
    );
  }
}
