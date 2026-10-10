import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

/// Saved properties list matching design.jpeg list rows:
/// dense horizontal rows with red/blue badges + red prices.
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favListingsAsync = ref.watch(favouriteListingsProvider);
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'Saved Properties'),
      body: favListingsAsync.when(
        loading: () => ShimmerLoading(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, _) => Container(
              height: 148,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 120, height: 120),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerBox(height: 14, width: 140),
                        SizedBox(height: 8),
                        ShimmerBox(height: 12, width: 90),
                        SizedBox(height: 8),
                        ShimmerBox(height: 13, width: 70),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (listings) {
          if (listings.isEmpty) {
            return MkEmptyState(
              title: 'No saved places yet',
              subtitle:
                  'Tap the heart on any listing to save it here for later',
              icon: Icons.favorite_outline_rounded,
              actionLabel: 'Browse rooms',
              onAction: () => context.go(AppRoutes.customerHome),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: listings.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${listings.length} saved ${listings.length == 1 ? 'place' : 'places'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              final l = listings[i - 1];
              return ListingRow(
                listing: l,
                isFavourited: favIds.contains(l.id),
                onFavourite: () =>
                    ref.read(favouriteProvider.notifier).toggle(l),
                onTap: () =>
                    context.push(AppRoutes.roomDetail.replaceAll(':id', l.id)),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
    );
  }
}
