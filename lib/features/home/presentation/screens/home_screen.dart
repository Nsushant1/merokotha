import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/customer/providers/room_view_mode_provider.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/home/providers/agent_application_providers.dart';
import 'package:merokotha/shared/models/agent_application_model.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/owner/providers/owner_providers.dart';
import 'package:merokotha/features/owner/presentation/widgets/owner_widgets.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

/// Shared home for every regular user.
///
/// Browsing (search, feed, favourites, map) is identical for all users.
/// Owner capabilities — stats, quick actions, pending inquiries and the
/// my-listings preview — appear as an "owner hub" section whenever the
/// user has listings or pending inquiries; otherwise a compact post-a-room
/// card advertises the capability. No role switching is required for any
/// of it: every account can both browse and post.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final listingsAsync = ref.watch(activeListingsProvider);
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];
    final isGrid = ref.watch(roomViewModeProvider);
    final selectedL1 = ref.watch(searchFilterProvider).categoryL1Id;
    final myListingsAsync = ref.watch(ownerListingsProvider);
    final pendingCount = ref.watch(pendingInquiryCountProvider);

    final myListings = myListingsAsync.asData?.value ?? [];
    final pending = pendingCount.asData?.value ?? 0;
    final showOwnerHub = myListings.isNotEmpty || pending > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(activeListingsProvider);
            ref.invalidate(ownerListingsProvider);
            ref.invalidate(pendingInquiryCountProvider);
            ref.invalidate(currentUserProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── Brand header (logo + bell + avatar) ──
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    14,
                    AppSizes.pagePadding,
                    0,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/merokotha.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              TextSpan(
                                text: 'Mero ',
                                style: TextStyle(color: AppColors.primary),
                              ),
                              TextSpan(
                                text: 'Kotha',
                                style: TextStyle(color: AppColors.accent),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const _AgentEntry(),
                      const SizedBox(width: 10),
                      userAsync.when(
                        data: (u) => GestureDetector(
                          onTap: () => context.push(AppRoutes.profile),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent,
                                width: 2,
                              ),
                            ),
                            child: UserAvatar(
                              name: u?.name ?? 'User',
                              photoUrl: u?.photoUrl,
                              size: 36,
                              backgroundColor: AppColors.primaryLight,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox(width: 42, height: 42),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Greeting + search ──
              SliverToBoxAdapter(
                child: Container(
                  decoration: AppDecorations.headerBand,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    16,
                    AppSizes.pagePadding,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      userAsync.when(
                        data: (u) => OwnerGreeting(name: u?.name ?? 'there'),
                        loading: () => Text(
                          'Hello there',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 4),
                      userAsync.when(
                        data: (u) => Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                u?.location ?? 'Kathmandu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 18),
                      MkSearchField.readOnly(
                        hint: 'Search by location, property type...',
                        onTap: () => context.push(AppRoutes.search),
                        suffix: MkSearchSuffixButton(
                          icon: Icons.tune_rounded,
                          onTap: () => context.push(AppRoutes.search),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Promo banner ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    16,
                    AppSizes.pagePadding,
                    0,
                  ),
                  child: PromoBannerCarousel(),
                ),
              ),

              // ── Owner hub (conditional) ──
              if (showOwnerHub) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pagePadding,
                    ),
                    child: myListingsAsync.when(
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OwnerSectionHeader(title: 'Quick actions'),
                        const SizedBox(height: 12),
                        const OwnerQuickActions(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
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
                          onSeeAll: () =>
                              context.push(AppRoutes.ownerInquiries),
                        ),
                        const SizedBox(height: 12),
                        const OwnerRecentInquiries(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
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
                const _MyListingsPreview(),
              ] else ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pagePadding,
                    ),
                    child: _PostRoomCta(
                      onTap: () => context.push(AppRoutes.uploadListing),
                    ),
                  ),
                ),
              ],

              // ── Filter chips ──
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _CategoryChipRow(
                      selected: selectedL1,
                      onSelect: (id) => ref
                          .read(searchFilterProvider.notifier)
                          .setCategory(categoryL1Id: id),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ── Explore feed ──
              listingsAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: _ListingFeedSkeleton()),
                error: (e, _) => SliverToBoxAdapter(
                  child: MkErrorWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(activeListingsProvider),
                  ),
                ),
                data: (allListings) {
                  final listings = selectedL1 == null
                      ? allListings
                      : allListings
                            .where((l) => l.roomType == selectedL1)
                            .toList();

                  if (listings.isEmpty) {
                    return SliverToBoxAdapter(
                      child: MkEmptyState(
                        title: 'No rooms found',
                        subtitle: selectedL1 != null
                            ? 'No rooms in this category. Try a different type.'
                            : 'No listings yet. Check back soon.',
                        icon: Icons.house_outlined,
                      ),
                    );
                  }

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.pagePadding,
                          ),
                          child: RoomSectionHeader(
                            title: 'All rooms (${listings.length})',
                            actionLabel: 'View All',
                            onAction: () => context.push(AppRoutes.search),
                            isGrid: isGrid,
                            onToggle: () => ref
                                .read(roomViewModeProvider.notifier)
                                .toggle(),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      RoomFeedSlivers(
                        listings: listings,
                        isGrid: isGrid,
                        favouriteIds: favIds,
                        onFavourite: (l) =>
                            ref.read(favouriteProvider.notifier).toggle(l),
                        onTap: (l) => context.push(
                          AppRoutes.roomDetail.replaceAll(':id', l.id),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // Post-a-room stays one thumb-tap away everywhere on Home; the map
      // companion keeps browse-by-location equally close. Same red-gradient
      // language as the bottom-nav center action.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'home_post_room',
            onPressed: () => context.push(AppRoutes.uploadListing),
            tooltip: 'Post a room',
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'home_map',
            onPressed: () => context.push(AppRoutes.customerMap),
            tooltip: 'Browse on map',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            shape: CircleBorder(side: BorderSide(color: AppColors.border)),
            child: const Icon(Icons.map_rounded),
          ),
        ],
      ),

      bottomNavigationBar: const HomeBottomNav(currentIndex: 0),
    );
  }
}

/// "Become Agent" entry in the header actions, in place of the old
/// notification bell (inquiries stay reachable via the Home owner hub,
/// My inquiries, and Messages).
///
/// Hidden for verified agents and admins (they have nothing to apply
/// for). Shows an hourglass + "Pending" while an application is under
/// review — both open the existing `/apply-agent` route, which renders
/// the matching status.
class _AgentEntry extends ConsumerWidget {
  const _AgentEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user == null || user.isVerifiedAgent || user.isAdmin) {
      return const SizedBox.shrink();
    }
    final pending =
        ref.watch(myAgentApplicationProvider).asData?.value?.status ==
        AgentApplicationStatus.pending;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.applyAgent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: pending ? null : AppColors.accentGradient,
          color: pending ? AppColors.warning : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40FF1F2D),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pending ? Icons.hourglass_top_rounded : Icons.badge_outlined,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              pending ? 'Pending' : 'Become Agent',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact card advertising posting for users without listings yet.
class _PostRoomCta extends StatelessWidget {
  final VoidCallback onTap;
  const _PostRoomCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppSizes.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Icon(Icons.add_home_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have a room to rent?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Post it for free and reach seekers.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey600),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: const Text('Post')),
        ],
      ),
    );
  }
}

/// First 3 own listings with status toggle + delete.
class _MyListingsPreview extends ConsumerWidget {
  const _MyListingsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(ownerListingsProvider);
    return listingsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
          child: _ListingsSkeleton(),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
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
          delegate: SliverChildBuilderDelegate((context, index) {
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
          }, childCount: listings.take(3).length),
        );
      },
    );
  }
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
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerBox(height: 120, width: double.infinity),
          ),
        ),
      ),
    );
  }
}

class _ListingFeedSkeleton extends StatelessWidget {
  const _ListingFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pagePadding,
          vertical: 6,
        ),
        child: Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: AppSizes.shadowCard,
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ShimmerBox(
                      height: 120,
                      width: 120,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShimmerBox(
                            height: 15,
                            width: 150,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          ShimmerBox(
                            height: 13,
                            width: 100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          ShimmerBox(
                            height: 13,
                            width: 70,
                            borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }
}

const _roomTypeOptions = [
  ('room', 'Room'),
  ('flat', 'Flat'),
  ('apartment', 'Apartment'),
  ('house', 'House'),
  ('office', 'Office'),
  ('shop', 'Shop'),
  ('land', 'Land'),
  ('other', 'Other'),
];

class _CategoryChipRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _CategoryChipRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return MkChipRow(
      children: [
        MkChip(
          label: 'All',
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        ..._roomTypeOptions.map(
          (c) => MkChip(
            label: c.$2,
            selected: selected == c.$1,
            onTap: () => onSelect(selected == c.$1 ? null : c.$1),
          ),
        ),
      ],
    );
  }
}
