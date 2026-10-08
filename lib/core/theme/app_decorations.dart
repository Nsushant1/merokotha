import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Single source of truth for surfaces: cards, inputs, chips, sheets.
///
/// Every screen must compose from these instead of hand-rolling
/// BoxDecorations, so borders / radii / shadows stay identical across
/// mobile, tablet, and desktop.
class AppDecorations {
  AppDecorations._();

  /// Primary content card: white, 20px radius, hairline border, soft shadow.
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: AppSizes.shadowCard,
  );

  /// Flat card: same shape, no shadow (nested / dense contexts).
  static BoxDecoration get cardFlat => BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    border: Border.all(color: AppColors.border, width: 1),
  );

  /// Tinted section container (headers, icon wells, empty states).
  static BoxDecoration get tinted => BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    border: Border.all(color: AppColors.border, width: 1),
  );

  /// Brand tint container (selected states, avatar fallbacks, highlights).
  /// Blue tint by default; use [accentTint] for red highlight contexts
  /// (selected filter chips, For Sale badges, price wells).
  static BoxDecoration brandTint([Color? border]) => BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    border: Border.all(
      color: border ?? AppColors.primary.withValues(alpha: 0.25),
      width: 1,
    ),
  );

  static BoxDecoration get accentTint => BoxDecoration(
    color: AppColors.accentLight,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    border: Border.all(
      color: AppColors.accent.withValues(alpha: 0.25),
      width: 1,
    ),
  );

  /// Pill (chips, badges, toggles).
  static BoxDecoration pill({Color? color, Color? border}) => BoxDecoration(
    color: color ?? AppColors.background,
    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    border: Border.all(color: border ?? AppColors.border, width: 1),
  );

  /// Selected pill — brand Red to match design reference
  /// (All / House / 3+ active filter states).
  static BoxDecoration get pillSelected => BoxDecoration(
    color: AppColors.accent,
    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    border: Border.all(color: AppColors.accent, width: 1),
    boxShadow: const [
      BoxShadow(color: Color(0x33FF1F2D), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  /// Image placeholder well.
  static BoxDecoration get mediaPlaceholder => BoxDecoration(
    color: AppColors.surfaceContainer,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
  );

  /// Bottom sheet / dialog surface.
  static BoxDecoration get sheet => BoxDecoration(
    color: AppColors.background,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(AppSizes.radiusXl),
    ),
    boxShadow: AppSizes.shadowRaised,
  );

  /// Header band: white surface with hairline bottom border.
  static BoxDecoration get headerBand => const BoxDecoration(
    color: AppColors.background,
    border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
  );

  /// Icon well: 40px rounded container for leading icons.
  /// Dark-blue icon on light-blue well (see profile menu rows).
  static BoxDecoration iconWell({Color? color}) => BoxDecoration(
    color: color ?? AppColors.primaryLight,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    border: Border.all(color: AppColors.border, width: 1),
  );

  /// Blue gradient header band (top bars, profile header).
  static BoxDecoration get brandHeader =>
      const BoxDecoration(gradient: AppColors.brandGradient);

  /// Promo hero banner (blue → red wash like design.jpeg Explore card).
  static BoxDecoration get promoBanner => BoxDecoration(
    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    gradient: const LinearGradient(
      colors: [Color(0xFF0757B8), Color(0xFF0A2F63), Color(0xFFD91424)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x260757B8), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );

  /// For Sale badge — solid brand red.
  static BoxDecoration get forSaleBadge => BoxDecoration(
    color: AppColors.accent,
    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
  );

  /// For Rent badge — solid brand blue.
  static BoxDecoration get forRentBadge => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
  );
}
