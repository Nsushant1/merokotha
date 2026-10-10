import 'package:flutter/material.dart';

/// Responsive helpers — one set of breakpoints used app-wide.
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
}
