import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/agent/presentation/widgets/agent_bottom_nav.dart';
import 'package:merokotha/features/agent/providers/agent_providers.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/owner/presentation/widgets/owner_widgets.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Rooms this agent posted on behalf of owners.
class AgentListingsScreen extends ConsumerWidget {
  const AgentListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final listingsAsync = ref.watch(agentListingsProvider);

    if (user?.isVerifiedAgent != true) {
      return Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: const MkAppBar(title: 'My listings', showBack: false),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: MkEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Awaiting admin verification',
            subtitle:
                'You can browse rooms for now. Your posted rooms will appear here after approval.',
          ),
        ),
        // Listings live under the Home section (no dedicated tab).
        bottomNavigationBar: const AgentBottomNav(currentIndex: 0),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(
        title: 'My listings',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.agentUpload),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(agentListingsProvider),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return MkEmptyState(
              title: 'No listings yet',
              subtitle:
                  'Post your first room on behalf of an owner to get started',
              icon: Icons.house_outlined,
              actionLabel: 'Post a room',
              onAction: () => context.push(AppRoutes.agentUpload),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(agentListingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              itemCount: listings.length,
              separatorBuilder: (_, i) => const SizedBox(height: AppSizes.md),
              itemBuilder: (_, i) {
                final l = listings[i];
                return OwnerListingCard(
                  listing: l,
                  editRoute: AppRoutes.agentUpload,
                  onStatusChange: (status) => ref
                      .read(agentListingStatusProvider.notifier)
                      .toggle(l.id, status),
                  onDelete: () => _confirmDelete(context, ref, l),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 0),
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
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900),
        ),
        content: Text(
          'Delete "${l.title}"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(agentListingStatusProvider.notifier).delete(l.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
