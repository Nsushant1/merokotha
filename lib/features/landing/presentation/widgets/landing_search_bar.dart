import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';

class LandingSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const LandingSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.dmSans(
        fontSize: 14.5,
        color: LandingTheme.ink,
      ),
      decoration: InputDecoration(
        hintText: 'Search by location or name…',
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: LandingTheme.stone,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: LandingTheme.stone,
          size: 20,
        ),
        filled: true,
        fillColor: LandingTheme.bgWarm,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LandingTheme.accent, width: 1.5),
        ),
      ),
    );
  }
}
