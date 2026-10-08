import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Mero Kotha brand palette (matches design.jpeg reference) ──
  // Core brand: Primary Blue + Primary Red. Blue drives navigation,
  // primary actions, and surfaces; red is reserved for highlights,
  // prices, important CTAs, alerts, and selected filter states.

  // Brand Blue
  static const primary = Color(0xFF0757B8);
  static const primaryDark = Color(0xFF063B7A);
  static const primaryLight = Color(0xFFEAF4FF);
  static const primaryContainer = Color(0xFFD6E9FF);

  // Brand Red (accent / highlight / important CTA)
  static const accent = Color(0xFFFF1F2D);
  static const accentDark = Color(0xFFD91424);
  static const accentLight = Color(0xFFFFE8EA);

  static const secondary = Color(0xFFFF1F2D);
  static const secondaryLight = Color(0xFFFFE8EA);

  // Neutrals — cool blue-tinted ramp so surfaces sit cleanly on
  // Light Background #F5F9FF and text stays Dark Text #12315A.
  static const grey50 = Color(0xFFF5F9FF); // = light background
  static const grey100 = Color(0xFFEAF4FF); // = light blue
  static const grey200 = Color(0xFFD9E6F7);
  static const grey400 = Color(0xFF6B8AB0);
  static const grey600 = Color(0xFF3A5A85);
  static const grey800 = Color(0xFF1E3A5F);
  static const grey900 = Color(0xFF12315A); // = dark text

  // Semantic — red family doubles as error so alerts match brand.
  static const success = Color(0xFF0E7A4F);
  static const successLight = Color(0xFFE2F4EA);
  static const error = Color(0xFFD91424);
  static const errorLight = Color(0xFFFFE8EA);
  static const warning = Color(0xFFB7791F);
  static const warningLight = Color(0xFFFFF1D6);
  static const info = Color(0xFF0757B8);
  static const infoLight = Color(0xFFEAF4FF);

  // Background — white cards/sheets/inputs on light-blue-tinted scaffold.
  static const background = Color(0xFFFFFFFF);
  static const backgroundSecondary = Color(0xFFF5F9FF); // Light Background
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEAF4FF);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE8F8);
  static const borderStrong = Color(0xFFB9D0EC);

  // Text ramp — dark blue hierarchy for contrast on white/light.
  static const textPrimary = Color(0xFF12315A); // Dark Text
  static const textSecondary = Color(0xFF3A5A85);
  static const textTertiary = Color(0xFF6B8AB0);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Role aliases — one consistent brand identity app-wide.
  // Blue is the default primary; red is used for conversion CTAs.
  static const ownerPrimary = Color(0xFF0757B8);
  static const ownerLight = Color(0xFFEAF4FF);

  static const customerPrimary = Color(0xFF0757B8);
  static const customerLight = Color(0xFFEAF4FF);

  static const agentPrimary = Color(0xFF0757B8);
  static const agentLight = Color(0xFFEAF4FF);

  // ── Design-reference helpers ──

  /// Blue → dark-blue gradient used for headers, hero banners,
  /// and profile bands (see design.jpeg top bars / profile header).
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF0757B8), Color(0xFF063B7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Red → dark-red gradient used for important CTAs
  /// (Get Started, Apply Filters, Contact Owner, + FAB).
  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF1F2D), Color(0xFFD91424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Price text — always brand red for hierarchy (see listing cards).
  static const price = Color(0xFFD91424);
}
