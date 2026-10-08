import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';

/// Unified card primitive — every card composes from this.
///
/// [MkCard]: white 20px radius, hairline border, soft blue shadow.
/// [MkSectionCard]: titled section with uppercase eyebrow + divider.
/// [MkHeroCard]: blue→dark gradient with red wash (promo / headers).
/// [MkSpecPill]: icon + label pill for room specs (3 Room / 2 Bath).
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
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: padding,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Gradient hero card (promo banners, empty-state headers).
class MkHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const MkHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.radiusLg);
    final body = Container(
      width: double.infinity,
      padding: padding,
      decoration: AppDecorations.promoBanner,
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
