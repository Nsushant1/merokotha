import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:merokotha/features/admin/providers/admin_providers.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class AdminListingsScreen extends ConsumerStatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  ConsumerState<AdminListingsScreen> createState() =>
      _AdminListingsScreenState();
}

class _AdminListingsScreenState extends ConsumerState<AdminListingsScreen> {
  ListingStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(allListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const AdminAppBar(title: 'All listings', showBack: false),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AdminColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filterStatus == null,
                    onTap: () => setState(() => _filterStatus = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    isSelected: _filterStatus == ListingStatus.active,
                    onTap: () =>
                        setState(() => _filterStatus = ListingStatus.active),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Paused',
                    isSelected: _filterStatus == ListingStatus.paused,
                    onTap: () =>
                        setState(() => _filterStatus = ListingStatus.paused),
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Rented',
                    isSelected: _filterStatus == ListingStatus.rented,
                    onTap: () =>
                        setState(() => _filterStatus = ListingStatus.rented),
                    color: AppColors.grey400,
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: listingsAsync.when(
              loading: () => ShimmerLoading(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, _) => ShimmerBox(
                    height: 84,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
              ),
              error: (e, _) => MkErrorWidget(message: e.toString()),
              data: (all) {
                final listings = _filterStatus == null
                    ? all
                    : all.where((l) => l.status == _filterStatus).toList();

                if (listings.isEmpty) {
                  return MkEmptyState(
                    title: 'No listings found',
                    subtitle: _filterStatus != null
                        ? 'No ${_filterStatus!.name} listings'
                        : 'No listings on the platform yet',
                    icon: Icons.home_work_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: listings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final l = listings[i];
                    return AdminListingTile(
                      listing: l,
                      onDelete: () => _confirmDelete(context, ref, l),
                      onToggleStatus: () => ref
                          .read(adminActionProvider.notifier)
                          .setListingStatus(
                            l.id,
                            l.isActive
                                ? ListingStatus.paused
                                : ListingStatus.active,
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ListingModel l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('Delete "${l.title}"? This cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminActionProvider.notifier).deleteListing(l.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminColors.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? c : AdminColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: isSelected ? c : Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AdminColors.primary : AppColors.grey400,
            ),
          ),
        ),
      ),
    );
  }
}
