import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/i18n/localization.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/data/listings_repository.dart'
    show SearchFilter;
import 'package:merokotha/features/customer/data/saved_searches_repository.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/customer/providers/room_view_mode_provider.dart';
import 'package:merokotha/shared/models/listing_model.dart' show FurnishingType;
import 'package:merokotha/shared/models/saved_search_model.dart'
    show ListingSort, SavedSearchModel;
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
    final isGrid = ref.watch(roomViewModeProvider);

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
            decoration: InputDecoration(
              hintText: tr(ref, 'home_search_hint'),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8AA0BE)),
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
                    title: tr(ref, 'search_no_results'),
                    subtitle: tr(ref, 'search_no_results_sub'),
                    icon: Icons.search_off_rounded,
                    actionLabel: tr(ref, 'search_clear_filters'),
                    onAction: () {
                      notifier.reset();
                      _searchCtrl.clear();
                    },
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.pagePadding,
                          AppSizes.pagePadding,
                          AppSizes.pagePadding,
                          12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RoomSectionHeader(
                              title:
                                  '${validListings.length} ${validListings.length == 1 ? tr(ref, 'search_result') : tr(ref, 'search_results')}',
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                              isGrid: isGrid,
                              onToggle: () => ref
                                  .read(roomViewModeProvider.notifier)
                                  .toggle(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _SaveSearchButton(filter: filter),
                            ),
                          ],
                        ),
                      ),
                    ),
                    RoomFeedSlivers(
                      listings: validListings,
                      isGrid: isGrid,
                      favouriteIds: favIds,
                      onFavourite: (l) =>
                          ref.read(favouriteProvider.notifier).toggle(l),
                      onTap: (l) => context.push(
                        AppRoutes.roomDetail.replaceAll(':id', l.id),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSizes.pagePadding),
                    ),
                  ],
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

class _FilterPanel extends ConsumerWidget {
  final SearchFilter filter;
  final SearchFilterNotifier notifier;
  final VoidCallback onClose;

  const _FilterPanel({
    required this.filter,
    required this.notifier,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text(
                tr(ref, 'common_filters'),
                style: const TextStyle(
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
                child: Text(tr(ref, 'common_reset')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterLabel(tr(ref, 'search_property_type')),
          const SizedBox(height: 10),
          _PropertyTypeChips(
            selected: filter.categoryL1Id,
            onChanged: (id) => notifier.setCategory(categoryL1Id: id),
          ),
          const SizedBox(height: 20),
          _FilterLabel(tr(ref, 'search_price_range')),
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

          _FilterLabel(tr(ref, 'search_furnishing')),
          const SizedBox(height: 10),
          _FurnishingChips(
            selected: filter.furnishing,
            onChanged: notifier.setFurnishing,
          ),

          const SizedBox(height: 16),

          _FilterLabel(tr(ref, 'search_features')),
          const SizedBox(height: 10),
          FacilityFilterRow(
            selected: filter.facilities,
            onChanged: notifier.setFacilities,
          ),

          const SizedBox(height: 16),

          _VerifiedOnlyRow(
            value: filter.verifiedOnly,
            onChanged: notifier.setVerifiedOnly,
          ),

          const SizedBox(height: 16),

          _FilterLabel(tr(ref, 'search_sort')),
          const SizedBox(height: 10),
          _SortDropdown(sort: filter.sort, onChanged: notifier.setSort),

          const SizedBox(height: 16),

          _FilterLabel(tr(ref, 'search_nearby')),
          const SizedBox(height: 10),
          _NearbyRow(filter: filter, notifier: notifier),

          const SizedBox(height: 20),

          // Sticky CTA — solid red (design Filters).
          MkButton(
            label: tr(ref, 'common_apply'),
            onPressed: onClose,
            height: 52,
          ),
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

class _ActiveFiltersBar extends StatelessWidget {  final SearchFilter filter;
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
    if (f.furnishing != null) parts.add(f.furnishing!.name);
    if (f.verifiedOnly) parts.add('Verified only');
    if (f.radiusKm != null) parts.add('within ${f.radiusKm!.toStringAsFixed(0)} km');
    return parts.join(' · ');
  }
}

/// Furnishing filter chips (All / Furnished / Semi / Unfurnished).
class _FurnishingChips extends ConsumerWidget {
  final FurnishingType? selected;
  final ValueChanged<FurnishingType?> onChanged;
  const _FurnishingChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget chip(String label, FurnishingType? value) => _TypeChip(
      label: label,
      selected: selected == value,
      onTap: () => onChanged(selected == value ? null : value),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TypeChip(
          label: tr(ref, 'common_all'),
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        chip(tr(ref, 'search_furnished'), FurnishingType.furnished),
        chip(tr(ref, 'search_semi'), FurnishingType.semiFurnished),
        chip(tr(ref, 'search_unfurnished'), FurnishingType.unfurnished),
      ],
    );
  }
}

/// Verified-only toggle.
class _VerifiedOnlyRow extends ConsumerWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _VerifiedOnlyRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(
          Icons.verified_outlined,
          size: 20,
          color: AppColors.success,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tr(ref, 'search_verified_only'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Sort selector.
class _SortDropdown extends ConsumerWidget {
  final ListingSort sort;
  final ValueChanged<ListingSort> onChanged;
  const _SortDropdown({required this.sort, required this.onChanged});

  String _label(WidgetRef ref, ListingSort s) {
    switch (s) {
      case ListingSort.newest:
        return tr(ref, 'search_sort_newest');
      case ListingSort.priceAsc:
        return tr(ref, 'search_sort_price_asc');
      case ListingSort.priceDesc:
        return tr(ref, 'search_sort_price_desc');
      case ListingSort.mostViewed:
        return tr(ref, 'search_sort_viewed');
      case ListingSort.nearest:
        return tr(ref, 'search_sort_nearest');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonFormField<ListingSort>(
      value: sort,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: ListingSort.values
          .map((s) => DropdownMenuItem(value: s, child: Text(_label(ref, s))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Nearby filter: use device location + radius chips.
class _NearbyRow extends ConsumerStatefulWidget {
  final SearchFilter filter;
  final SearchFilterNotifier notifier;
  const _NearbyRow({required this.filter, required this.notifier});

  @override
  ConsumerState<_NearbyRow> createState() => _NearbyRowState();
}

class _NearbyRowState extends ConsumerState<_NearbyRow> {
  bool _busy = false;

  Future<void> _useLocation(double radiusKm) async {
    setState(() => _busy = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      widget.notifier.setNearby(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusKm: radiusKm,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filter;
    if (f.radiusKm != null) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text('Within ${f.radiusKm!.toStringAsFixed(0)} km'),
            deleteIcon: const Icon(Icons.close_rounded, size: 16),
            onDeleted: widget.notifier.clearNearby,
          ),
          for (final r in [2.0, 5.0, 10.0])
            if (r != f.radiusKm)
              _TypeChip(
                label: '${r.toStringAsFixed(0)} km',
                selected: false,
                onTap: () => _useLocation(r),
              ),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TypeChip(
          label: _busy ? 'Locating…' : tr(ref, 'search_use_location'),
          selected: false,
          onTap: _busy ? () {} : () => _useLocation(5),
        ),
        for (final r in [2.0, 5.0, 10.0])
          _TypeChip(
            label: '${r.toStringAsFixed(0)} km',
            selected: false,
            onTap: _busy ? () {} : () => _useLocation(r),
          ),
      ],
    );
  }
}

/// Save-current-search button + dialog, shown above results.
class _SaveSearchButton extends ConsumerStatefulWidget {
  final SearchFilter filter;
  const _SaveSearchButton({required this.filter});

  @override
  ConsumerState<_SaveSearchButton> createState() => _SaveSearchButtonState();
}

class _SaveSearchButtonState extends ConsumerState<_SaveSearchButton> {
  bool _busy = false;

  Future<void> _save() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save searches.')),
      );
      return;
    }
    final nameCtrl = TextEditingController(
      text: widget.filter.query ?? widget.filter.categoryL1Id ?? 'My search',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save search'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameCtrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final f = widget.filter;
      await ref
          .read(savedSearchesRepositoryProvider)
          .saveSearch(
            user.uid,
            SavedSearchModel(
              id: '',
              name: name,
              query: f.query,
              roomType: f.categoryL1Id,
              furnishing: f.furnishing?.name,
              minRent: f.minRent,
              maxRent: f.maxRent,
              facilities: f.facilities,
              verifiedOnly: f.verifiedOnly,
              sort: f.sort,
              lat: f.lat,
              lng: f.lng,
              radiusKm: f.radiusKm,
              lastCheckedAt: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search saved.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _busy ? null : _save,
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bookmark_add_outlined, size: 16),
      label: Text(tr(ref, 'search_save'), style: const TextStyle(fontSize: 13)),
    );
  }
}
