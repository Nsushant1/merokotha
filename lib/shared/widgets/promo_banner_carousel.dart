import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Classic image-based promo destination (top-of-screen banners).
///
/// Artwork comes from the bundled PNGs (`assets/kitta.png`,
/// `assets/himavolt.png`), which already contain their own headline
/// copy — so the carousel renders the image full-bleed instead of
/// overlaying duplicate text.
class PromoBannerDestination {
  final String label;
  final String assetPath;
  final String url;

  const PromoBannerDestination({
    required this.label,
    required this.assetPath,
    required this.url,
  });
}

/// Single source of truth for the top-of-screen promo banners.
///
/// Requirement URLs (two separate destinations — never concatenated):
/// - https://pitambari.vercel.app/
/// - https://floor-cleaner.vercel.app/
const promoBannerDestinations = [
  PromoBannerDestination(
    label: 'Pitambari — open external site',
    assetPath: 'assets/kitta.png',
    url: 'https://pitambari.vercel.app/',
  ),
  PromoBannerDestination(
    label: 'Floor Cleaner — open external site',
    assetPath: 'assets/himavolt.png',
    url: 'https://floor-cleaner.vercel.app/',
  ),
];

/// Code-designed in-feed promo destination (room-feed ad slots only).
///
/// Unlike the top banners, these render a custom gradient + icon + copy
/// card designed in code, so the two promos are visually distinct.
class InFeedPromoDestination {
  final String label;
  final String brand;
  final String tagline;
  final String ctaLabel;
  final String url;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;

  const InFeedPromoDestination({
    required this.label,
    required this.brand,
    required this.tagline,
    required this.ctaLabel,
    required this.url,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

/// Single source of truth for the in-feed promo banners (same two URLs).
const inFeedPromoDestinations = [
  InFeedPromoDestination(
    label: 'Pitambari — open external site',
    brand: 'Pitambari',
    tagline: 'Herbal care rooted in Nepali tradition',
    ctaLabel: 'Explore',
    url: 'https://pitambari.vercel.app/',
    icon: Icons.spa_rounded,
    gradientStart: Color(0xFF0D5C34),
    gradientEnd: Color(0xFF35A06B),
  ),
  InFeedPromoDestination(
    label: 'Floor Cleaner — open external site',
    brand: 'Floor Cleaner',
    tagline: 'Spotless shine for every room',
    ctaLabel: 'Shop now',
    url: 'https://floor-cleaner.vercel.app/',
    icon: Icons.cleaning_services_rounded,
    gradientStart: Color(0xFF0B3D91),
    gradientEnd: Color(0xFF2FA8DE),
  ),
];

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Shared auto-scroll PageView + dot indicator shell used by both the
/// classic image carousel and the custom in-feed carousel.
///
/// - Shows one banner at a time, auto-advances every 3 seconds.
/// - Manual swipe supported via [PageView].
/// - Timer is cancelled in [dispose]; no work after disposal.
class _CarouselShell extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double height;
  final Duration interval;

  const _CarouselShell({
    required this.itemCount,
    required this.itemBuilder,
    this.height = 148,
    this.interval = const Duration(seconds: 3),
  });

  @override
  State<_CarouselShell> createState() => _CarouselShellState();
}

class _CarouselShellState extends State<_CarouselShell> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(_CarouselShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.interval != widget.interval) {
      _index = 0;
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.itemCount <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.itemCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.itemCount,
            onPageChanged: (i) {
              if (!mounted) return;
              setState(() => _index = i);
            },
            itemBuilder: widget.itemBuilder,
          ),
        ),
        if (widget.itemCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.itemCount,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == _index
                      ? AppColors.primary
                      : Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Classic image promo banner carousel for top-of-screen placements
/// (Customer Home below the search bar, Landing, Owner/Agent home).
///
/// - Tap opens the destination URL externally.
/// - Bundled PNG artwork (aspect ~2.5:1, rendered with [BoxFit.cover])
///   so there is no stretching and only minimal side cropping;
///   responsive via parent constraints.
class PromoBannerCarousel extends StatelessWidget {
  final List<PromoBannerDestination> destinations;
  final double height;
  final Duration interval;

  const PromoBannerCarousel({
    super.key,
    this.destinations = promoBannerDestinations,
    this.height = 148,
    this.interval = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return _CarouselShell(
      itemCount: destinations.length,
      height: height,
      interval: interval,
      itemBuilder: (_, i) {
        final d = destinations[i];
        return Semantics(
          label: d.label,
          button: true,
          child: GestureDetector(
            onTap: () => _openUrl(d.url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    d.assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.primaryLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.campaign_outlined,
                        size: 40,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_in_new_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom-designed promo carousel for the in-feed ad slots of the
/// room feed ([RoomFeedSlivers]). Same timing/swipe/tap/dots behavior
/// as [PromoBannerCarousel]; only the artwork differs.
class InFeedPromoCarousel extends StatelessWidget {
  final List<InFeedPromoDestination> destinations;
  final double height;
  final Duration interval;

  const InFeedPromoCarousel({
    super.key,
    this.destinations = inFeedPromoDestinations,
    this.height = 148,
    this.interval = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return _CarouselShell(
      itemCount: destinations.length,
      height: height,
      interval: interval,
      itemBuilder: (_, i) {
        final d = destinations[i];
        return Semantics(
          label: d.label,
          button: true,
          child: GestureDetector(
            onTap: () => _openUrl(d.url),
            child: _InFeedBannerCard(destination: d),
          ),
        );
      },
    );
  }
}

/// Code-designed promo banner: gradient backdrop with decorative rings,
/// brand medallion, headline + tagline, CTA pill, and an external-link
/// affordance. Compact enough for narrow phones (texts ellipsize).
class _InFeedBannerCard extends StatelessWidget {
  final InFeedPromoDestination destination;

  const _InFeedBannerCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    final d = destination;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [d.gradientStart, d.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative rings.
          Positioned(
            top: -44,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -52,
            left: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Ad marker.
          Positioned(
            top: 8,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
          // Content.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(d.icon, size: 26, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              d.ctaLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: d.gradientStart,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: d.gradientStart,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
