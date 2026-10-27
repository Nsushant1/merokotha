import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/i18n/localization.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:merokotha/features/moderation/data/moderation_repository.dart';
import 'package:merokotha/shared/models/report_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Reports submitted by the signed-in user, with admin decision status.
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fbUser = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(title: tr(ref, 'reports_title')),
      body: fbUser == null
          ? const MkEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Not signed in',
              subtitle: 'Sign in to see the reports you submitted.',
            )
          : StreamBuilder<List<ReportModel>>(
              stream: ref
                  .watch(reportsRepositoryProvider)
                  .watchMyReports(fbUser.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const MkLoading();
                }
                if (snap.hasError) {
                  return MkErrorWidget(message: snap.error.toString());
                }
                final reports = snap.data ?? [];
                if (reports.isEmpty) {
                  return MkEmptyState(
                    icon: Icons.flag_outlined,
                    title: tr(ref, 'reports_empty'),
                    subtitle: tr(ref, 'reports_empty_sub'),
                    actionLabel: 'Browse rooms',
                    onAction: () => context.go(AppRoutes.home),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ReportTile(report: reports[i]),
                );
              },
            ),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 4),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final ReportModel report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (report.status) {
      case ReportStatus.pending:
        color = AppColors.warning;
        label = 'Under review';
        break;
      case ReportStatus.resolved:
        color = AppColors.success;
        label = 'Resolved';
        break;
      case ReportStatus.dismissed:
        color = AppColors.grey400;
        label = 'Dismissed';
        break;
    }
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppSizes.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.listingTitle ?? 'Listing',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${report.category} · ${Formatters.timeAgo(report.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
          if (!report.isPending &&
              (report.decisionNote?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Text(
                'Decision: ${report.decisionNote}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey800,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
