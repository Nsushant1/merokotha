import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Unified card primitive — every card composes from this.
///
/// [MkSpecPill]: icon + label pill for room specs (3 Room / 2 Bath).
/// Small spec pill: light-blue well with dark-blue icon + label.
/// Used for room specs, nearby times, facility counts.
class MkSpecPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  const MkSpecPill({
    super.key,
    required this.icon,
    required this.label,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background ?? AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground ?? AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
