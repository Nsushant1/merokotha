import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';

/// Unified card primitive — every card in the app composes from this.
///
/// [MkCard]: plain tappable/static card (white, 20px radius, hairline,
/// soft shadow). [MkSectionCard]: titled section with uppercase eyebrow
/// label, hairline divider, and 20px body padding.
class MkCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showShadow;
  final double? width;

  const MkCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSizes.cardPadding),
    this.showShadow = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.radiusLg);
    final body = Container(
      width: width,
      padding: padding,
      decoration: showShadow ? AppDecorations.card : AppDecorations.cardFlat,
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: body),
    );
  }
}

class MkSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const MkSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSizes.cardPaddingLarge),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: padding, child: Column(children: children)),
        ],
      ),
    );
  }
}
