import 'package:flutter/material.dart';
import 'package:merokotha/shared/widgets/mk_chip.dart';

/// Category filter row — unified [MkChip] pill system.
/// Behavior unchanged: null = All, tap toggles selection.
class FilterChipRow extends StatelessWidget {
  final String? selectedCategoryId;
  final List<({String id, String name})> categories;
  final void Function(String?) onCategoryChanged;

  const FilterChipRow({
    super.key,
    this.selectedCategoryId,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MkChipRow(
      children: [
        MkChip(
          label: 'All',
          selected: selectedCategoryId == null,
          onTap: () => onCategoryChanged(null),
        ),
        for (final c in categories)
          MkChip(
            label: c.name,
            selected: selectedCategoryId == c.id,
            onTap: () =>
                onCategoryChanged(selectedCategoryId == c.id ? null : c.id),
          ),
      ],
    );
  }
}
