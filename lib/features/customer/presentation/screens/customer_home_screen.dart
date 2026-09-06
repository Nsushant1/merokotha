import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
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
                  color: Colors.white,
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
                                  _greeting(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.grey400,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                userAsync.when(
                                  data: (u) => Text(
                                    u?.name.split(' ').first ?? 'MeroKotha',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.grey900,
                                      height: 1.15,
                                    ),
                                  ),
                                  loading: () => const Text(
                                    'MeroKotha',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.grey900,
                                      height: 1.15,
                                    ),
                                  ),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                                const SizedBox(height: 4),
                                userAsync.when(
                                  data: (u) => Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 13,
                                        color: AppColors.customerPrimary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        u?.location ?? 'Kathmandu',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey400,
                                        ),
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
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: AppColors.grey50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  size: 20,
                                  color: AppColors.grey600,
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
                                      size: 36,
                                      backgroundColor: AppColors.customerLight,
                                    ),
                                  ),
                                ),
                                loading: () =>
                                    const SizedBox(width: 42, height: 42),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search bar
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.search),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(color: AppColors.grey100),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Search rooms, area, landmarks...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey400,
                                  ),
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.customerPrimary,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
        children: [
          _CatChip(
            label: 'All',
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          ..._roomTypeOptions.map(
            (c) => _CatChip(
              label: c.$2,
              active: selected == c.$1,
              onTap: () => onSelect(selected == c.$1 ? null : c.$1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.customerPrimary : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: active ? AppColors.customerPrimary : AppColors.grey100,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}
