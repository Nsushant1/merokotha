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
    color: AppColors.grey50,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    border: Border.all(color: AppColors.border, width: 1),
  );

  /// Brand tint container (selected states, avatar fallbacks, highlights).
  static BoxDecoration brandTint([Color? border]) => BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    border: Border.all(
      color: border ?? AppColors.primary.withValues(alpha: 0.22),
      width: 1,
    ),
  );

  /// Pill (chips, badges, toggles).
  static BoxDecoration pill({Color? color, Color? border}) => BoxDecoration(
    color: color ?? AppColors.background,
    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    border: Border.all(color: border ?? AppColors.border, width: 1),
  );

  /// Selected pill.
  static BoxDecoration get pillSelected => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    border: Border.all(color: AppColors.primary, width: 1),
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
  static BoxDecoration iconWell({Color? color}) => BoxDecoration(
    color: color ?? AppColors.grey50,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    border: Border.all(color: AppColors.border, width: 1),
  );
}
