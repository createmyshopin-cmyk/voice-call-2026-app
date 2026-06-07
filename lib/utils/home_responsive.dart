import 'package:flutter/material.dart';

/// iPhone 15 Pro reference width (390 logical px).
abstract final class HomeResponsive {
  static const double designWidth = 390;

  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / designWidth).clamp(0.85, 1.15);
  }

  static double w(BuildContext context, double designPx) {
    return designPx * MediaQuery.sizeOf(context).width / designWidth;
  }

  static EdgeInsets pagePadding(BuildContext context, {double horizontal = 20}) {
    return EdgeInsets.symmetric(horizontal: w(context, horizontal));
  }

  static double sectionGap(BuildContext context) => w(context, 16);

  static double bottomNavClearance(BuildContext context) => w(context, 88);

  static double bottomNavHeight(BuildContext context) => w(context, 76);

  static double promoBannerHeight(BuildContext context) => w(context, 92);

  /// Bottom nav + gap + promo banner (sticky stack on Home / Calls / Wallet).
  static double stickyPromoClearance(BuildContext context) =>
      bottomNavHeight(context) + w(context, 8) + promoBannerHeight(context);
}
