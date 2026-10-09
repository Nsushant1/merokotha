import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/responsive.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_toggle_view.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/promo_banner_carousel.dart';

import 'listing_card.dart';

// ── Block model (pure, testable) ────────────────────────────────────────────

/// One unit of the repeating room/ad pattern:
///
/// - vertical chunk (3 list rows, or 4 grid cards) → ad → vertical chunk →
///   horizontal grid (≤10) → vertical chunk → ad → repeat.
sealed class RoomFeedBlock {
  const RoomFeedBlock();
}

/// Up to [verticalChunkSize] rooms rendered vertically
/// (list rows or grid cards).
class RoomChunkBlock extends RoomFeedBlock {
  final List<ListingModel> rooms;
  const RoomChunkBlock(this.rooms);
}

/// Scrolling ad banner ([PromoBannerCarousel]).
class AdBlock extends RoomFeedBlock {
  const AdBlock();
}

/// Horizontally scrollable grid of up to 10 rooms.
class HorizontalGridBlock extends RoomFeedBlock {
  final List<ListingModel> rooms;
  const HorizontalGridBlock(this.rooms);
}

/// Splits [listings] into the repeating chunk / ad / chunk / h-grid(10) /
/// chunk / ad pattern without dropping or duplicating rooms. Ads consume
/// no rooms and are only emitted when more rooms remain (no trailing ad).
///
/// [verticalChunkSize] is 3 in list mode and 4 in grid mode (two full
/// 2-column rows), so an ad always follows a complete visual row.
List<RoomFeedBlock> buildRoomFeedBlocks(
  List<ListingModel> listings, {
  int verticalChunkSize = 3,
}) {
  final blocks = <RoomFeedBlock>[];
  var i = 0;
  var step = 0;
  while (i < listings.length) {
    final phase = step % 6;
    if (phase == 1 || phase == 5) {
      blocks.add(const AdBlock());
    } else if (phase == 3) {
      final end = (i + 10).clamp(0, listings.length);
      blocks.add(HorizontalGridBlock(listings.sublist(i, end)));
      i = end;
    } else {
      final end = (i + verticalChunkSize).clamp(0, listings.length);
      blocks.add(RoomChunkBlock(listings.sublist(i, end)));
      i = end;
    }
    step++;
  }
  return blocks;
}

// ── Section header with manual toggle ───────────────────────────────────────

/// Room-listing section header: title left, optional "View All" action,
/// manual list/grid toggle on the side — same [LandingToggleView] design
/// and behavior as the Landing Screen. The toggle never auto-switches;
/// [isGrid] clearly drives the icon + semantics.
class RoomSectionHeader extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isGrid;
  final VoidCallback onToggle;

  const RoomSectionHeader({
    super.key,
    required this.title,
    required this.isGrid,
    required this.onToggle,
    this.titleStyle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                titleStyle ??
                const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
        Semantics(
          label: isGrid ? 'Grid view active' : 'List view active',
          button: true,
          child: LandingToggleView(isGrid: isGrid, onToggle: onToggle),
        ),
      ],
    );
  }
}

// ── Feed slivers (single shared implementation) ─────────────────────────────

/// Shared repeating room/ad feed for Customer Home and Search Results.
///
/// Consumes [listings] once (no extra API calls); favourites, loading,
/// error, empty, and detail navigation stay in the calling screen.
/// Vertical chunks respect [isGrid] (rows vs 2/3-col cards); the
/// horizontal grid and ad banners are identical in both modes.
class RoomFeedSlivers extends StatelessWidget {
  final List<ListingModel> listings;
  final bool isGrid;
  final List<String> favouriteIds;
  final void Function(ListingModel) onFavourite;
  final void Function(ListingModel) onTap;

  const RoomFeedSlivers({
    super.key,
    required this.listings,
    required this.isGrid,
    required this.favouriteIds,
    required this.onFavourite,
    required this.onTap,
  });

  int _gridColumns(BuildContext context) {
    if (MkBreakpoints.isDesktop(context)) return 3;
    if (MkBreakpoints.isTablet(context)) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    // Grid mode fills two full 2-column rows (4 rooms) per chunk so ads
    // always follow a complete row; list mode keeps 3 rows per chunk.
    final blocks = buildRoomFeedBlocks(
      listings,
      verticalChunkSize: isGrid ? 4 : 3,
    );
    final slivers = <Widget>[];

    for (final block in blocks) {
      switch (block) {
        case RoomChunkBlock(:final rooms):
          if (rooms.isEmpty) break;
          if (isGrid) {
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumns(context),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // ListingCard is taller than LandingGridCard (132px photo
                    // + full body), so cells need extra height — 0.72 clipped
                    // ~6px off the card bottom.
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final l = rooms[i];
                    return ListingCard(
                      listing: l,
                      isFavourited: favouriteIds.contains(l.id),
                      onFavourite: () => onFavourite(l),
                      onTap: () => onTap(l),
                    );
                  }, childCount: rooms.length),
                ),
              ),
            );
          } else {
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                sliver: SliverList.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final l = rooms[i];
                    return ListingRow(
                      listing: l,
                      isFavourited: favouriteIds.contains(l.id),
                      onFavourite: () => onFavourite(l),
                      onTap: () => onTap(l),
                    );
                  },
                ),
              ),
            );
          }
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
        case AdBlock():
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 4)));
          slivers.add(
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
                // In-feed slots use the custom Pitambari / Floor Cleaner
                // designs; classic image banners stay on top placements.
                child: InFeedPromoCarousel(),
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
        case HorizontalGridBlock(:final rooms):
          if (rooms.isEmpty) break;
          slivers.add(
            SliverToBoxAdapter(
              child: SizedBox(
                height: 262,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final l = rooms[i];
                    return SizedBox(
                      width: 220,
                      child: ListingCard(
                        listing: l,
                        isFavourited: favouriteIds.contains(l.id),
                        onFavourite: () => onFavourite(l),
                        onTap: () => onTap(l),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
      }
    }

    return SliverMainAxisGroup(slivers: slivers);
  }
}
