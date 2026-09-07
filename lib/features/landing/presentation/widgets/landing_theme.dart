import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingTheme {
  // Brand
  static const accent = Color(0xFF1D9E75);
  static const accentMuted = Color(0xFF4C8F7B);

  // Backgrounds
  static const bg = Color(0xFFFFFFFF);
  static const bgWarm = Color(0xFFF8F7F4);
  static const surface = Color(0xFFFFFFFF);

  // Neutrals / text
  static const ink = Color(0xFF1A1A18);
  static const stone = Color(0xFF86847D);
  static const hairline = Color(0xFFEBEBEB);

  // Semantic
  static const error = Color(0xFFE24B4A);

  static TextStyle get labelSm => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: accentMuted,
  );

  static TextStyle get bodyMd =>
      GoogleFonts.dmSans(fontSize: 13.5, color: stone, height: 1.5);

  static TextStyle get priceLg => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.2,
  );

  static TextStyle get titleMd => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ink,
    letterSpacing: -0.1,
  );

  static const double r = 16.0;

  static String formatPrice(num v) => v
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
