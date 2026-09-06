import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/widgets/mk_section_title.dart';
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
              ShimmerBox(height: 22, width: 220, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 10),
              ShimmerBox(height: 14, width: 150, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 20),
              ShimmerBox(height: 26, width: 130, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 24),
              ShimmerBox(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 8),
              ShimmerBox(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 8),
              ShimmerBox(height: 14, width: 200, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _photoIndex = 0;

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
                      padding: const EdgeInsets.all(AppSizes.pagePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  listing.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.grey900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.customerLight,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  listing.roomTypeLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.customerPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (listing.address != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.grey400,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    listing.address!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PriceBadge(
                                    amount: listing.rentPerMonth,
                                    fontSize: 20,
                                  ),
                                  if (listing.depositAmount > 0)
                                    Text(
                                      'Deposit: ${Formatters.npr(listing.depositAmount)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Floor ${listing.floor}/${listing.totalFloors}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                  Text(
                                    listing.furnishingLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          MkDivider(),

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
                            MkSectionTitle('Location'),
                            const SizedBox(height: 10),
                            if (listing.nearbyLandmarks != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me_outlined,
                                      size: 14,
                                      color: AppColors.grey400,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        listing.nearbyLandmarks!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.grey400,
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
                            const SizedBox(height: 20),
                            MkDivider(),
                          ],

                          Row(
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
                              const SizedBox(width: 16),
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

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: MoreRoomsSection(
                      excludeListingId: widget.listingId,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
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
