import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/chat/providers/chat_providers.dart';
import 'package:merokotha/shared/widgets/mk_bottom_nav.dart';

// Index map: 0 = Home, 1 = Saved, 2 = My Listings, 3 = Messages,
// 4 = Profile. Shared by every regular user: browsing and posting are
// capabilities of one account, so a single nav covers both. Posting a
// room stays one tap away via My Listings (+), the Home post card, and
// the upload route.
class HomeBottomNav extends ConsumerWidget {
  final int currentIndex;
  const HomeBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(totalUnreadProvider).asData?.value ?? 0;

    return MkBottomNav(
      currentIndex: currentIndex,
      accentColor: AppColors.accent,
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
          icon: Icons.house_outlined,
          activeIcon: Icons.house_rounded,
          label: 'Listings',
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
            context.push(AppRoutes.home);
          case 1:
            context.push(AppRoutes.favourites);
          case 2:
            context.push(AppRoutes.myListings);
          case 3:
            context.push(AppRoutes.chatList);
          case 4:
            context.push(AppRoutes.profile);
        }
      },
    );
  }
}
