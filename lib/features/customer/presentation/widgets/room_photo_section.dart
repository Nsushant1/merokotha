import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class RoomPhotoSection extends StatelessWidget {
  final ListingModel listing;
  final int currentIndex;
  final void Function(int) onPageChanged;
  final bool isFavourited;
  final VoidCallback onFavourite;
  final VoidCallback onBack;

  const RoomPhotoSection({
    super.key,
    required this.listing,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isFavourited,
    required this.onFavourite,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final photos = listing.photoUrls;
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 268,
              child: photos.isNotEmpty
                  ? PageView.builder(
                      itemCount: photos.length,
                      onPageChanged: onPageChanged,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: photos[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, _) => ShimmerLoading(
                          child: ShimmerBox(
                            width: double.infinity,
                            height: 268,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        errorWidget: (_, _, _) => _placeholder,
                      ),
                    )
                  : _placeholder,
            ),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == currentIndex ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 26,
          child: _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 26,
          child: _CircleBtn(
            icon: isFavourited
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: isFavourited ? AppColors.error : AppColors.grey600,
            onTap: onFavourite,
          ),
        ),
      ],
    );
  }

  Widget get _placeholder => Container(
    height: 280,
    color: AppColors.grey50,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 64, color: AppColors.grey100),
    ),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const _CircleBtn({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
        ],
      ),
      child: Icon(icon, size: 18, color: iconColor ?? AppColors.grey600),
    ),
  );
}
