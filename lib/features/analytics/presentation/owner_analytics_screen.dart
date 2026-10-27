import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/i18n/localization.dart';
import 'package:merokotha/features/analytics/data/analytics_repository.dart';
import 'package:merokotha/features/analytics/presentation/analytics_widgets.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:merokotha/features/owner/data/inquiry_repository.dart';
import 'package:merokotha/shared/models/analytics_model.dart';
import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Owner dashboard: visits, unique visitors, inquiry outcomes, 14-day
/// trends, and per-listing performance.
class OwnerAnalyticsScreen extends ConsumerWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(ownerAnalyticsProvider);
    final user = ref.watch(currentUserProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(title: tr(ref, 'analytics_title')),
      body: eventsAsync.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(ownerAnalyticsProvider),
        ),
        data: (events) {
          if (user == null) {
            return const MkEmptyState(
              title: 'Not signed in',
              subtitle: 'Sign in to view analytics.',
              icon: Icons.inbox_outlined,
            );
          }
          final byListing = aggregateByListing(events);
          var views = 0;
          final visitors = <String>{};
          for (final e in events) {
            if (e.type == AnalyticsEventType.view) {
              views++;
              visitors.add(e.visitorId);
            }
          }
          final trend = buildTrend(events, 14);
          final top = byListing.values.toList()
            ..sort((a, b) => b.views.compareTo(a.views));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ownerAnalyticsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnalyticsStatCard(
                          label: tr(ref, 'analytics_visits'),
                          value: '$views',
                          icon: Icons.visibility_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnalyticsStatCard(
                          label: tr(ref, 'analytics_visitors'),
                          value: '${visitors.length}',
                          icon: Icons.people_outline_rounded,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InquiryOutcomes(ownerId: user.id),
                  const SizedBox(height: 20),
                  Text(
                    tr(ref, 'analytics_trend'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TrendChart(points: trend),
                  const SizedBox(height: 20),
                  Text(
                    tr(ref, 'analytics_performance'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (top.isEmpty)
                    const MkEmptyState(
                      title: 'No data yet',
                      subtitle: 'Visits appear here once seekers open rooms.',
                      icon: Icons.insights_outlined,
                    )
                  else
                    for (final s in top.take(10))
                      _PerformanceRow(stats: s),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 4),
    );
  }
}

/// Inquiry outcome counts from the inquiries collection (source of truth
/// for pending/accepted/declined — events mirror them for trends).
final _ownerInquiriesProvider =
    StreamProvider.family<List<InquiryModel>, String>((ref, ownerId) {
      return ref.watch(inquiryRepositoryProvider).watchAllForOwner(ownerId);
    });

class _InquiryOutcomes extends ConsumerWidget {
  final String ownerId;
  const _InquiryOutcomes({required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(_ownerInquiriesProvider(ownerId));
    return inquiriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (inquiries) {
        final pending = inquiries
            .where((i) => i.status == InquiryStatus.pending)
            .length;
        final accepted = inquiries
            .where((i) => i.status == InquiryStatus.accepted)
            .length;
        return Row(
          children: [
            Expanded(
              child: AnalyticsStatCard(
                label: tr(ref, 'analytics_inquiries'),
                value: '${inquiries.length}',
                icon: Icons.inbox_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnalyticsStatCard(
                label: tr(ref, 'analytics_accepted'),
                value: '$accepted',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnalyticsStatCard(
                label: 'Pending',
                value: '$pending',
                icon: Icons.hourglass_top_rounded,
                color: AppColors.grey600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final ListingStats stats;
  const _PerformanceRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.listingId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.views} visits · ${stats.uniqueVisitors} visitors · '
                  '${stats.inquiries} inquiries '
                  '(${stats.accepted} accepted)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (stats.calls + stats.whatsapps > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                '${stats.calls + stats.whatsapps} contacts',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
