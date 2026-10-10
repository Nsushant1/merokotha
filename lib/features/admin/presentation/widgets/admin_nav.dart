import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';

/// Admin panel runs a deliberate dark shell — a rich near-black surface
/// with a gold accent — so the admin experience reads as a distinct,
/// authoritative mode rather than another green customer/owner screen.
class AdminColors {
  static const primary = Color(0xFF1A1A18);
  static const accent = AppColors.warning;
  static const accentLight = AppColors.warningLight;
  static const surface = Color(0xFF2C2B27);
  static const bg = Color(0xFF1A1A18);
}

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  const AdminBottomNav({super.key, required this.currentIndex});

  static const _items = [
    (
      icon: Icons.dashboard_outlined,
      active: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    (
      icon: Icons.people_outline_rounded,
      active: Icons.people_rounded,
      label: 'Users',
    ),
    (
      icon: Icons.home_work_outlined,
      active: Icons.home_work_rounded,
      label: 'Listings',
    ),
    (
      icon: Icons.inbox_outlined,
      active: Icons.inbox_rounded,
      label: 'Inquiries',
    ),
  ];

  // Tab switches replace the stack instead of piling onto it, so the
  // system back button exits the current section instead of walking
  // back through previously visited tabs.
  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go(AppRoutes.adminHome);
      case 1:
        context.go(AppRoutes.adminUsers);
      case 2:
        context.go(AppRoutes.adminListings);
      case 3:
        context.go(AppRoutes.adminInquiries);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AdminColors.primary,
        border: Border(top: BorderSide(color: AdminColors.surface, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _AdminNavItem(
                    icon: _items[i].icon,
                    activeIcon: _items[i].active,
                    label: _items[i].label,
                    selected: i == currentIndex,
                    onTap: () => _onTap(context, i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AdminColors.accent : AppColors.grey400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AdminColors.accent.withValues(alpha: 0.1),
        highlightColor: AdminColors.accent.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AdminColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 60,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Material(
                color: AdminColors.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AdminColors.accent,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 16,
              color: AdminColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AdminColors.surface),
      ),
    );
  }
}
