import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/models/listing_model.dart';

class OwnerListingCard extends StatelessWidget {
  final ListingModel listing;
  final void Function(ListingStatus) onStatusChange;
  final VoidCallback onDelete;

  const OwnerListingCard({
    super.key,
    required this.listing,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = listing.status == ListingStatus.active;
    final isRented = listing.status == ListingStatus.rented;

    Color statusColor;
    String statusLabel;
    if (isActive) {
      statusColor = AppColors.success;
      statusLabel = 'Active';
    } else if (isRented) {
      statusColor = AppColors.primary;
      statusLabel = 'Rented';
    } else {
      statusColor = AppColors.warning;
      statusLabel = 'Paused';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: AppSizes.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: listing.photoUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.photoUrls.first,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        placeholder: (context, url) =>
                            const _ImagePlaceholder(),
                        errorWidget: (context, url, error) =>
                            const _ImagePlaceholder(),
                      )
                    : const _ImagePlaceholder(),
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        listing.address ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs ${listing.rentPerMonth.toStringAsFixed(0)}/mo',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        _IconBtn(
                          icon: Icons.visibility_outlined,
                          color: AppColors.info,
                          onTap: () => context.push(
                            AppRoutes.roomDetail.replaceAll(':id', listing.id),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _IconBtn(
                          icon: Icons.edit_outlined,
                          color: AppColors.grey600,
                          onTap: () => context.push(
                            AppRoutes.uploadListing,
                            extra: listing,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusMenuBtn(
                          listing: listing,
                          onStatusChange: onStatusChange,
                        ),
                        const SizedBox(width: 6),
                        _IconBtn(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.error,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMenuBtn extends StatelessWidget {
  final ListingModel listing;
  final void Function(ListingStatus) onStatusChange;

  const _StatusMenuBtn({
    required this.listing,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    if (listing.status == ListingStatus.rented) {
      return _IconBtn(
        icon: Icons.home_rounded,
        color: AppColors.primary,
        onTap: () => onStatusChange(ListingStatus.active),
        tooltip: 'Mark as Available',
      );
    }

    final isActive = listing.status == ListingStatus.active;
    final iconColor = isActive ? AppColors.warning : AppColors.success;
    final icon = isActive
        ? Icons.pause_circle_outline_rounded
        : Icons.play_circle_outline_rounded;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<ListingStatus>(
        onSelected: onStatusChange,
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, size: 16, color: iconColor),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: isActive ? ListingStatus.paused : ListingStatus.active,
            child: Text(isActive ? 'Pause listing' : 'Resume listing'),
          ),
          const PopupMenuItem(
            value: ListingStatus.rented,
            child: Text('Mark as Rented'),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.grey50,
      child: const Icon(
        Icons.house_outlined,
        size: 48,
        color: AppColors.grey400,
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
