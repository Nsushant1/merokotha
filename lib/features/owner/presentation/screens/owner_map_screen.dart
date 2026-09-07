import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:merokotha/shared/widgets/mk_map_button.dart';
import 'package:merokotha/shared/widgets/owner_bottom_nav.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/features/owner/providers/owner_providers.dart';

class OwnerMapScreen extends ConsumerStatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  ConsumerState<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends ConsumerState<OwnerMapScreen> {
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
        width: 44,
        height: 52,
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedListing = _selectedListing?.id == l.id ? null : l;
          }),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ownerPrimary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ownerPrimary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.house_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.ownerPrimary,
                ),
              ),
              CustomPaint(
                size: const Size(10, 5),
                painter: _TrianglePainter(
                  color: isSelected ? AppColors.ownerPrimary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _fitAllMarkers(List<ListingModel> listings) {
    final points = listings
        .where((l) => l.geoPoint != null)
        .map((l) => LatLng(l.geoPoint!.latitude, l.geoPoint!.longitude))
        .toList();

    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 13);
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(ownerListingsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          listingsAsync.when(
            loading: () => const MkLoading(),
            error: (e, _) => MkErrorWidget(message: e.toString()),
            data: (listings) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _fitAllMarkers(listings),
              );

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _kathmandu,
                  initialZoom: 13,
                  maxZoom: 19,
                  minZoom: 8,
                  onTap: (_, _) => setState(() => _selectedListing = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.merokotha.app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(markers: _buildMarkers(listings)),
                ],
              );
            },
          ),

          // ── Top bar ──
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
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: AppSizes.shadowCard,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.house_rounded,
                          size: 16,
                          color: AppColors.ownerPrimary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'My listing locations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                MkMapButton(
                  icon: Icons.add_location_alt_outlined,
                  onTap: () => context.go(AppRoutes.uploadListing),
                ),
              ],
            ),
          ),

          // ── Listing count pill ──
          listingsAsync.when(
            data: (listings) {
              final count = listings.where((l) => l.geoPoint != null).length;
              return Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ownerPrimary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: const [
                        BoxShadow(color: Color(0x331D9E75), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      count == 0
                          ? 'No pinned listings'
                          : '$count listing${count == 1 ? '' : 's'} on map',
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

          // ── No listings hint ──
          listingsAsync.when(
            data: (listings) {
              if (listings.any((l) => l.geoPoint != null)) {
                return const SizedBox.shrink();
              }
              return Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    boxShadow: AppSizes.shadowRaised,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_location_alt_rounded,
                          size: 26,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No listing locations yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add a listing with a map pin and it will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.grey400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MkButton(
                        label: 'Add listing',
                        onPressed: () => context.go(AppRoutes.uploadListing),
                        height: 44,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // ── Selected listing bottom card ──
          if (_selectedListing != null)
            Positioned(
              bottom: 90,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: AppSizes.shadowRaised,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: _selectedListing!.photoUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _selectedListing!.photoUrls.first,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.backgroundSecondary,
                              ),
                              errorWidget: (_, _, _) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.backgroundSecondary,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.grey200,
                                ),
                              ),
                            )
                          : Container(
                              width: 64,
                              height: 64,
                              color: AppColors.backgroundSecondary,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.grey200,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedListing!.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          PriceBadge(amount: _selectedListing!.rentPerMonth),
                          const SizedBox(height: 4),
                          StatusBadge.fromListingStatus(_selectedListing!.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 4),
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

