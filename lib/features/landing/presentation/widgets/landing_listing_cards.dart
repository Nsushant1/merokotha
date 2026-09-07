import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';
import 'package:merokotha/shared/models/listing_model.dart';

class LandingGridCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;

  const LandingGridCard({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LandingTheme.surface,
      borderRadius: BorderRadius.circular(LandingTheme.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LandingTheme.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LandingTheme.r),
            border: Border.all(color: LandingTheme.hairline),
          ),
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
                            placeholder: (_, _) => const _ShimmerPlaceholder(),
                            errorWidget: (_, _, _) => const _PhotoFallback(),
                          )
                        : const _PhotoFallback(),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _ScrimBadge(
                        text: listing.roomTypeLabel,
                      ),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LandingTheme.titleMd,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: LandingTheme.stone,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.address ?? 'Nepal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: LandingTheme.stone,
                            ),
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
    return Material(
      color: LandingTheme.surface,
      borderRadius: BorderRadius.circular(LandingTheme.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LandingTheme.r),
        child: Container(
          height: 108,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LandingTheme.r),
            border: Border.all(color: LandingTheme.hairline),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: listing.photoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.photoUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const _ShimmerPlaceholder(),
                          errorWidget: (_, _, _) => const _PhotoFallback(),
                        )
                      : const _PhotoFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LandingTheme.titleMd,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: LandingTheme.stone,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              listing.address ?? 'Kathmandu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: LandingTheme.stone,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Rs. ${LandingTheme.formatPrice(listing.rentPerMonth)}',
                            style: LandingTheme.priceLg,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '/month',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: LandingTheme.stone,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFECEAE4));
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LandingTheme.bgWarm,
      child: Center(
        child: Icon(
          Icons.home_outlined,
          color: LandingTheme.stone,
          size: 28,
        ),
      ),
    );
  }
}

class _ScrimBadge extends StatelessWidget {
  final String text;
  const _ScrimBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        'Rs. ${LandingTheme.formatPrice(amount)}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: LandingTheme.ink,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
