import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/theme/app_decorations.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';
import 'package:merokotha/shared/models/listing_model.dart';

/// Public listing cards — rebuilt on the unified card system:
/// white surface, 20px radius, hairline border, soft shadow,
/// DM Sans-only type (title 15 w700, meta 13, price 16 w800).
/// Navigation/behavior unchanged: tap still routes via [onTap].
class LandingGridCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;

  const LandingGridCard({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(LandingTheme.r);
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
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    listing.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.photoUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const _MediaPlaceholder(),
                            errorWidget: (_, _, _) => const _PhotoFallback(),
                          )
                        : const _PhotoFallback(),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _TypeBadge(text: listing.roomTypeLabel),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _PriceTag(amount: listing.rentPerMonth),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.address ?? 'Nepal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
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
}

class LandingListCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;

  const LandingListCard({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(LandingTheme.r);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 136,
          padding: const EdgeInsets.all(12),
          decoration: AppDecorations.card,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: listing.photoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.photoUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const _MediaPlaceholder(),
                          errorWidget: (_, _, _) => const _PhotoFallback(),
                        )
                      : const _PhotoFallback(),
                ),
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
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.address ?? 'Kathmandu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Rs. ${LandingTheme.formatPrice(listing.rentPerMonth)}',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(width: 4),
                        Text('/month', style: textTheme.bodySmall),
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
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.surfaceContainer);
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundSecondary,
      child: const Center(
        child: Icon(
          Icons.home_outlined,
          color: AppColors.grey400,
          size: 28,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String text;
  const _TypeBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final double amount;
  const _PriceTag({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppSizes.shadowCard,
      ),
      child: Text(
        'Rs. ${LandingTheme.formatPrice(amount)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.grey900,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
