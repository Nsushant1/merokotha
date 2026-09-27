import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF1D9E75);
  static const primaryDark = Color(0xFF0F6E56);
  static const primaryLight = Color(0xFFE1F5EE);

  static const secondary = Color(0xFF534AB7);
  static const secondaryLight = Color(0xFFEEEDFE);

  // Neutrals (warm-neutral ramp, standardized for hierarchy + contrast).
  // grey900 / grey800 are unchanged; grey600/400 are slightly darkened
  // vs. legacy values so secondary text passes contrast on white.
  static const grey50 = Color(0xFFF1EFEA); // Subtle tinted surface
  static const grey100 = Color(0xFFE8E6E1); // Hairline / pressed surface
  static const grey200 = Color(0xFFD5D3CC);
  static const grey400 = Color(0xFF7A7871);
  static const grey600 = Color(0xFF55534D);
  static const grey800 = Color(0xFF3A3936);
  static const grey900 = Color(0xFF1A1A18); // Text

  // Semantic
  static const success = Color(0xFF1D9E75);
  static const successLight = Color(0xFFE1F5EE);
  static const error = Color(0xFFE24B4A);
  static const errorLight = Color(0xFFFCEBEB);
  static const warning = Color(0xFFF5A623);
  static const warningLight = Color(0xFFFDF1DC);
  static const info = Color(0xFF378ADD);
  static const infoLight = Color(0xFFE6F1FB);

  // Background — single standardized surface ramp.
  // Scaffold uses [backgroundSecondary]; cards/sheets/inputs use [background].
  static const background = Color(0xFFFFFFFF);
  static const backgroundSecondary = Color(0xFFF6F5F1); // Warm Off White
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFF1EFEA);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8E6E1);
  static const borderStrong = Color(0xFFDAD9D5);

  // Standardized text ramp — always use these instead of ad-hoc greys
  // for predictable hierarchy + contrast on light backgrounds.
  static const textPrimary = Color(0xFF1A1A18); // grey900
  static const textSecondary = Color(0xFF55534D); // grey600, darkened for contrast
  static const textTertiary = Color(0xFF7A7871); // grey400, darkened for contrast
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Owner theme — same brand green, kept as a semantic alias
  static const ownerPrimary = Color(0xFF1D9E75);
  static const ownerLight = Color(0xFFE1F5EE);

  // Customer theme — aliased to brand green so the whole app reads as
  // one consistent identity instead of a competing accent color.
  static const customerPrimary = Color(0xFF1D9E75);
  static const customerLight = Color(0xFFE1F5EE);

  // Agent theme — aliased to brand green, consistent with owner/customer.
  static const agentPrimary = Color(0xFF1D9E75);
  static const agentLight = Color(0xFFE1F5EE);
}
