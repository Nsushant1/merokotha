import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_nav.dart';
import 'package:merokotha/features/analytics/data/analytics_repository.dart';
import 'package:merokotha/features/analytics/presentation/analytics_widgets.dart';
import 'package:merokotha/shared/models/analytics_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Platform-wide analytics: visits, visitors, inquiry outcomes, trends,
/// and top-performing listings.
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(platformAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const AdminAppBar(title: 'Analytics', showBack: true),
      body: eventsAsync.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(platformAnalyticsProvider),
        ),
        data: (events) {
          var views = 0;
          var inquiries = 0;
          var accepted = 0;
          final visitors = <String>{};
          final listings = <String>{};
          for (final e in events) {
            switch (e.type) {
              case AnalyticsEventType.view:
                views++;
                visitors.add(e.visitorId);
                break;
              case AnalyticsEventType.inquiry:
                inquiries++;
                break;
              case AnalyticsEventType.inquiryAccepted:
                accepted++;
                break;
              default:
                break;
            }
            if (e.listingId.isNotEmpty) listings.add(e.listingId);
          }
          final byListing = aggregateByListing(events);
          final top = byListing.values.toList()
            ..sort((a, b) => b.views.compareTo(a.views));
          final trend = buildTrend(events, 14);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TotalsGrid(
                  views: views,
                  visitors: visitors.length,
                  inquiries: inquiries,
                  accepted: accepted,
                  listings: listings.length,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Trend · last 14 days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 10),
                TrendChart(points: trend),
                const SizedBox(height: 20),
                const Text(
                  'Top listings by visits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 10),
                if (top.isEmpty)
                  const MkEmptyState(
                    title: 'No data yet',
                    subtitle: 'Events appear here once tracking flows.',
                    icon: Icons.insights_outlined,
                  )
                else
                  for (final s in top.take(10))
                    Container(
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
                            child: Text(
                              s.listingId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${s.views} visits · ${s.uniqueVisitors} visitors',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }
}

class _TotalsGrid extends StatelessWidget {
  final int views;
  final int visitors;
  final int inquiries;
  final int accepted;
  final int listings;
  const _TotalsGrid({
    required this.views,
    required this.visitors,
    required this.inquiries,
    required this.accepted,
    required this.listings,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value, IconData icon, Color color) =>
        Expanded(
          child: AnalyticsStatCard(
            label: label,
            value: value,
            icon: icon,
            color: color,
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            tile('Visits', '$views', Icons.visibility_outlined, AppColors.primary),
            const SizedBox(width: 10),
            tile('Visitors', '$visitors', Icons.people_outline_rounded, AppColors.info),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            tile('Inquiries', '$inquiries', Icons.inbox_outlined, AppColors.warning),
            const SizedBox(width: 10),
            tile('Accepted', '$accepted', Icons.check_circle_outline_rounded, AppColors.success),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            tile('Active listings', '$listings', Icons.home_work_outlined, AppColors.secondary),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}
