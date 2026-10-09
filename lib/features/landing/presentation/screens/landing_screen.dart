import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/responsive.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_feed.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_category_row.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_listing_cards.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_search_bar.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_toggle_view.dart';
import 'package:merokotha/shared/widgets/promo_banner_carousel.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  String _search = '';
  String? _category;
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(activeListingsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: _LandingHeader(
                  onSearchChanged: (v) =>
                      setState(() => _search = v.toLowerCase()),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Promo banner — same reusable carousel as Customer Home,
            // immediately below the search header. 3s auto-scroll.
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: PromoBannerCarousel(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverToBoxAdapter(
              child: LandingCategoryRow(
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Featured Listings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    LandingToggleView(
                      isGrid: _isGrid,
                      onToggle: () => setState(() => _isGrid = !_isGrid),
                    ),
                  ],
                ),
              ),
            ),

            listingsAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: _isGrid ? const _GridSkeleton() : const _ListSkeleton(),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(message: '$e'),
              ),
              data: (list) {
                final listings = list.where((l) {
                  final matchQ =
                      _search.isEmpty ||
                      l.title.toLowerCase().contains(_search);
                  final matchC = _category == null || l.roomType == _category;
                  return matchQ && matchC;
                }).toList();

                if (listings.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      hasFilters: _search.isNotEmpty || _category != null,
                    ),
                  );
                }

                final columns = MkBreakpoints.isDesktop(context)
                    ? 3
                    : MkBreakpoints.isTablet(context)
                    ? 3
                    : 2;
                void openDetail(String id) =>
                    context.push(AppRoutes.roomDetail.replaceAll(':id', id));
                // Same repeating pattern as the customer feed: chunks of 3
                // in list mode (4 in grid mode) with the custom Pitambari /
                // Floor Cleaner banners interleaved — no extra API calls,
                // rooms are only re-sliced from [listings].
                final blocks = buildRoomFeedBlocks(
                  listings,
                  verticalChunkSize: _isGrid ? 4 : 3,
                );
                final feedSlivers = <Widget>[];
                for (final block in blocks) {
                  switch (block) {
                    case RoomChunkBlock(:final rooms):
                      if (rooms.isEmpty) break;
                      feedSlivers.add(
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          sliver: _isGrid
                              ? SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 0.72,
                                      ),
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) => LandingGridCard(
                                      listing: rooms[i],
                                      onTap: () => openDetail(rooms[i].id),
                                    ),
                                    childCount: rooms.length,
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: LandingListCard(
                                        listing: rooms[i],
                                        onTap: () => openDetail(rooms[i].id),
                                      ),
                                    ),
                                    childCount: rooms.length,
                                  ),
                                ),
                        ),
                      );
                      feedSlivers.add(
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      );
                    case AdBlock():
                      feedSlivers.add(
                        const SliverToBoxAdapter(child: SizedBox(height: 4)),
                      );
                      feedSlivers.add(
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: InFeedPromoCarousel(),
                          ),
                        ),
                      );
                      feedSlivers.add(
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      );
                    case HorizontalGridBlock(:final rooms):
                      if (rooms.isEmpty) break;
                      feedSlivers.add(
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 248,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: rooms.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (_, i) => SizedBox(
                                width: 220,
                                child: LandingGridCard(
                                  listing: rooms[i],
                                  onTap: () => openDetail(rooms[i].id),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                      feedSlivers.add(
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      );
                  }
                }
                feedSlivers.add(
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                );
                return SliverMainAxisGroup(slivers: feedSlivers);
              },
            ),
          ],
        ),
        bottomNavigationBar: _SignInCta(
          onTap: () => context.push(AppRoutes.roleSelect),
        ),
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const _LandingHeader({required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/merokotha.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    children: const [
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
                ),
                const Spacer(),
                _SignInChip(onTap: () => context.push(AppRoutes.roleSelect)),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Find your next home.',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover rooms, flats & apartments across Nepal.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            LandingSearchBar(onChanged: onSearchChanged),
          ],
        ),
      ),
    );
  }
}

class _SignInChip extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: LandingTheme.bgWarm,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LandingTheme.hairline),
          ),
          child: Text(
            'Sign In',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.grey900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInCta extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: AppSizes.buttonHeight,
        child: Material(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40FF1F2D),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Get Started',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: LandingTheme.bgWarm,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.home_work_outlined,
                size: 38,
                color: LandingTheme.accentMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No properties found' : 'No listings yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try a different search term or category'
                  : 'New rooms and flats will show up here as owners list them',
              textAlign: TextAlign.center,
              style: LandingTheme.bodyMd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 38, color: LandingTheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LandingTheme.bodyMd,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => ShimmerLoading(
          child: Container(
            decoration: BoxDecoration(
              color: LandingTheme.surface,
              borderRadius: BorderRadius.circular(LandingTheme.r),
              border: Border.all(color: LandingTheme.hairline),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                const Expanded(
                  flex: 6,
                  child: ShimmerBox(borderRadius: BorderRadius.zero),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        ShimmerBox(width: 90, height: 12),
                        SizedBox(height: 8),
                        ShimmerBox(width: 60, height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        childCount: 6,
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoading(
            child: Container(
              height: 152,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LandingTheme.surface,
                borderRadius: BorderRadius.circular(LandingTheme.r),
                border: Border.all(color: LandingTheme.hairline),
              ),
              child: Row(
                children: [
                  const ShimmerBox(
                    width: 120,
                    height: 124,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          ShimmerBox(width: 120, height: 13),
                          SizedBox(height: 8),
                          ShimmerBox(width: 80, height: 11),
                          SizedBox(height: 10),
                          ShimmerBox(width: 70, height: 13),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        childCount: 4,
      ),
    );
  }
}
