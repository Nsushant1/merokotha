import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/auth/providers/pending_inquiry_provider.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/login_sheet.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_photo_section.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_info_row.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_facilities_grid.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_owner_card.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_bottom_cta.dart';
import 'package:merokotha/features/customer/presentation/widgets/more_rooms_section.dart';
import 'package:merokotha/features/customer/presentation/widgets/room_static_map_preview.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const RoomDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailSkeleton extends StatelessWidget {
  const _RoomDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                height: 268,
                width: double.infinity,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 20),
              ShimmerBox(
                height: 22,
                width: 220,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              ShimmerBox(
                height: 14,
                width: 150,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 20),
              ShimmerBox(
                height: 26,
                width: 130,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              ShimmerBox(
                height: 14,
                width: double.infinity,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                height: 14,
                width: double.infinity,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                height: 14,
                width: 200,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _photoIndex = 0;

  /// Opens the room location in the device maps app, keeping the listing
  /// context (previously this just opened the generic in-app map).
  /// Falls back to the in-app map when no maps handler exists.
  Future<void> _openDirections(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (context.mounted) context.push(AppRoutes.customerMap);
  }

  @override
  void dispose() {
    // Leaving the room drops any unsent guest inquiry intent set via
    // Message Owner, so a later unrelated sign-in can't resume it.
    ref.read(pendingInquiryProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final isFav = ref.watch(isListingFavouritedProvider(widget.listingId));
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: listingAsync.when(
        loading: () => const _RoomDetailSkeleton(),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (listing) {
          if (listing == null) {
            return const MkErrorWidget(message: 'Listing not found');
          }
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: RoomPhotoSection(
                        listing: listing,
                        currentIndex: _photoIndex,
                        onPageChanged: (i) => setState(() => _photoIndex = i),
                        isFavourited: isFav,
                        onFavourite: () {
                          if (userAsync.asData?.value == null) {
                            showLoginSheet(context);
                            return;
                          }
                          ref.read(favouriteProvider.notifier).toggle(listing);
                        },
                        onBack: () => context.pop(),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.25,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ListingTypeBadge(
                                label: listing.roomType == 'land'
                                    ? 'For Sale'
                                    : 'For Rent',
                                forSale: listing.roomType == 'land',
                              ),
                              const SizedBox(width: 8),
                              if (listing.address != null)
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          listing.address!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: PriceBadge(
                                  amount: listing.rentPerMonth,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.visibility_outlined,
                                        size: 14,
                                        color: AppColors.grey400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${listing.viewCount} views',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: AppColors.grey400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Listed ${Formatters.timeAgo(listing.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Spec pills (design.jpeg: 3 Room / 2 Bathroom / 1 Parking).
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              MkSpecPill(
                                icon: Icons.meeting_room_outlined,
                                label: listing.roomTypeLabel,
                              ),
                              MkSpecPill(
                                icon: Icons.layers_outlined,
                                label:
                                    'Floor ${listing.floor}/${listing.totalFloors}',
                              ),
                              MkSpecPill(
                                icon: Icons.chair_outlined,
                                label: listing.furnishingLabel,
                              ),
                            ],
                          ),

                          const MkDivider(),

                          RoomInfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Available from',
                            value: Formatters.date(listing.availableFrom),
                          ),

                          MkDivider(),

                          if (listing.facilities.isNotEmpty) ...[
                            MkSectionTitle('Facilities'),
                            const SizedBox(height: 10),
                            RoomFacilitiesGrid(listing.facilities),
                            const SizedBox(height: 16),
                            MkDivider(),
                          ],

                          MkSectionTitle('About this room'),
                          const SizedBox(height: 8),
                          Text(
                            listing.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.grey600,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 20),
                          MkDivider(),

                          MkSectionTitle('Listed by'),
                          const SizedBox(height: 10),
                          RoomOwnerCard(listing: listing),

                          const SizedBox(height: 20),
                          MkDivider(),

                          if (listing.geoPoint != null) ...[
                            const MkSectionTitle('Location'),
                            const SizedBox(height: 10),
                            if (listing.nearbyLandmarks != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me_outlined,
                                      size: 14,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        listing.nearbyLandmarks!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            RoomStaticMapPreview(
                              lat: listing.geoPoint!.latitude,
                              lng: listing.geoPoint!.longitude,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _openDirections(
                                  context,
                                  listing.geoPoint!.latitude,
                                  listing.geoPoint!.longitude,
                                ),
                                icon: const Icon(
                                  Icons.navigation_rounded,
                                  size: 18,
                                  color: AppColors.accent,
                                ),
                                label: const Text(
                                  'Get Directions',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const MkDivider(),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: MoreRoomsSection(excludeListingId: widget.listingId),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RoomBottomCTA(listing: listing, userAsync: userAsync),
              ),
            ],
          );
        },
      ),
    );
  }
}
