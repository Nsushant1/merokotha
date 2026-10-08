import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';

/// Definition for a single destination in [MkBottomNav].
class MkBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const MkBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Bottom navigation matching design.jpeg: white bar with hairline top,
/// red active icon + label, grey-blue inactive, and an optional elevated
/// red gradient center FAB (Home / Saved / + / Messages / Profile).
class MkBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<MkBottomNavItem> items;
  final ValueChanged<int> onTap;
  final Color accentColor;

  /// When set, the middle item is replaced by a center + FAB that
  /// triggers [onCenterTap]. Index mapping for side items stays 0..n.
  final VoidCallback? onCenterTap;
  final IconData centerIcon;

  const MkBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.accentColor = AppColors.accent,
    this.onCenterTap,
    this.centerIcon = Icons.add_rounded,
  });

  static const _inactive = Color(0xFF8AA0BE);

  @override
  Widget build(BuildContext context) {
    final hasCenterFab = onCenterTap != null && items.length == 5;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14063B7A),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                if (hasCenterFab && i == 2)
                  Expanded(child: _CenterFab(onTap: onCenterTap!))
                else
                  Expanded(
                    child: _NavTapTarget(
                      item: items[i],
                      selected: i == currentIndex,
                      accentColor: accentColor,
                      inactiveColor: _inactive,
                      onTap: () => onTap(i),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FF1F2D),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _NavTapTarget extends StatelessWidget {
  final MkBottomNavItem item;
  final bool selected;
  final Color accentColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavTapTarget({
    required this.item,
    required this.selected,
    required this.accentColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accentColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.08),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key: ValueKey(selected),
                    color: color,
                    size: 25,
                  ),
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
                color: color,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
