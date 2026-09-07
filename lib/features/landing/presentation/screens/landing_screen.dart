import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_category_row.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_toggle_view.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_listing_cards.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_search_bar.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: LandingTheme.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _LandingHeader(
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
                            childAspectRatio: 0.72,
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
          onTap: () => context.push(AppRoutes.login),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                Text(
                  'Mero Kotha',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: LandingTheme.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                _SignInChip(
                  onTap: () => context.push(AppRoutes.login),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Find your next\nhome in Nepal',
              style: GoogleFonts.dmSans(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: -0.8,
                color: LandingTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover rooms, flats & apartments across Nepal.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: LandingTheme.stone,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
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
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: LandingTheme.ink,
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
              height: 108,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LandingTheme.surface,
                borderRadius: BorderRadius.circular(LandingTheme.r),
                border: Border.all(color: LandingTheme.hairline),
              ),
              child: Row(
                children: [
                  const ShimmerBox(
                    width: 92,
                    height: 92,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  const SizedBox(width: 12),
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
