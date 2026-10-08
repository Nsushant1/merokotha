import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/constants/app_typography.dart';

/// Landing visual tokens — now a thin alias over the app-wide design
/// system so public browse screens share one font, one palette, and one
/// type scale with the rest of the app. Kept as a facade so existing
/// call sites keep working unchanged.
class LandingTheme {
  // Brand — single AP green identity.
  static const accent = AppColors.primary;
  static const accentMuted = AppColors.primaryDark;

  // Backgrounds — standardized surfaces.
  static const bg = AppColors.background;
  static const bgWarm = AppColors.backgroundSecondary;
  static const surface = AppColors.background;

  // Neutrals / text — standardized ramp.
  static const ink = AppColors.grey900;
  static const stone = AppColors.grey600;
  static const hairline = AppColors.border;

  // Semantic
  static const error = AppColors.error;

  // Eyebrow label: 11px bold, tracked, brand.
  static TextStyle get labelSm => AppTypography.overline;

  // Secondary body: 14px, comfortable measure.
  static TextStyle get bodyMd => AppTypography.bodyMd;

  // Listing price: 16px extra-bold, tight.
  static TextStyle get priceLg => AppTypography.titleMd;

  // Listing title: 15px semibold.
  static TextStyle get titleMd => AppTypography.titleSm;

  static const double r = AppSizes.radiusLg;

  static String formatPrice(num v) => v.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}
