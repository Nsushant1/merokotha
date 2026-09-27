import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';

/// Unified screen header pattern used on every screen:
///
/// [eyebrow] (11px tracked uppercase) → [title] (24px extrabold) →
/// [subtitle] (15px secondary) → optional [child] (search / stats).
///
/// Wrapped in a white band with a hairline bottom border so headers
/// read identically on landing, customer, owner, agent, and admin.
class MkScreenHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? child;
  final Widget? leading;

  const MkScreenHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.action,
    this.child,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: AppDecorations.headerBand,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            16,
            AppSizes.pagePadding,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leading case final l?) ...[l, const SizedBox(width: 10)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow case final e?) ...[
                            Text(e, style: textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1.2,
                            )),
                            const SizedBox(height: 6),
                          ],
                          Text(title, style: textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    ?action,
                  ],
                ),
                if (subtitle case final s?) ...[
                  const SizedBox(height: 8),
                  Text(s, style: textTheme.bodyMedium),
                ],
                if (child case final c?) ...[
                  const SizedBox(height: 20),
                  c,
                ],
              ],
          ),
        ),
      ),
    );
  }
}
