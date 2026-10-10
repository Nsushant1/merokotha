import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/data/customer_inquiry_repository.dart';
import 'package:merokotha/features/customer/presentation/widgets/inquiry_status_tracker.dart';
import 'package:merokotha/features/owner/data/inquiry_repository.dart';
import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';

/// Inquiries the signed-in user sent as a seeker.
///
/// Accepted inquiries open their chat thread (resolved side-effect free);
/// other rows link back to the room. Mirrors the owner inbox without
/// duplicating its accept/decline actions.
class MyInquiriesScreen extends ConsumerWidget {
  const MyInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fbUser = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'My inquiries', showBack: false),
      body: fbUser == null
          ? const MkEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Not signed in',
              subtitle: 'Sign in to see the inquiries you sent.',
            )
          : StreamBuilder<List<InquiryModel>>(
              stream: ref
                  .watch(customerInquiryRepositoryProvider)
                  .watchMyInquiries(fbUser.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const MkLoading();
                }
                if (snap.hasError) {
                  return MkErrorWidget(
                    message: snap.error.toString(),
                    onRetry: () =>
                        ref.invalidate(customerInquiryRepositoryProvider),
                  );
                }
                final inquiries = snap.data ?? [];
                if (inquiries.isEmpty) {
                  return MkEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No inquiries yet',
                    subtitle:
                        'Rooms you ask about will show up here with their status.',
                    actionLabel: 'Browse rooms',
                    onAction: () => context.go(AppRoutes.home),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: inquiries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _InquiryTile(inquiry: inquiries[i]),
                );
              },
            ),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 3),
    );
  }
}

class _InquiryTile extends ConsumerWidget {
  final InquiryModel inquiry;
  const _InquiryTile({required this.inquiry});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (inquiry.status == InquiryStatus.accepted) {
      try {
        final chatId = await ref
            .read(inquiryRepositoryProvider)
            .resolveChatId(
              inquiryId: inquiry.id,
              inquiry: inquiry,
              ownerName: inquiry.ownerName ?? 'Owner',
            );
        if (context.mounted) {
          context.push(AppRoutes.chatThread.replaceAll(':chatId', chatId));
        }
        return;
      } catch (_) {
        if (context.mounted) {
          context.push(AppRoutes.chatList);
        }
        return;
      }
    }
    context.push(AppRoutes.roomDetail.replaceAll(':id', inquiry.listingId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppSizes.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPaddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inquiry.listingTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusPill(status: inquiry.status),
                  ],
                ),
                const SizedBox(height: 8),
                InquiryStatusTracker(status: inquiry.status.name),
                const SizedBox(height: 8),
                Text(
                  Formatters.timeAgo(inquiry.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey400,
                  ),
                ),
                if (inquiry.status == InquiryStatus.declined &&
                    (inquiry.declineReason?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${inquiry.declineReason}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final InquiryStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case InquiryStatus.accepted:
        return StatusBadge.accepted();
      case InquiryStatus.declined:
        return StatusBadge.declined();
      case InquiryStatus.pending:
        return StatusBadge.pending();
    }
  }
}
