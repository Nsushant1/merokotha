import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/shared/widgets/owner_bottom_nav.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/owner/providers/owner_providers.dart';
import 'package:merokotha/features/owner/presentation/widgets/owner_widgets.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final listingsAsync = ref.watch(ownerListingsProvider);
    final pendingCount = ref.watch(pendingInquiryCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(
        title: 'MeroKotha',
        showBack: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.grey800,
                ),
                onPressed: () => context.push(AppRoutes.ownerInquiries),
              ),
              pendingCount.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: userAsync.when(
              data: (u) => GestureDetector(
                onTap: () => context.push(AppRoutes.ownerProfile),
                child: UserAvatar(
                  name: u?.name ?? 'Owner',
                  photoUrl: u?.photoUrl,
                  size: 34,
                ),
              ),
              loading: () => const ShimmerLoading(
                child: ShimmerBox(
                  width: 34,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(17)),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(ownerListingsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userAsync.when(
                data: (u) => OwnerGreeting(name: u?.name ?? 'Owner'),
                loading: () => const SizedBox(height: 48),
                error: (_, _) => const OwnerGreeting(name: 'Owner'),
              ),
              const SizedBox(height: 20),

              listingsAsync.when(
                data: (l) => OwnerStatsRow(listings: l),
                loading: () => ShimmerLoading(
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: ShimmerBox(
                            height: 90,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                error: (e, _) => MkErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(ownerListingsProvider),
                ),
              ),
              const SizedBox(height: 24),

              const OwnerSectionHeader(title: 'Quick actions'),
              const SizedBox(height: 12),
              const OwnerQuickActions(),
              const SizedBox(height: 24),

              OwnerSectionHeader(
                title: 'Pending inquiries',
                onSeeAll: () => context.push(AppRoutes.ownerInquiries),
              ),
              const SizedBox(height: 12),
              const OwnerRecentInquiries(),
              const SizedBox(height: 24),

              OwnerSectionHeader(
                title: 'My listings',
                onSeeAll: () => context.push(AppRoutes.myListings),
              ),
              const SizedBox(height: 12),
              listingsAsync.when(
                data: (listings) => listings.isEmpty
                    ? MkEmptyState(
                        title: 'No listings yet',
                        subtitle: 'Tap "Add listing" to post your first room',
                        icon: Icons.house_outlined,
                        actionLabel: 'Add listing',
                        onAction: () => context.push(AppRoutes.uploadListing),
                      )
                    : Column(
                        children: listings
                            .take(3)
                            .map(
                              (l) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: OwnerListingCard(
                                  listing: l,
                                  onStatusChange: (status) => ref
                                      .read(listingStatusProvider.notifier)
                                      .toggle(l.id, status),
                                  onDelete: () =>
                                      _confirmDelete(context, ref, l),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const MkLoading(fullScreen: false),
                error: (e, _) => MkErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(ownerListingsProvider),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.uploadListing),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add listing',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 0),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ListingModel l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: const Text(
          'Delete listing?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900),
        ),
        content: Text(
          'Delete "${l.title}"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(listingStatusProvider.notifier).delete(l.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
