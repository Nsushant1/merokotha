import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

/// Generic full-screen loading state rendered as a shimmering skeleton
/// (a stack of card-shaped placeholders) instead of a bare spinner, so
/// pages never show a jarring blank-then-pop-in transition.
class MkLoading extends StatelessWidget {
  final bool fullScreen;

  const MkLoading({super.key, this.fullScreen = true});

  @override
  Widget build(BuildContext context) {
    if (!fullScreen) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.accent,
          ),
        ),
      );
    }
    return const Scaffold(body: _SkeletonFeed());
  }
}

class _SkeletonFeed extends StatelessWidget {
  const _SkeletonFeed();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ShimmerBox(
            height: 20,
            width: 160,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < 3; i++) ...[
            ShimmerBox(
              height: 180,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            const SizedBox(height: 12),
            ShimmerBox(
              height: 14,
              width: 200,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            ShimmerBox(
              height: 14,
              width: 120,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class MkErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const MkErrorWidget({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePaddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x260757B8),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              MkButton(
                label: 'Try again',
                onPressed: onRetry,
                fullWidth: false,
                height: AppSizes.buttonHeightSm,
                prefixIcon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MkEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MkEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePaddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x260757B8),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              MkButton(
                label: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
