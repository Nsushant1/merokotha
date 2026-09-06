import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_hero.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_category_row.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_toggle_view.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_listing_cards.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  String _search = '';
  String? _category;
  bool _isGrid = false;

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(activeListingsProvider);
    final photosWithImages = listingsAsync.value
        ?.where((l) => l.photoUrls.isNotEmpty)
        .map((l) => l.photoUrls.first);
    final heroPhoto = (photosWithImages != null && photosWithImages.isNotEmpty)
        ? photosWithImages.first
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LandingTheme.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: LandingHero(
                photoUrl: heroPhoto,
                onSearchChanged: (v) => setState(() => _search = v.toLowerCase()),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: LandingCategoryRow(
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('AVAILABLE ROOMS', style: LandingTheme.labelSm),
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
                  final matchQ = _search.isEmpty ||
                      l.title.toLowerCase().contains(_search);
                  final matchC = _category == null || l.roomType == _category;
                  return matchQ && matchC;
                }).toList();

                if (listings.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(hasFilters: _search.isNotEmpty || _category != null),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: _isGrid
                      ? SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.62,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => LandingGridCard(
                              listing: listings[i],
                              onTap: () => context.push(
                                AppRoutes.roomDetail.replaceAll(
                                  ':id',
                                  listings[i].id,
                                ),
                              ),
                            ),
                            childCount: listings.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LandingListCard(
                                listing: listings[i],
                                onTap: () => context.push(
                                  AppRoutes.roomDetail.replaceAll(
                                    ':id',
                                    listings[i].id,
                                  ),
                                ),
                              ),
                            ),
                            childCount: listings.length,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: _SignInCta(
          onTap: () => context.go(AppRoutes.login),
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
        color: LandingTheme.surface,
        border: const Border(top: BorderSide(color: LandingTheme.hairline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: Material(
          color: LandingTheme.accent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: const Center(
              child: Text(
                'Sign in to inquire',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
                hasFilters ? Icons.search_off_rounded : Icons.home_work_outlined,
                size: 38,
                color: LandingTheme.accentMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No properties found' : 'No listings yet',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: LandingTheme.ink,
              ),
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
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: LandingTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: LandingTheme.bodyMd),
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
        childAspectRatio: 0.62,
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
                const Expanded(flex: 7, child: ShimmerBox(borderRadius: BorderRadius.zero)),
                Expanded(
                  flex: 3,
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
              height: 114,
              decoration: BoxDecoration(
                color: LandingTheme.surface,
                borderRadius: BorderRadius.circular(LandingTheme.r),
                border: Border.all(color: LandingTheme.hairline),
              ),
              clipBehavior: Clip.hardEdge,
              child: Row(
                children: [
                  const ShimmerBox(width: 114, height: 114, borderRadius: BorderRadius.zero),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
