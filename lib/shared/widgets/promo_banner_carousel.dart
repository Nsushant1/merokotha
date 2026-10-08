import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// External promo destination shown in the banner carousel.
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

/// Single source of truth for the external promo banners.
///
/// Requirement URLs (two separate destinations — never concatenated):
/// - https://kitta-estate.vercel.app/
/// - https://www.himavolt.com/
const promoBannerDestinations = [
  PromoBannerDestination(
    label: 'Kitta Estate — open external site',
    assetPath: 'assets/kitta.png',
    url: 'https://kitta-estate.vercel.app/',
  ),
  PromoBannerDestination(
    label: 'Himavolt — open external site',
    assetPath: 'assets/himavolt.png',
    url: 'https://www.himavolt.com/',
  ),
];

/// Reusable external-promo banner carousel.
///
/// Used in both [CustomerHomeScreen] (immediately below the search bar)
/// and [LandingScreen] — one implementation, one config.
///
/// - Shows one banner at a time, auto-advances every 3 seconds.
/// - Manual swipe supported via [PageView]; tap opens the URL externally.
/// - Animated dot indicator.
/// - Timer is cancelled in [dispose]; no work after disposal.
/// - Bundled PNG artwork (aspect ~2.5:1, rendered with [BoxFit.cover])
///   so there is no stretching and only minimal side cropping;
///   responsive via parent constraints.
class PromoBannerCarousel extends StatefulWidget {
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
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
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
  void didUpdateWidget(PromoBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinations.length != widget.destinations.length ||
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
    if (widget.destinations.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.destinations.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = widget.destinations;
    if (destinations.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: destinations.length,
            onPageChanged: (i) {
              if (!mounted) return;
              setState(() => _index = i);
            },
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
          ),
        ),
        if (destinations.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              destinations.length,
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
