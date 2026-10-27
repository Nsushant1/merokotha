import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/admin/providers/ads_providers.dart';
import 'package:merokotha/shared/models/ad_model.dart';
import 'package:merokotha/shared/widgets/promo_banner_carousel.dart';

/// Opens an ad destination: listing detail, external URL, or nothing.
Future<void> openAd(BuildContext context, AdModel ad) async {
  if (ad.linkType == 'listing' &&
      ad.listingId != null &&
      ad.listingId!.isNotEmpty) {
    context.push(AppRoutes.roomDetail.replaceAll(':id', ad.listingId!));
    return;
  }
  if (ad.linkType == 'external' &&
      ad.externalUrl != null &&
      ad.externalUrl!.isNotEmpty) {
    final uri = Uri.tryParse(ad.externalUrl!);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Top-of-screen banner carousel backed by active Firebase ads
/// (`ads` collection, placement + priority + destination respected).
/// Falls back to the bundled promotions only when no active ad exists —
/// never an empty gap.
class FirebasePromoCarousel extends ConsumerWidget {
  final String slot;
  final double height;

  const FirebasePromoCarousel({
    super.key,
    required this.slot,
    this.height = 148,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(activeAdsProvider(slot));
    return adsAsync.when(
      loading: () => const PromoBannerCarousel(),
      error: (_, _) => const PromoBannerCarousel(),
      data: (ads) {
        if (ads.isEmpty) return const PromoBannerCarousel();
        return _AdCarousel(ads: ads, height: height, inFeed: false);
      },
    );
  }
}

/// In-feed ad slot backed by active Firebase ads, with the same static
/// fallback behavior as [FirebasePromoCarousel].
class FirebaseInFeedPromo extends ConsumerWidget {
  final String slot;
  const FirebaseInFeedPromo({super.key, required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(activeAdsProvider(slot));
    return adsAsync.when(
      loading: () => const InFeedPromoCarousel(),
      error: (_, _) => const InFeedPromoCarousel(),
      data: (ads) {
        if (ads.isEmpty) return const InFeedPromoCarousel();
        return _AdCarousel(ads: ads, height: 148, inFeed: true);
      },
    );
  }
}

class _AdCarousel extends StatefulWidget {
  final List<AdModel> ads;
  final double height;
  final bool inFeed;
  const _AdCarousel({
    required this.ads,
    required this.height,
    required this.inFeed,
  });

  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  static const _interval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(_AdCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads.length != widget.ads.length) {
      _index = 0;
      if (_controller.hasClients && widget.ads.isNotEmpty) {
        _controller.jumpToPage(0);
      }
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
    if (widget.ads.length <= 1) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      // Don't fight the user mid-swipe or an in-flight animation.
      if (_controller.position.isScrollingNotifier.value) return;
      final next = (_index + 1) % widget.ads.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.ads.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _AdCard(ad: widget.ads[i]),
          ),
        ),
        if (widget.ads.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.ads.length,
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

class _AdCard extends StatelessWidget {
  final AdModel ad;
  const _AdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: ad.title,
      button: true,
      child: GestureDetector(
        onTap: () => openAd(context, ad),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: ad.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.campaign_outlined,
                    size: 40,
                    color: AppColors.grey400,
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.campaign_outlined,
                    size: 40,
                    color: AppColors.grey400,
                  ),
                ),
              ),
              // Title/subtitle scrim.
              if (ad.title.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ad.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (ad.subtitle.isNotEmpty)
                          Text(
                            ad.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
