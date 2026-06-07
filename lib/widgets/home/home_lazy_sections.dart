import 'package:flutter/material.dart';

/// Tracks how many items to render per home section (client-side lazy batches).
class HomeLazySections extends ChangeNotifier {
  static const int featuredBatch = 4;
  static const int onlineBatch = 4;
  static const int topRatedBatch = 3;
  static const int recentBatch = 6;

  int featuredVisible = featuredBatch;
  int onlineVisible = onlineBatch;
  int topRatedVisible = topRatedBatch;
  int recentVisible = recentBatch;

  void reset() {
    featuredVisible = featuredBatch;
    onlineVisible = onlineBatch;
    topRatedVisible = topRatedBatch;
    recentVisible = recentBatch;
    notifyListeners();
  }

  void syncTotals({
    required int featuredTotal,
    required int onlineTotal,
    required int topRatedTotal,
    required int recentTotal,
  }) {
    featuredVisible = featuredVisible.clamp(0, featuredTotal);
    onlineVisible = onlineVisible.clamp(0, onlineTotal);
    topRatedVisible = topRatedVisible.clamp(0, topRatedTotal);
    recentVisible = recentVisible.clamp(0, recentTotal);
  }

  void loadMoreFeatured(int total) {
    if (featuredVisible >= total) return;
    featuredVisible = (featuredVisible + featuredBatch).clamp(0, total);
    notifyListeners();
  }

  void loadMoreOnline(int total) {
    if (onlineVisible >= total) return;
    onlineVisible = (onlineVisible + onlineBatch).clamp(0, total);
    notifyListeners();
  }

  void loadMoreTopRated(int total) {
    if (topRatedVisible >= total) return;
    topRatedVisible = (topRatedVisible + topRatedBatch).clamp(0, total);
    notifyListeners();
  }

  void loadMoreRecent(int total) {
    if (recentVisible >= total) return;
    recentVisible = (recentVisible + recentBatch).clamp(0, total);
    notifyListeners();
  }
}

/// Defers building [child] until the section scrolls into the viewport.
class HomeLazyViewportSection extends StatelessWidget {
  final double estimatedExtent;
  final Widget child;

  const HomeLazyViewportSection({
    super.key,
    required this.estimatedExtent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final inView =
            constraints.overlap > 0 || constraints.remainingPaintExtent > 0;
        if (!inView) {
          return SliverToBoxAdapter(
            child: SizedBox(height: estimatedExtent),
          );
        }
        return SliverToBoxAdapter(child: child);
      },
    );
  }
}
