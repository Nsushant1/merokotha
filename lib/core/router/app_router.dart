import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/owner/presentation/screens/my_listing_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/features/auth/presentation/screens/banned_screen.dart';
import 'package:merokotha/features/auth/presentation/screens/splash_screen.dart';
import 'package:merokotha/features/auth/presentation/screens/google_login_screen.dart';
import 'package:merokotha/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/home/presentation/screens/agent_application_screen.dart';
import 'package:merokotha/features/home/presentation/screens/home_screen.dart';
import 'package:merokotha/features/home/presentation/screens/my_inquiries_screen.dart';
import 'package:merokotha/features/home/presentation/screens/profile_screen.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/core/router/app_routes.dart';

import 'package:merokotha/features/landing/presentation/screens/landing_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/upload_listing_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/owner_inquiries_screen.dart';
import 'package:merokotha/features/owner/presentation/screens/owner_map_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/search_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/customer_map_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/room_detail_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/favourites_screen.dart';
import 'package:merokotha/features/customer/presentation/screens/inquire_screen.dart';
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
import 'package:merokotha/features/admin/presentation/screens/admin_ads_screen.dart';
import 'package:merokotha/features/admin/presentation/screens/admin_ad_form_screen.dart';
import 'package:merokotha/shared/models/ad_model.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);
  // Profile is async; guards that need it only apply once loaded. Data
  // stays protected by Firestore rules regardless of navigation state.
  final user = ref.watch(currentUserProvider).asData?.value;

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
        AppRoutes.onboarding,
      ];

      if (!isLoggedIn &&
          !publicRoutes.contains(loc) &&
          !loc.startsWith('/customer/room/')) {
        return AppRoutes.login;
      }

      // Suspended accounts see only the banned screen (with a sign-out
      // action) until an admin lifts the ban. Writes are already rejected
      // by Firestore rules; this makes the state explicit instead of a
      // series of silent failures.
      if (isLoggedIn && (user?.isBanned ?? false) && loc != AppRoutes.banned) {
        return AppRoutes.banned;
      }

      // Admin screens are never reachable without the superAdmin role.
      // Verified agents land on their own interface; everyone else lands
      // on the shared home. There are no walls between regular
      // capabilities — browsing and posting belong to one account.
      if (isLoggedIn && loc.startsWith('/admin')) {
        if (user == null) return null; // profile still loading — decide later
        if (!user.isAdmin) {
          return user.isVerifiedAgent ? AppRoutes.agentHome : AppRoutes.home;
        }
      }

      // The Agent interface requires an approved application. Unverified
      // visitors (including pending applicants) go to the shared home,
      // where the profile explains their application status.
      if (isLoggedIn && loc.startsWith('/agent')) {
        if (user == null) return null; // profile still loading — decide later
        if (!user.isVerifiedAgent && !user.isAdmin) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        builder: (_, _) => const LandingScreen(),
      ),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const GoogleLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.banned, builder: (_, _) => const BannedScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.myInquiries,
        builder: (_, _) => const MyInquiriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.applyAgent,
        builder: (_, _) => const AgentApplicationScreen(),
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
        path: AppRoutes.roomDetail,
        builder: (_, state) =>
            RoomDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.inquire,
        builder: (_, state) => InquireRouteScreen(
          listingId: state.pathParameters['id']!,
          listing: state.extra is ListingModel
              ? state.extra as ListingModel
              : null,
        ),
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
        path: AppRoutes.adminAds,
        builder: (_, _) => const AdminAdsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAdForm,
        builder: (_, state) => AdminAdFormScreen(ad: state.extra as AdModel?),
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
