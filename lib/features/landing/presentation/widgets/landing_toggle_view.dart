import 'package:flutter/material.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';

class LandingToggleView extends StatelessWidget {
  final bool isGrid;
  final VoidCallback onToggle;

  const LandingToggleView({
    super.key,
    required this.isGrid,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LandingTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LandingTheme.hairline, width: 1),
          ),
          child: Icon(
            isGrid
                ? Icons.format_list_bulleted_rounded
                : Icons.grid_view_rounded,
            color: LandingTheme.accent,
            size: 16,
          ),
        ),
      ),
    );
  }
}
