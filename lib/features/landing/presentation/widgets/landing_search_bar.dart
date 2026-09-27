import 'package:flutter/material.dart';
import 'package:merokotha/shared/widgets/mk_search_field.dart';

/// Public search input — unified [MkSearchField] visual pattern.
/// API unchanged: still a live TextField bound to [onChanged].
class LandingSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const LandingSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MkSearchField.editable(
      hint: 'Search by location or name…',
      onChanged: onChanged,
    );
  }
}
