import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';

const _landingRoomTypeOptions = [
  ('room', 'Room'),
  ('flat', 'Flat'),
  ('apartment', 'Apartment'),
  ('house', 'House'),
  ('office', 'Office'),
  ('shop', 'Shop'),
  ('land', 'Land'),
  ('other', 'Other'),
];

class LandingCategoryRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const LandingCategoryRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _Chip(
            label: 'All',
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          ..._landingRoomTypeOptions.map(
            (c) => _Chip(
              label: c.$2,
              active: selected == c.$1,
              onTap: () => onSelect(selected == c.$1 ? null : c.$1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? LandingTheme.accent : LandingTheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? LandingTheme.accent : LandingTheme.hairline,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : LandingTheme.ink,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
