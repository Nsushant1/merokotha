import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';
import 'package:merokotha/shared/widgets/mk_section_title.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final listingsAsync = ref.watch(activeListingsProvider);
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(activeListingsProvider);
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
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      userAsync.when(
                        data: (u) => GestureDetector(
                          onTap: () => context.push(AppRoutes.customerProfile),
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
              // ── Search ──
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
                      // Greeting
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting().toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 6),
                          userAsync.when(
                            data: (u) => Text(
                              'Hello, ${u?.name.split(' ').first ?? 'there'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Search bar — unified pattern
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

              // ── Promo banner (external destinations, 3s auto-scroll) ──
              // Immediately below the search bar per requirements.
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

              // ── Filter chips ──
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _CategoryChipRow(
                      selected: ref.watch(searchFilterProvider).categoryL1Id,
                      onSelect: (id) => ref
                          .read(searchFilterProvider.notifier)
                          .setCategory(categoryL1Id: id),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ── Listings: list-based feed (lazy SliverList) ──
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
                  // Category chip filter applied client-side; watched once
                  // here (not nested inside another provider watch).
                  final selectedL1 = ref
                      .watch(searchFilterProvider)
                      .categoryL1Id;
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
                          child: MkSectionTitle(
                            'All rooms (${listings.length})',
                            actionLabel: 'View All',
                            onAction: () => context.push(AppRoutes.search),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.pagePadding,
                        ),
                        sliver: SliverList.separated(
                          itemCount: listings.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final l = listings[i];
                            return ListingRow(
                              listing: l,
                              isFavourited: favIds.contains(l.id),
                              onFavourite: () => ref
                                  .read(favouriteProvider.notifier)
                                  .toggle(l),
                              onTap: () => context.push(
                                AppRoutes.roomDetail.replaceAll(':id', l.id),
                              ),
                            );
                          },
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

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.customerMap),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.map_rounded),
      ),

      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
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

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
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
