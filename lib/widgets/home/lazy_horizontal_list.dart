import 'package:flutter/material.dart';

import '../../utils/home_responsive.dart';

/// Lazily builds horizontal list items; expands via [onNearEnd] when scrolled.
class LazyHorizontalList extends StatefulWidget {
  final double height;
  final int itemCount;
  final double horizontalPadding;
  final double itemSpacing;
  final VoidCallback? onNearEnd;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const LazyHorizontalList({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.horizontalPadding = 20,
    this.itemSpacing = 12,
    this.onNearEnd,
  });

  @override
  State<LazyHorizontalList> createState() => _LazyHorizontalListState();
}

class _LazyHorizontalListState extends State<LazyHorizontalList> {
  bool _nearEndTriggered = false;

  @override
  void didUpdateWidget(covariant LazyHorizontalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _nearEndTriggered = false;
    }
  }

  bool _handleScroll(ScrollNotification notification) {
    if (widget.onNearEnd == null || _nearEndTriggered) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    final metrics = notification.metrics;
    if (metrics.maxScrollExtent <= 0) return false;
    if (metrics.pixels >= metrics.maxScrollExtent - 120) {
      _nearEndTriggered = true;
      widget.onNearEnd!();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nearEndTriggered = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return SizedBox(height: widget.height);

    final pad = HomeResponsive.w(context, widget.horizontalPadding);
    final gap = HomeResponsive.w(context, widget.itemSpacing);

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: pad),
          cacheExtent: HomeResponsive.w(context, 320),
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => SizedBox(width: gap),
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child: widget.itemBuilder(context, index),
            );
          },
        ),
      ),
    );
  }
}
