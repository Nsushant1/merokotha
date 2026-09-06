import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/customer/data/listings_repository.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final notifier = ref.read(searchFilterProvider.notifier);
    final resultsAsync = ref.watch(searchResultsProvider);
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.grey800,
          ),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Area, landmark, room type...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintStyle: TextStyle(fontSize: 15, color: AppColors.grey400),
          ),
          style: const TextStyle(fontSize: 15, color: AppColors.grey900),
          onChanged: (v) => notifier.setQuery(v),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.tune_rounded : Icons.tune_outlined,
                    color: filter.hasActiveFilters
                        ? AppColors.customerPrimary
                        : AppColors.grey600,
                  ),
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                ),
                if (filter.hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.customerPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey50),
        ),
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _showFilters
                ? _FilterPanel(
                    filter: filter,
                    notifier: notifier,
                    onClose: () => setState(() => _showFilters = false),
                  )
                : const SizedBox.shrink(),
          ),

          if (filter.hasActiveFilters)
            _ActiveFiltersBar(filter: filter, onClear: () => notifier.reset()),

          Expanded(
            child: resultsAsync.when(
              loading: () => const _SearchResultsSkeleton(),
              error: (e, _) => MkErrorWidget(message: e.toString()),
              data: (listings) {
                final validListings = listings
                    .where((l) => l.id.isNotEmpty)
                    .toList();

                if (validListings.isEmpty) {
                  return MkEmptyState(
                    title: 'No results found',
                    subtitle: 'Try different keywords or remove some filters',
                    icon: Icons.search_off_rounded,
                    actionLabel: 'Clear filters',
                    onAction: () {
                      notifier.reset();
                      _searchCtrl.clear();
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: validListings.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final l = validListings[i];
                    return ListingCard(
                      listing: l,
                      isFavourited: favIds.contains(l.id),
                      onFavourite: () =>
                          ref.read(favouriteProvider.notifier).toggle(l),
                      onTap: () => context.push(
                        AppRoutes.roomDetail.replaceAll(':id', l.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
    );
  }
}

class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: 110,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: AppSizes.shadowCard,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 90,
                height: 90,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 14, width: 140, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 10),
                    ShimmerBox(height: 12, width: 90, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 10),
                    ShimmerBox(height: 12, width: 70, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final SearchFilter filter;
  final SearchFilterNotifier notifier;
  final VoidCallback onClose;

  const _FilterPanel({
    required this.filter,
    required this.notifier,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              TextButton(
                onPressed: notifier.reset,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.customerPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Text(
            'Price range',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.grey800,
            ),
          ),
          PriceRangeSlider(
            minValue: filter.minRent,
            maxValue: filter.maxRent,
            onChanged: (min, max) {
              notifier.setMinRent(min);
              notifier.setMaxRent(max);
            },
          ),

          const SizedBox(height: 14),

          const Text(
            'Facilities',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.grey800,
            ),
          ),
          const SizedBox(height: 8),
          FacilityFilterRow(
            selected: filter.facilities,
            onChanged: notifier.setFacilities,
          ),

          const SizedBox(height: 14),

          // Done button
          MkButton(label: 'Apply filters', onPressed: onClose, height: 46),
        ],
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final SearchFilter filter;
  final VoidCallback onClear;
  const _ActiveFiltersBar({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.customerLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pagePadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: AppColors.customerPrimary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _summary(filter),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.customerPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.customerPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _summary(SearchFilter f) {
    final parts = <String>[];
    if (f.categoryL1Id != null) parts.add('Type: ${f.categoryL1Id}');
    if (f.minRent != null || f.maxRent != null) {
      final min = f.minRent != null
          ? 'NPR ${f.minRent!.toStringAsFixed(0)}'
          : '0';
      final max = f.maxRent != null
          ? 'NPR ${f.maxRent!.toStringAsFixed(0)}'
          : 'any';
      parts.add('$min – $max');
    }
    if (f.facilities.isNotEmpty) parts.add('${f.facilities.length} facilities');
    return parts.join(' · ');
  }
}
