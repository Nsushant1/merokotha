import 'package:flutter/material.dart';
import 'package:merokotha/shared/widgets/mk_chip.dart';

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

/// Horizontal category filter — unified [MkChip] pill system.
/// API unchanged: [selected] + [onSelect] behave exactly as before.
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
    return MkChipRow(
      children: [
        MkChip(
          label: 'All',
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        for (final c in _landingRoomTypeOptions)
          MkChip(
            label: c.$2,
            selected: selected == c.$1,
            onTap: () => onSelect(selected == c.$1 ? null : c.$1),
          ),
      ],
    );
  }
}
