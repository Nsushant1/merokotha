import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/price_badge.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

/// Customer listing card — rebuilt on the unified card system to match
/// landing cards exactly: white, 20px radius, hairline border, 10px
/// media inset, 14px body, DM Sans-only type.
/// Behavior unchanged: [onTap] navigates to detail, [onFavourite]
/// toggles favourite.
class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final bool isFavourited;
  final VoidCallback? onFavourite;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    required this.listing,
    this.isFavourited = false,
    this.onFavourite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppSizes.radiusLg);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap:
            onTap ??
            () => context.push(
              AppRoutes.roomDetail.replaceAll(':id', listing.id),
            ),
        borderRadius: radius,
        child: Container(
          decoration: AppDecorations.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: listing.photoUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.photoUrls.first,
                              height: 168,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const ShimmerLoading(
                                child: ShimmerBox(
                                  height: 168,
                                  width: double.infinity,
                                ),
                              ),
                              errorWidget: (_, _, _) => _photoPlaceholder,
                            )
                          : _photoPlaceholder,
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          listing.roomTypeLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.grey800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavourite,
                        child: Container(
                          width: 36,
                          height: 36,
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
                            isFavourited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFavourited
                                ? AppColors.error
                                : AppColors.grey400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (listing.address != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.address!,
                              style: textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PriceBadge(amount: listing.rentPerMonth),
                        Flexible(
                          child: Text(
                            listing.furnishingLabel,
                            style: textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
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

  Widget get _photoPlaceholder => Container(
    height: 168,
    color: AppColors.surfaceContainer,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 40, color: AppColors.grey200),
    ),
  );
}
