import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Horizontal rule used between content sections.
class MkDivider extends StatelessWidget {
  const MkDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSizes.md),
    child: Divider(height: 1, color: AppColors.border),
  );
}

/// Bold section heading with optional accent bar on the left.
class MkSectionTitle extends StatelessWidget {
  final String text;
  final bool showAccent;
  final Color? accentColor;

  const MkSectionTitle(
    this.text, {
    super.key,
    this.showAccent = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAccent) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.3,
          color: AppColors.grey900,
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: accentColor ?? AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.3,
              color: AppColors.grey900,
            ),
          ),
        ),
      ],
    );
  }
}
