import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/customer/data/listings_repository.dart'
    show SearchFilter;
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
        toolbarHeight: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by location, property type...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8AA0BE)),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (v) => notifier.setQuery(v),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _showFilters || filter.hasActiveFilters
                          ? AppColors.accent
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _showFilters || filter.hasActiveFilters
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14063B7A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _showFilters ? Icons.tune_rounded : Icons.tune_outlined,
                      size: 20,
                      color: _showFilters || filter.hasActiveFilters
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (filter.hasActiveFilters && !_showFilters)
                  Positioned(
                    right: 2,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
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
                  itemCount: validListings.length + 1,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${validListings.length} ${validListings.length == 1 ? 'place' : 'places'} found',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    final l = validListings[i - 1];
                    return ListingRow(
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
          height: 148,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: AppSizes.shadowCard,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 120,
                height: 120,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      height: 14,
                      width: 140,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 10),
                    ShimmerBox(
                      height: 12,
                      width: 90,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 10),
                    ShimmerBox(
                      height: 12,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — bold title + red Reset (design.jpeg Filters).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: notifier.reset,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(48, 32),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _FilterLabel('Property Type'),
          const SizedBox(height: 10),
          _PropertyTypeChips(
            selected: filter.categoryL1Id,
            onChanged: (id) => notifier.setCategory(categoryL1Id: id),
          ),
          const SizedBox(height: 20),
          const _FilterLabel('Price Range'),
          const SizedBox(height: 4),
          PriceRangeSlider(
            minValue: filter.minRent,
            maxValue: filter.maxRent,
            onChanged: (min, max) {
              notifier.setMinRent(min);
              notifier.setMaxRent(max);
            },
          ),

          const SizedBox(height: 16),

          const _FilterLabel('Features'),
          const SizedBox(height: 10),
          FacilityFilterRow(
            selected: filter.facilities,
            onChanged: notifier.setFacilities,
          ),

          const SizedBox(height: 20),

          // Sticky CTA — solid red (design Filters).
          MkButton(label: 'Apply Filters', onPressed: onClose, height: 52),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.1,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PropertyTypeChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _PropertyTypeChips({required this.selected, required this.onChanged});

  static const _types = [
    ('house', 'House'),
    ('apartment', 'Apartment'),
    ('flat', 'Flat'),
    ('room', 'Room'),
    ('land', 'Land'),
    ('shop', 'Shop'),
    ('office', 'Commercial'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TypeChip(
          label: 'All',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final t in _types)
          _TypeChip(
            label: t.$2,
            selected: selected == t.$1,
            onTap: () => onChanged(selected == t.$1 ? null : t.$1),
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33FF1F2D),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
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
