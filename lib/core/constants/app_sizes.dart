import 'package:flutter/material.dart';

class AppSizes {
  AppSizes._();

  // Spacing — standardized 4pt scale. Prefer these over ad-hoc numbers.
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // Common gaps (aliases into the scale above for readability)
  static const gapXs = 4.0;
  static const gapSm = 8.0;
  static const gapMd = 12.0;
  static const gapLg = 16.0;
  static const gapXl = 24.0;
  static const sectionGap = 28.0;

  // Border radius — modern, bold, consistent.
  static const radiusXs = 6.0;
  static const radiusSm = 8.0;
  static const radiusMd = 14.0;
  static const radiusLg = 20.0;
  static const radiusXl = 28.0;
  static const radiusFull = 999.0;

  // Shadows — soft, realistic, low-elevation (premium look, no harsh drop shadows)
  static const shadowCard = [
    BoxShadow(color: Color(0x0F1A1A18), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static const shadowRaised = [
    BoxShadow(color: Color(0x141A1A18), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const shadowButton = [
    BoxShadow(color: Color(0x2B1D9E75), blurRadius: 16, offset: Offset(0, 6)),
  ];

  // Icon sizes
  static const iconXs = 14.0;
  static const iconSm = 16.0;
  static const iconMd = 20.0;
  static const iconLg = 24.0;
  static const iconXl = 32.0;

  // Component heights — standardized tap targets + inputs
  static const buttonHeightSm = 44.0;
  static const buttonHeight = 54.0;
  static const buttonHeightLg = 58.0;
  static const inputHeight = 54.0;
  static const appBarHeight = 60.0;
  static const bottomNavHeight = 68.0;
  static const listingCardHeight = 220.0;
  static const tapTargetMin = 44.0;

  // Padding — page + card rhythm used app-wide
  static const pagePadding = 20.0;
  static const pagePaddingLarge = 24.0;
  static const cardPadding = 16.0;
  static const cardPaddingLarge = 20.0;

  // Avatar
  static const avatarSm = 32.0;
  static const avatarMd = 44.0;
  static const avatarLg = 64.0;
  static const avatarXl = 88.0;
}
