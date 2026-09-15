import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF1D9E75);
  static const primaryDark = Color(0xFF0F6E56);
  static const primaryLight = Color(0xFFE1F5EE);

  static const secondary = Color(0xFF534AB7);
  static const secondaryLight = Color(0xFFEEEDFE);

  // Neutrals (warm-neutral ramp, anchored to spec text/border colors)
  static const grey50 = Color(0xFFEBEBEB); // Border
  static const grey100 = Color(0xFFDAD9D5);
  static const grey200 = Color(0xFFBFBEB8);
  static const grey400 = Color(0xFF92908A);
  static const grey600 = Color(0xFF66645D);
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

  // Background
  static const background = Color(0xFFFFFFFF);
  static const backgroundSecondary = Color(0xFFF8F7F4); // Warm Off White
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFEBEBEB);

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
