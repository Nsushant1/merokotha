import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/data/listings_repository.dart';
import 'package:merokotha/features/customer/data/saved_searches_repository.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:merokotha/shared/models/listing_model.dart'
    show FurnishingType;
import 'package:merokotha/shared/models/saved_search_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Saved filter combinations with matching + new-listing counts.
class SavedSearchesScreen extends ConsumerWidget {
  const SavedSearchesScreen({super.key});

  /// Converts a saved search back into a live [SearchFilter].
  SearchFilter _toFilter(SavedSearchModel s) => SearchFilter(
    query: s.query,
    categoryL1Id: s.roomType,
    furnishing: s.furnishing == null
        ? null
        : FurnishingType.values.firstWhere(
            (e) => e.name == s.furnishing,
            orElse: () => FurnishingType.unfurnished,
          ),
    minRent: s.minRent,
    maxRent: s.maxRent,
    facilities: s.facilities,
    verifiedOnly: s.verifiedOnly,
    sort: s.sort,
    lat: s.lat,
    lng: s.lng,
    radiusKm: s.radiusKm,
  );

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    SavedSearchModel s,
  ) async {
    final user = ref.read(authStateProvider).asData?.value;
    // Apply the saved filter to the live search, then open results.
    ref.read(searchFilterProvider.notifier).apply(_toFilter(s));
    if (user != null) {
      await ref
          .read(savedSearchesRepositoryProvider)
          .markSeen(user.uid, s.id);
    }
    if (context.mounted) context.push(AppRoutes.search);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(mySavedSearchesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'Saved searches'),
      body: savedAsync.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (searches) {
          if (searches.isEmpty) {
            return MkEmptyState(
              title: 'No saved searches',
              subtitle:
                  'Save a filter combination from Search to get here, with new-listing counts.',
              icon: Icons.bookmark_outline_rounded,
              actionLabel: 'Go to search',
              onAction: () => context.push(AppRoutes.search),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: searches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _SavedSearchTile(
              search: searches[i],
              onOpen: () => _open(context, ref, searches[i]),
              onDelete: () async {
                final user = ref.read(authStateProvider).asData?.value;
                if (user == null) return;
                await ref
                    .read(savedSearchesRepositoryProvider)
                    .deleteSearch(user.uid, searches[i].id);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 4),
    );
  }
}

class _SavedSearchTile extends ConsumerStatefulWidget {
  final SavedSearchModel search;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  const _SavedSearchTile({
    required this.search,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  ConsumerState<_SavedSearchTile> createState() => _SavedSearchTileState();
}

class _SavedSearchTileState extends ConsumerState<_SavedSearchTile> {
  late Future<(int, int)> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _loadCounts();
  }

  @override
  void didUpdateWidget(covariant _SavedSearchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search.lastCheckedAt != widget.search.lastCheckedAt) {
      _counts = _loadCounts();
    }
  }

  SearchFilter _toFilter() {
    final s = widget.search;
    return SearchFilter(
      query: s.query,
      categoryL1Id: s.roomType,
      furnishing: s.furnishing == null
          ? null
          : FurnishingType.values.firstWhere(
              (e) => e.name == s.furnishing,
              orElse: () => FurnishingType.unfurnished,
            ),
      minRent: s.minRent,
      maxRent: s.maxRent,
      facilities: s.facilities,
      verifiedOnly: s.verifiedOnly,
      sort: s.sort,
      lat: s.lat,
      lng: s.lng,
      radiusKm: s.radiusKm,
    );
  }

  Future<(int, int)> _loadCounts() async {
    final results = await ref
        .read(listingsRepositoryProvider)
        .searchListings(_toFilter());
    final since = widget.search.lastCheckedAt;
    final fresh = since == null
        ? results.length
        : results.where((l) => l.createdAt.isAfter(since)).length;
    return (results.length, fresh);
  }

  @override
  Widget build(BuildContext context) {
    final search = widget.search;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppSizes.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        search.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        search.summary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<(int, int)>(
                        future: _counts,
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Text(
                              'Counting matches…',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey400,
                              ),
                            );
                          }
                          final counts = snap.data!;
                          return Text(
                            '${counts.$1} match${counts.$1 == 1 ? '' : 'es'}'
                            '${counts.$2 > 0 ? ' · ${counts.$2} new' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: counts.$2 > 0
                                  ? AppColors.accent
                                  : AppColors.grey600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
