import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/owner/presentation/screens/my_listing_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/features/auth/presentation/screens/splash_screen.dart';
import 'package:merokotha/features/auth/presentation/screens/otp_login_screen.dart';
import 'package:merokotha/features/auth/presentation/screens/role_select_screen.dart';
import 'package:merokotha/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/core/router/app_routes.dart';

import 'package:merokotha/features/landing/presentation/screens/landing_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/owner_home_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/upload_listing_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/owner_inquiries_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/owner_map_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/owner_profile_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/customer_home_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/search_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/customer_map_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/room_detail_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/favourites_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/inquire_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/customer_profile_screen.dart';
import 'package:merokotha/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:merokotha/features/chat/presentation/screens/chat_thread_screen.dart';
import 'package:merokotha/features/agent/presentation/screens/agent_home_screen.dart';
import 'package:merokotha/features/agent/presentation/screens/agent_upload_screen.dart';
import 'package:merokotha/features/agent/presentation/screens/agent_listings_screen.dart';
import 'package:merokotha/features/agent/presentation/screens/agent_inquiries_screen.dart';
import 'package:merokotha/features/agent/presentation/screens/agent_profile_screen.dart';
import 'package:merokotha/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:merokotha/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:merokotha/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:merokotha/features/admin/presentation/screens/admin_listings_screen.dart';
import 'package:merokotha/features/admin/presentation/screens/admin_inquiries_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final loc = state.matchedLocation;

      final publicRoutes = [
        AppRoutes.landing,
        AppRoutes.login,
        AppRoutes.splash,
        AppRoutes.roleSelect,
        AppRoutes.onboarding,
      ];

      if (!isLoggedIn &&
          !publicRoutes.contains(loc) &&
          !loc.startsWith('/customer/room/')) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        builder: (_, _) => const LandingScreen(),
      ),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const OtpLoginScreen()),
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (_, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.ownerHome,
        builder: (_, _) => const OwnerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.uploadListing,
        builder: (_, state) =>
            UploadListingScreen(listing: state.extra as ListingModel?),
      ),
      GoRoute(
        path: AppRoutes.myListings,
        builder: (_, _) => const MyListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.ownerInquiries,
        builder: (_, _) => const OwnerInquiriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.ownerMap,
        builder: (_, _) => const OwnerMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.ownerProfile,
        builder: (_, _) => const OwnerProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (_, _) => const CustomerHomeScreen(),
      ),
      GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: AppRoutes.customerMap,
        builder: (_, _) => const CustomerMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.favourites,
        builder: (_, _) => const FavouritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerProfile,
        builder: (_, _) => const CustomerProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomDetail,
        builder: (_, state) =>
            RoomDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.inquire,
        builder: (_, state) =>
            InquireScreen(listing: state.extra as ListingModel),
      ),
      GoRoute(
        path: AppRoutes.chatList,
        builder: (_, _) => const ChatListScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatThread,
        builder: (_, state) =>
            ChatThreadScreen(chatId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (_, _) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (_, _) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminListings,
        builder: (_, _) => const AdminListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminInquiries,
        builder: (_, _) => const AdminInquiriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUserDetail,
        builder: (_, state) =>
            AdminUserDetailScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: AppRoutes.agentHome,
        builder: (_, _) => const AgentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentUpload,
        builder: (_, state) =>
            AgentUploadScreen(listing: state.extra as ListingModel?),
      ),
      GoRoute(
        path: AppRoutes.agentListings,
        builder: (_, _) => const AgentListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentInquiries,
        builder: (_, _) => const AgentInquiriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentProfile,
        builder: (_, _) => const AgentProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.landing),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );
}
