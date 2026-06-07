import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/home_theme.dart';

/// Reusable shimmer placeholder block.
class ShimmerBone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBone({
    super.key,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps [child] in the standard app shimmer effect.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: HomeTheme.background,
      child: child,
    );
  }
}

/// Generic list skeleton for transaction/history loading states.
class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => ShimmerBone(
          width: double.infinity,
          height: itemHeight,
          radius: 16,
        ),
      ),
    );
  }
}

/// Horizontal card row skeleton (e.g. recharge packages).
class HorizontalCardsSkeleton extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;

  const HorizontalCardsSkeleton({
    super.key,
    this.cardWidth = 140,
    this.cardHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => ShimmerBone(
            width: cardWidth,
            height: cardHeight,
            radius: 20,
          ),
        ),
      ),
    );
  }
}

/// Branded splash while auth session restores.
class AuthInitSkeleton extends StatelessWidget {
  const AuthInitSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeTheme.background,
      body: Center(
        child: AppShimmer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ShimmerBone(width: 80, height: 80, radius: 40),
              SizedBox(height: 24),
              ShimmerBone(width: 200, height: 20, radius: 10),
              SizedBox(height: 12),
              ShimmerBone(width: 140, height: 14, radius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
