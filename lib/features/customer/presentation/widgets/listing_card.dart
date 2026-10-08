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
import 'package:merokotha/shared/widgets/status_badge.dart';

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
                              height: 132,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const ShimmerLoading(
                                child: ShimmerBox(
                                  height: 132,
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
                      child: ListingTypeBadge(
                        label: _saleOrRentLabel,
                        forSale: _isForSale,
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
                                ? AppColors.accent
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
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (listing.address != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${listing.address!} · ${listing.roomTypeLabel}',
                              style: textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: PriceBadge(amount: listing.rentPerMonth),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            listing.furnishingLabel,
                            style: textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
    height: 132,
    color: AppColors.primaryLight,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 40, color: AppColors.grey400),
    ),
  );

  /// Sale vs rent heuristic until backend adds an explicit flag:
  /// land reads as For Sale (red), everything else as For Rent (blue),
  /// matching the design.jpeg listing badges.
  bool get _isForSale => listing.roomType == 'land';

  String get _saleOrRentLabel => _isForSale ? 'For Sale' : 'For Rent';
}

/// Horizontal listing row matching design.jpeg Houses / Land / Beach lists:
/// 120px photo left with red/blue badge, title + location + red price
/// right, heart action. Dense, scannable, responsive.
class ListingRow extends StatelessWidget {
  final ListingModel listing;
  final bool isFavourited;
  final VoidCallback? onFavourite;
  final VoidCallback? onTap;

  const ListingRow({
    super.key,
    required this.listing,
    this.isFavourited = false,
    this.onFavourite,
    this.onTap,
  });

  bool get _isForSale => listing.roomType == 'land';

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
          constraints: const BoxConstraints(minHeight: 148),
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: listing.photoUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.photoUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                                  Container(color: AppColors.primaryLight),
                              errorWidget: (_, _, _) => Container(
                                color: AppColors.primaryLight,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.grey400,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.primaryLight,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.grey400,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: ListingTypeBadge(
                      label: _isForSale ? 'For Sale' : 'For Rent',
                      forSale: _isForSale,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.address ?? listing.roomTypeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    PriceBadge(
                      amount: listing.rentPerMonth,
                      showPerMonth: true,
                      fontSize: 15,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onFavourite,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Icon(
                    isFavourited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 19,
                    color: isFavourited ? AppColors.accent : AppColors.grey400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
