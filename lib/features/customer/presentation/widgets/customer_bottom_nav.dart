import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/chat/providers/chat_providers.dart';
import 'package:merokotha/shared/widgets/mk_bottom_nav.dart';

// Index map: 0 = Home, 1 = Saved, 2 = + (search), 3 = Messages, 4 = Profile.
// Matches design.jpeg: Home / Saved / + / Messages / Profile.
class CustomerBottomNav extends ConsumerWidget {
  final int currentIndex;
  const CustomerBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(totalUnreadProvider).asData?.value ?? 0;

    return MkBottomNav(
      currentIndex: currentIndex,
      accentColor: AppColors.accent,
      onCenterTap: () => context.push(AppRoutes.search),
      items: [
        const MkBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        const MkBottomNavItem(
          icon: Icons.favorite_outline_rounded,
          activeIcon: Icons.favorite_rounded,
          label: 'Saved',
        ),
        const MkBottomNavItem(
          icon: Icons.add_rounded,
          activeIcon: Icons.add_rounded,
          label: '+',
        ),
        MkBottomNavItem(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          label: 'Messages',
          badgeCount: unread,
        ),
        const MkBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
      onTap: (i) {
        switch (i) {
          case 0:
            context.push(AppRoutes.customerHome);
          case 1:
            context.push(AppRoutes.favourites);
          case 3:
            context.push(AppRoutes.chatList);
          case 4:
            context.push(AppRoutes.customerProfile);
        }
      },
    );
  }
}
