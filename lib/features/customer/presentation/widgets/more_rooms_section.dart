import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/core/utils/responsive.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/login_sheet.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class MoreRoomsSection extends ConsumerWidget {
  final String excludeListingId;

  const MoreRoomsSection({super.key, required this.excludeListingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync = ref.watch(similarListingsProvider(excludeListingId));
    final userAsync = ref.watch(currentUserProvider);
    final textTheme = Theme.of(context).textTheme;

    return similarAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();

        final columns = MkBreakpoints.isMobile(context) ? 2 : 3;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'More rooms for you',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${listings.length} found',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemCount: listings.length,
                itemBuilder: (ctx, i) {
                  final listing = listings[i];
                  final isFav = ref.watch(
                    isListingFavouritedProvider(listing.id),
                  );
                  return _RoomGridCard(
                    listing: listing,
                    isFav: isFav,
                    onFavourite: () {
                      if (userAsync.asData?.value == null) {
                        showLoginSheet(context);
                        return;
                      }
                      ref.read(favouriteProvider.notifier).toggle(listing);
                    },
                    onTap: () => context.push(
                      AppRoutes.roomDetail.replaceAll(':id', listing.id),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Responsive grid card — unified card system ───────────────────────────────

class _RoomGridCard extends StatelessWidget {
  final ListingModel listing;
  final bool isFav;
  final VoidCallback onFavourite;
  final VoidCallback onTap;

  const _RoomGridCard({
    required this.listing,
    required this.isFav,
    required this.onFavourite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppSizes.radiusLg);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: AppDecorations.card,
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo with rounded top corners
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    listing.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.photoUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                const ShimmerLoading(child: ShimmerBox()),
                            errorWidget: (_, _, _) => _placeholder,
                          )
                        : _placeholder,

                    // Room type badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          listing.roomTypeLabel,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.grey900,
                          ),
                        ),
                      ),
                    ),

                    // Favourite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavourite,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                            boxShadow: AppSizes.shadowCard,
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFav
                                ? AppColors.error
                                : AppColors.grey400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info section
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(fontSize: 14),
                          ),
                          if (listing.address != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 12,
                                  color: AppColors.grey400,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    listing.address!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.npr(listing.rentPerMonth),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '/month',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.customerPrimary,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 15,
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
        ),
      ),
    );
  }

  Widget get _placeholder => Container(
        color: AppColors.surfaceContainer,
        child: const Center(
          child: Icon(
            Icons.home_outlined,
            size: 28,
            color: AppColors.grey200,
          ),
        ),
      );
}
