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
          _NotificationBell(
            pendingCount: pendingCount,
            onTap: () => context.push(AppRoutes.ownerInquiries),
          ),
          const SizedBox(width: 10),
          _OwnerAvatar(userAsync: userAsync),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(ownerListingsProvider);
          ref.invalidate(pendingInquiryCountProvider);
          ref.invalidate(currentUserProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header Banner ──
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  4,
                  AppSizes.pagePadding,
                  24,
                ),
                child: userAsync.when(
                  data: (u) => OwnerGreeting(name: u?.name ?? 'Owner'),
                  loading: () => const _GreetingSkeleton(),
                  error: (_, _) => const OwnerGreeting(name: 'Owner'),
                ),
              ),
            ),

            // ── Stats ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  20,
                  AppSizes.pagePadding,
                  0,
                ),
                child: listingsAsync.when(
                  data: (l) => OwnerStatsRow(listings: l),
                  loading: () => const _StatsSkeleton(),
                  error: (e, _) => MkErrorWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(ownerListingsProvider),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Quick Actions ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OwnerSectionHeader(title: 'Quick actions'),
                    const SizedBox(height: 12),
                    const OwnerQuickActions(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Pending Inquiries ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OwnerSectionHeader(
                      title: 'Pending inquiries',
                      onSeeAll: () => context.push(AppRoutes.ownerInquiries),
                    ),
                    const SizedBox(height: 12),
                    const OwnerRecentInquiries(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── My Listings ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                child: OwnerSectionHeader(
                  title: 'My listings',
                  onSeeAll: () => context.push(AppRoutes.myListings),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            listingsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  child: _ListingsSkeleton(),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  child: MkErrorWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(ownerListingsProvider),
                  ),
                ),
              ),
              data: (listings) {
                if (listings.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.pagePadding,
                      ),
                      child: MkEmptyState(
                        title: 'No listings yet',
                        subtitle:
                            'Tap "Add listing" to post your first room and start receiving inquiries.',
                        icon: Icons.house_outlined,
                        actionLabel: 'Add listing',
                        onAction: () => context.push(AppRoutes.uploadListing),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final l = listings[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.pagePadding,
                          0,
                          AppSizes.pagePadding,
                          12,
                        ),
                        child: OwnerListingCard(
                          listing: l,
                          onStatusChange: (status) => ref
                              .read(listingStatusProvider.notifier)
                              .toggle(l.id, status),
                          onDelete: () => _confirmDelete(context, ref, l),
                        ),
                      );
                    },
                    childCount: listings.take(3).length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            fontSize: 14,
          ),
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        content: Text(
          'Delete "${l.title}"? This cannot be undone.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey600,
            height: 1.4,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(listingStatusProvider.notifier).delete(l.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header widgets ──

class _NotificationBell extends StatelessWidget {
  final AsyncValue<int> pendingCount;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.grey50,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.grey800,
              ),
            ),
          ),
        ),
        pendingCount.when(
          data: (count) => count > 0
              ? Positioned(
                  right: 2,
                  top: 2,
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
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final AsyncValue<dynamic> userAsync;
  const _OwnerAvatar({required this.userAsync});

  @override
  Widget build(BuildContext context) {
    return userAsync.when(
      data: (u) => GestureDetector(
        onTap: () => context.push(AppRoutes.ownerProfile),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: UserAvatar(
            name: u?.name ?? 'Owner',
            photoUrl: u?.photoUrl,
            size: 32,
            backgroundColor: Colors.white,
          ),
        ),
      ),
      loading: () => const ShimmerLoading(
        child: ShimmerBox(
          width: 36,
          height: 36,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ── Skeletons ──

class _GreetingSkeleton extends StatelessWidget {
  const _GreetingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            height: 14,
            width: 120,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          SizedBox(height: 8),
          ShimmerBox(
            height: 30,
            width: 180,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: ShimmerBox(
                height: 96,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListingsSkeleton extends StatelessWidget {
  const _ListingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: AppSizes.shadowCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    height: 160,
                    width: double.infinity,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          height: 16,
                          width: 160,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        SizedBox(height: 8),
                        ShimmerBox(
                          height: 12,
                          width: 100,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(
                              height: 16,
                              width: 80,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                            ShimmerBox(
                              height: 28,
                              width: 120,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
