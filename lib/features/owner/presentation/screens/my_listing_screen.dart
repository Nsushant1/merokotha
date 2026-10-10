import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/shared/widgets/owner_bottom_nav.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/owner/providers/owner_providers.dart';
import 'package:merokotha/features/owner/presentation/widgets/owner_widgets.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(ownerListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(
        title: 'My listings',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.uploadListing),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(ownerListingsProvider),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return MkEmptyState(
              title: 'No listings yet',
              subtitle: 'Add your first room to start receiving inquiries',
              icon: Icons.house_outlined,
              actionLabel: 'Add listing',
              onAction: () => context.push(AppRoutes.uploadListing),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(ownerListingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              itemCount: listings.length,
              separatorBuilder: (_, i) => const SizedBox(height: AppSizes.md),
              itemBuilder: (_, i) {
                final l = listings[i];
                return OwnerListingCard(
                  listing: l,
                  onStatusChange: (status) => ref
                      .read(listingStatusProvider.notifier)
                      .toggle(l.id, status),
                  onDelete: () => _confirmDelete(context, ref, l),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 1),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ListingModel l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: const Text(
          'Delete listing?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        content: Text(
          'Delete "${l.title}"? This cannot be undone.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey600,
            height: 1.4,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(listingStatusProvider.notifier).delete(l.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
