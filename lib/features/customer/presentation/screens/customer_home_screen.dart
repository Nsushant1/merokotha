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
        child: RefreshIndicator(
          color: AppColors.customerPrimary,
          onRefresh: () async {
            ref.invalidate(activeListingsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── Header + Search ──
              SliverToBoxAdapter(
                child: Container(
                  decoration: AppDecorations.headerBand,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    20,
                    AppSizes.pagePadding,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting().toUpperCase(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                userAsync.when(
                                  data: (u) => Text(
                                    u?.name.split(' ').first ?? 'MeroKotha',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                  loading: () => Text(
                                    'MeroKotha',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
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
                                        color: AppColors.customerPrimary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        u?.location ?? 'Kathmandu',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              // Notification bell
                              Container(
                                width: 44,
                                height: 44,
                                decoration: AppDecorations.iconWell(),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  size: 20,
                                  color: AppColors.grey800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Avatar with colored ring
                              userAsync.when(
                                data: (u) => GestureDetector(
                                  onTap: () =>
                                      context.push(AppRoutes.customerProfile),
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.customerPrimary,
                                        width: 2,
                                      ),
                                    ),
                                    child: UserAvatar(
                                      name: u?.name ?? 'User',
                                      photoUrl: u?.photoUrl,
                                      size: 38,
                                      backgroundColor: AppColors.customerLight,
                                    ),
                                  ),
                                ),
                                loading: () =>
                                    const SizedBox(width: 44, height: 44),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search bar — unified pattern
                      MkSearchField.readOnly(
                        hint: 'Search rooms, area, landmarks...',
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

              // ── Section header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  child: MkSectionTitle(
                    'Rooms near you',
                    showAccent: true,
                    accentColor: AppColors.customerPrimary,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Listings ──
              listingsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: _ListingFeedSkeleton(),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: MkErrorWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(activeListingsProvider),
                  ),
                ),
                data: (allListings) {
                  // Apply category chip filter client-side
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

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final l = listings[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.pagePadding,
                          vertical: 6,
                        ),
                        child: ListingCard(
                          listing: l,
                          isFavourited: favIds.contains(l.id),
                          onFavourite: () => ref
                              .read(favouriteProvider.notifier)
                              .toggle(l),
                          onTap: () => context.push(
                            AppRoutes.roomDetail.replaceAll(':id', l.id),
                          ),
                        ),
                      );
                    }, childCount: listings.length),
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
        backgroundColor: AppColors.customerPrimary,
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
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: AppSizes.shadowCard,
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      height: 160,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    const SizedBox(height: 12),
                    ShimmerBox(height: 14, width: 160, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    ShimmerBox(height: 12, width: 100, borderRadius: BorderRadius.circular(4)),
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
