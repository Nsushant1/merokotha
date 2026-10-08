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

/// Section heading matching design.jpeg: 17px w800 dark title left,
/// optional blue "View All →" action right. Set [showAccent] for the
/// 4px blue left bar variant used on dense feeds.
class MkSectionTitle extends StatelessWidget {
  final String text;
  final bool showAccent;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MkSectionTitle(
    this.text, {
    super.key,
    this.showAccent = false,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
    );

    final action = (actionLabel != null && onAction != null)
        ? GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ],
            ),
          )
        : null;

    if (!showAccent) {
      if (action == null) return title;
      return Row(
        children: [
          Expanded(child: title),
          action,
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: accentColor ?? AppColors.accent,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: title),
        ?action,
      ],
    );
  }
}
