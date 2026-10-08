import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/chat/providers/chat_providers.dart';
import 'package:merokotha/shared/widgets/mk_bottom_nav.dart';

// Index map: 0 = Home, 1 = Listings, 2 = + (Add), 3 = Messages, 4 = Profile.
// Matches design.jpeg center + FAB.
class OwnerBottomNav extends ConsumerWidget {
  final int currentIndex;
  const OwnerBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(totalUnreadProvider).asData?.value ?? 0;

    return MkBottomNav(
      currentIndex: currentIndex,
      accentColor: AppColors.accent,
      onCenterTap: () => context.push(AppRoutes.uploadListing),
      items: [
        const MkBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        const MkBottomNavItem(
          icon: Icons.list_alt_outlined,
          activeIcon: Icons.list_alt_rounded,
          label: 'Listings',
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
            context.push(AppRoutes.ownerHome);
          case 1:
            context.push(AppRoutes.myListings);
          case 3:
            context.push(AppRoutes.chatList);
          case 4:
            context.push(AppRoutes.ownerProfile);
        }
      },
    );
  }
}
