import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/chat/providers/chat_providers.dart';
import 'package:merokotha/shared/widgets/mk_bottom_nav.dart';

// Index map: 0 = Home, 1 = Browse, 2 = + (Add), 3 = Inbox, 4 = Profile.
class AgentBottomNav extends ConsumerWidget {
  final int currentIndex;
  const AgentBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(totalUnreadProvider).asData?.value ?? 0;

    return MkBottomNav(
      currentIndex: currentIndex,
      accentColor: AppColors.accent,
      onCenterTap: () => context.push(AppRoutes.agentUpload),
      items: [
        const MkBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        const MkBottomNavItem(
          icon: Icons.search_outlined,
          activeIcon: Icons.search_rounded,
          label: 'Browse',
        ),
        const MkBottomNavItem(
          icon: Icons.add_rounded,
          activeIcon: Icons.add_rounded,
          label: '+',
        ),
        MkBottomNavItem(
          icon: Icons.inbox_outlined,
          activeIcon: Icons.inbox_rounded,
          label: 'Inbox',
          badgeCount: unread,
        ),
        const MkBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
      // Tab switches replace the stack instead of piling onto it, so the
      // system back button exits the current section instead of walking
      // back through previously visited tabs.
      onTap: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.agentHome);
          case 1:
            context.go(AppRoutes.home);
          case 3:
            // The badge counts unread *messages*, so this must land on the
            // chat list — not on the inquiries screen.
            context.go(AppRoutes.chatList);
          case 4:
            context.go(AppRoutes.agentProfile);
        }
      },
    );
  }
}
