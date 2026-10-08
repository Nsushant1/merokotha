import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/admin/providers/admin_providers.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class AdminInquiriesScreen extends ConsumerStatefulWidget {
  const AdminInquiriesScreen({super.key});

  @override
  ConsumerState<AdminInquiriesScreen> createState() =>
      _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends ConsumerState<AdminInquiriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AdminAppBar(
        title: 'All inquiries',
        showBack: false,
        actions: const [],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AdminColors.primary,
            child: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.grey400,
              indicatorColor: AdminColors.accent,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Accepted'),
                Tab(text: 'Declined'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _InquiryTab(status: InquiryStatus.pending),
                _InquiryTab(status: InquiryStatus.accepted),
                _InquiryTab(status: InquiryStatus.declined),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    );
  }
}

class _InquiryTab extends ConsumerWidget {
  final InquiryStatus status;
  const _InquiryTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(allInquiriesProvider)
        .when(
          loading: () => ShimmerLoading(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, _) => ShimmerBox(
                height: 148,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
          ),
          error: (e, _) => MkErrorWidget(message: e.toString()),
          data: (all) {
            final list = all.where((i) => i.status == status).toList();

            if (list.isEmpty) {
              return MkEmptyState(
                title: 'No ${status.name} inquiries',
                subtitle:
                    'Platform-wide ${status.name} inquiries will appear here',
                icon: Icons.inbox_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _AdminInquiryCard(list[i]),
            );
          },
        );
  }
}

class _AdminInquiryCard extends StatelessWidget {
  final InquiryModel inquiry;
  const _AdminInquiryCard(this.inquiry);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPaddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppSizes.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              UserAvatar(
                name: inquiry.customerName,
                photoUrl: inquiry.customerPhotoUrl,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    Text(
                      '→ ${inquiry.ownerName ?? 'Owner'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(inquiry.status),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Listing info
          Row(
            children: [
              const Icon(
                Icons.home_outlined,
                size: 13,
                color: AppColors.grey400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  inquiry.listingTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Move-in date + time
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.grey400,
              ),
              const SizedBox(width: 4),
              Text(
                'Move-in: ${Formatters.date(inquiry.moveInDate)}',
                style: const TextStyle(fontSize: 12, color: AppColors.grey600),
              ),
              const Spacer(),
              Text(
                Formatters.timeAgo(inquiry.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.grey400),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Message preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              inquiry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
                height: 1.4,
              ),
            ),
          ),

          // Decline reason
          if (inquiry.isDeclined && inquiry.declineReason != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Reason: ${inquiry.declineReason}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(InquiryStatus s) {
    switch (s) {
      case InquiryStatus.pending:
        return StatusBadge.pending();
      case InquiryStatus.accepted:
        return StatusBadge.accepted();
      case InquiryStatus.declined:
        return StatusBadge.declined();
    }
  }
}
