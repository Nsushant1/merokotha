import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Responsive helpers — one set of breakpoints used app-wide.
///
/// - Mobile: < 600px — single column, 20px page padding.
/// - Tablet: 600–1024px — 2-column grids, 24px padding, 720px max width.
/// - Desktop: > 1024px — 3-column grids, 24px padding, 1080px max width.
class MkBreakpoints {
  MkBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet &&
      MediaQuery.sizeOf(context).width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  /// Grid columns for listing feeds: 1 / 2 / 3.
  static int listingColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktop) return 3;
    if (w >= tablet) return 2;
    return 1;
  }

  /// Content max width for centered layouts.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktop) return 1080;
    if (w >= tablet) return 720;
    return double.infinity;
  }

  /// Page padding responsive to breakpoint.
  static double pagePadding(BuildContext context) =>
      isMobile(context) ? AppSizes.pagePadding : AppSizes.pagePaddingLarge;
}
