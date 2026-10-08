import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_nav.dart';
import 'package:merokotha/features/admin/providers/ads_providers.dart';
import 'package:merokotha/shared/models/ad_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class AdminAdsScreen extends ConsumerWidget {
  const AdminAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(allAdsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const AdminAppBar(title: 'Banner ads', showBack: false),
      body: adsAsync.when(
        loading: () => ShimmerLoading(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, _) => ShimmerBox(
              height: 144,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
          ),
        ),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (ads) {
          if (ads.isEmpty) {
            return const MkEmptyState(
              title: 'No banner ads yet',
              subtitle:
                  'Create one with the + button. They show on landing + customer home.',
              icon: Icons.campaign_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: ads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _AdTile(ad: ads[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.adminAdForm),
        backgroundColor: AdminColors.accent,
        foregroundColor: AdminColors.primary,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }
}

class _AdTile extends ConsumerWidget {
  final AdModel ad;
  const _AdTile({required this.ad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (ad.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: ad.imageUrl,
              width: 112,
              height: 112,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                width: 112,
                height: 112,
                color: AppColors.grey100,
                child: const Icon(Icons.image_outlined),
              ),
            )
          else
            Container(
              width: 112,
              height: 112,
              color: AppColors.grey100,
              child: const Icon(Icons.campaign_outlined),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${ad.placement} · priority ${ad.priority} · ${ad.status}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.adminAdForm, extra: ad),
                        child: const Text('Edit'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(adsActionProvider.notifier)
                            .toggleStatus(ad.id, !ad.isActive),
                        child: Text(ad.isActive ? 'Pause' : 'Activate'),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete ad?'),
        content: Text('Delete "${ad.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adsActionProvider.notifier).delete(ad.id);
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
