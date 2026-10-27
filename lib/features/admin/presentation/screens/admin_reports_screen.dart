import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_nav.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/moderation/data/moderation_repository.dart';
import 'package:merokotha/shared/models/report_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Admin review queue for user-submitted listing reports.
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  ReportStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allReportsProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const AdminAppBar(title: 'Reports', showBack: true),
      body: Column(
        children: [
          Container(
            color: AdminColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', _filter == null, () {
                    setState(() => _filter = null);
                  }),
                  const SizedBox(width: 8),
                  _chip('Pending', _filter == ReportStatus.pending, () {
                    setState(() => _filter = ReportStatus.pending);
                  }),
                  const SizedBox(width: 8),
                  _chip('Resolved', _filter == ReportStatus.resolved, () {
                    setState(() => _filter = ReportStatus.resolved);
                  }),
                  const SizedBox(width: 8),
                  _chip('Dismissed', _filter == ReportStatus.dismissed, () {
                    setState(() => _filter = ReportStatus.dismissed);
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              loading: () => const MkLoading(),
              error: (e, _) => MkErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(allReportsProvider),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return const MkEmptyState(
                    title: 'No reports',
                    subtitle: 'User-submitted listing reports appear here.',
                    icon: Icons.flag_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReportCard(report: reports[i]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AdminColors.accent : AdminColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AdminColors.primary : AppColors.grey400,
          ),
        ),
      ),
    ),
  );
}

class _ReportCard extends ConsumerStatefulWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;

  Future<void> _decide({required bool resolved, required bool suspend}) async {
    final noteCtrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(resolved ? 'Resolve report' : 'Dismiss report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suspend)
              const Text(
                'The listing will be suspended immediately.',
                style: TextStyle(fontSize: 13, color: AppColors.error),
              ),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Decision note (shown to the reporter)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, noteCtrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    noteCtrl.dispose();
    if (note == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final me = await ref.read(currentUserProvider.future);
      await ref
          .read(reportsRepositoryProvider)
          .decideReport(
            reportId: widget.report.id,
            report: widget.report,
            resolved: resolved,
            decisionNote: note.isEmpty ? null : note,
            decidedBy: me?.id ?? 'admin',
            suspendListing: suspend,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decision saved.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final me = await ref.read(currentUserProvider.future);
      await ref
          .read(reportsRepositoryProvider)
          .decideReport(
            reportId: widget.report.id,
            report: widget.report,
            resolved: true,
            decisionNote: 'Listing restored after review.',
            decidedBy: me?.id ?? 'admin',
            restoreListing: true,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
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
                  r.listingTitle ?? r.listingId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadgePending(r.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r.category} · by ${r.reporterName ?? r.reporterId} · ${Formatters.timeAgo(r.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
          if (r.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.details,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey800,
                height: 1.4,
              ),
            ),
          ],
          if (!r.isPending && (r.decisionNote?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 6),
            Text(
              'Decision: ${r.decisionNote}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (r.isPending) ...[
            const SizedBox(height: 12),
            if (_busy)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btn('Resolve', AppColors.success, () {
                    _decide(resolved: true, suspend: false);
                  }),
                  _btn('Resolve + suspend', AppColors.error, () {
                    _decide(resolved: true, suspend: true);
                  }, outlined: true),
                  _btn('Dismiss', AppColors.grey600, () {
                    _decide(resolved: false, suspend: false);
                  }, outlined: true),
                ],
              ),
          ] else ...[
            const SizedBox(height: 12),
            _btn('Restore listing', AppColors.info, _restore, outlined: true),
          ],
        ],
      ),
    );
  }

  Widget _btn(
    String label,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) => Material(
    color: outlined ? Colors.transparent : color,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: outlined ? color : Colors.white,
          ),
        ),
      ),
    ),
  );
}

class StatusBadgePending extends StatelessWidget {
  final ReportStatus status;
  const StatusBadgePending(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ReportStatus.pending:
        return StatusBadge.pending();
      case ReportStatus.resolved:
        return StatusBadge.accepted();
      case ReportStatus.dismissed:
        return StatusBadge.declined();
    }
  }
}
