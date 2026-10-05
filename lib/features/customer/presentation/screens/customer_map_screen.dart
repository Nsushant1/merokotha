import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/widgets/mk_map_button.dart';

import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class CustomerMapScreen extends ConsumerStatefulWidget {
  const CustomerMapScreen({super.key});

  @override
  ConsumerState<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends ConsumerState<CustomerMapScreen> {
  final _mapController = MapController();
  ListingModel? _selectedListing;

  static const _kathmandu = LatLng(27.7172, 85.3240);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.where((l) => l.geoPoint != null).map((l) {
      final isSelected = _selectedListing?.id == l.id;
      return Marker(
        point: LatLng(l.geoPoint!.latitude, l.geoPoint!.longitude),
        width: isSelected ? 90 : 80,
        height: isSelected ? 44 : 38,
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedListing = _selectedListing?.id == l.id ? null : l;
          }),
          child: _PriceMarker(price: l.rentPerMonth, isSelected: isSelected),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(mapListingsProvider);
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];

    return Scaffold(
      body: Stack(
        children: [
          listingsAsync.when(
            loading: () => const MkLoading(fullScreen: false),
            error: (e, _) => MkErrorWidget(message: e.toString()),
            data: (listings) => FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _kathmandu,
                initialZoom: 13,
                maxZoom: 19,
                minZoom: 8,
                onTap: (_, _) => setState(() => _selectedListing = null),
              ),
              children: [
                // OSM tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.merokotha.app',
                  maxZoom: 19,
                ),
                // Price markers
                MarkerLayer(markers: _buildMarkers(listings)),
              ],
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                MkMapButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.search),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: AppColors.grey400,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Search on map...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MkMapButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _mapController.move(_kathmandu, 14),
                ),
              ],
            ),
          ),

          listingsAsync.when(
            data: (listings) {
              final count = listings.where((l) => l.geoPoint != null).length;
              return Positioned(
                top: MediaQuery.of(context).padding.top + 62,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.customerPrimary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.customerPrimary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '$count room${count == 1 ? '' : 's'} on map',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          if (_selectedListing != null)
            Positioned(
              bottom: 90,
              left: 12,
              right: 12,
              child: _ListingPreviewCard(
                listing: _selectedListing!,
                isFavourited: favIds.contains(_selectedListing!.id),
                onFavourite: () => ref
                    .read(favouriteProvider.notifier)
                    .toggle(_selectedListing!),
                onTap: () => context.push(
                  AppRoutes.roomDetail.replaceAll(':id', _selectedListing!.id),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
    );
  }
}

class _PriceMarker extends StatelessWidget {
  final double price;
  final bool isSelected;

  const _PriceMarker({required this.price, required this.isSelected});

  String get _label => 'NPR ${Formatters.amount(price)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.customerPrimary : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.customerPrimary : AppColors.grey200,
              width: isSelected ? 0 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.1),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _label,
            style: TextStyle(
              fontSize: isSelected ? 13 : 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.grey900,
            ),
          ),
        ),
        // Triangle pointer
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(
            color: isSelected ? AppColors.customerPrimary : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

class _ListingPreviewCard extends StatelessWidget {
  final ListingModel listing;
  final bool isFavourited;
  final VoidCallback onFavourite;
  final VoidCallback onTap;

  const _ListingPreviewCard({
    required this.listing,
    required this.isFavourited,
    required this.onFavourite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: AppSizes.shadowRaised,
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: listing.photoUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: listing.photoUrls.first,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => ShimmerLoading(
                        child: ShimmerBox(width: 76, height: 76, borderRadius: BorderRadius.zero),
                      ),
                      errorWidget: (_, _, _) => _imgPlaceholder,
                    )
                  : _imgPlaceholder,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (listing.address != null)
                    Text(
                      listing.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PriceBadge(amount: listing.rentPerMonth),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: Text(
                          listing.roomTypeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Fav button
            GestureDetector(
              onTap: onFavourite,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFavourited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavourited ? AppColors.error : AppColors.grey400,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _imgPlaceholder => Container(
    width: 76,
    height: 76,
    color: AppColors.grey50,
    child: const Icon(Icons.image_outlined, color: AppColors.grey100, size: 28),
  );
}

