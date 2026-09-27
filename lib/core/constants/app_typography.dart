import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';

/// Standardized type scale — modern, clean, bold.
///
/// Rules:
/// - Integer font sizes only (no 13.5 / 14.5 / 11.5 fractions).
/// - Headings are bold (w700/w800) with tight letter-spacing.
/// - Body uses generous line-height (1.5) and secondary text color.
/// - Captions/labels use w600 with slight tracking for legibility.
class AppTypography {
  AppTypography._();

  // Display — hero numbers / splash only
  static const displayLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.15,
    color: AppColors.grey900,
  );
  static const displayMd = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.2,
    color: AppColors.grey900,
  );

  // Headline — screen titles
  static const headlineLg = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.grey900,
  );
  static const headlineMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.3,
    color: AppColors.grey900,
  );
  static const headlineSm = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.grey900,
  );

  // Title — card / section headings
  static const titleLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.35,
    color: AppColors.grey900,
  );
  static const titleMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppColors.grey900,
  );
  static const titleSm = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.grey900,
  );

  // Body — content text
  static const bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.grey800,
  );
  static const bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.grey600,
  );
  static const bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.grey600,
  );

  // Label / caption — metadata, badges, eyebrows
  static const labelLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.grey900,
  );
  static const labelMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.grey600,
  );
  static const labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.grey600,
  );
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.grey400,
  );
  static const overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.primary,
  );

  // Buttons / inputs
  static const buttonLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
  );
  static const buttonMd = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.2,
  );
  static const buttonSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );
  static const input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.grey900,
  );
  static const inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.grey900,
  );
  static const inputHint = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.grey400,
  );
}
