import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/owner/presentation/widgets/owner_widgets.dart';
import 'package:merokotha/shared/widgets/owner_bottom_nav.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/owner/data/inquiry_repository.dart';

class OwnerInquiriesScreen extends ConsumerStatefulWidget {
  const OwnerInquiriesScreen({super.key});

  @override
  ConsumerState<OwnerInquiriesScreen> createState() =>
      _OwnerInquiriesScreenState();
}

class _OwnerInquiriesScreenState extends ConsumerState<OwnerInquiriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(title: 'Inquiries', showBack: false, actions: const []),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(AppSizes.md, 4, AppSizes.md, 12),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: TabBar(
                controller: _tabController,
                splashBorderRadius: BorderRadius.circular(AppSizes.radiusFull),
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  boxShadow: AppSizes.shadowCard,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey600,
                labelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Accepted'),
                  Tab(text: 'Declined'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InquiryTab(status: InquiryStatus.pending),
                _InquiryTab(status: InquiryStatus.accepted),
                _InquiryTab(status: InquiryStatus.declined),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 3),
    );
  }
}

class _InquiryTab extends ConsumerWidget {
  final InquiryStatus status;
  const _InquiryTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(currentUserProvider)
        .when(
          data: (user) {
            if (user == null) return const SizedBox.shrink();

            return StreamBuilder<List<InquiryModel>>(
              stream: ref
                  .watch(inquiryRepositoryProvider)
                  .watchByStatus(user.id, status),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const MkLoading(fullScreen: false);
                }
                final inquiries = snap.data ?? [];
                if (inquiries.isEmpty) {
                  return MkEmptyState(
                    title: 'No ${status.name} inquiries',
                    subtitle: status == InquiryStatus.pending
                        ? 'New inquiries from renters will appear here'
                        : status == InquiryStatus.accepted
                        ? 'Accepted inquiries open a chat — check Messages tab'
                        : 'No inquiries have been declined yet',
                    icon: Icons.inbox_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: inquiries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizes.md),
                  itemBuilder: (_, i) {
                    final inq = inquiries[i];
                    return InquiryCard(
                      inquiry: inq,
                      onAccept: status == InquiryStatus.pending
                          ? () => _acceptAndChat(context, ref, user, inq)
                          : null,
                      onDecline: status == InquiryStatus.pending
                          ? () => _showDeclineDialog(context, ref, inq.id)
                          : null,
                      // Show "Open chat" button for accepted inquiries
                      onOpenChat: status == InquiryStatus.accepted
                          ? () => _openChat(context, ref, user, inq)
                          : null,
                    );
                  },
                );
              },
            );
          },
          loading: () => const MkLoading(),
          error: (e, _) => MkErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
        );
  }

  // ── Accept inquiry → create chat → open thread ──
  Future<void> _acceptAndChat(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    InquiryModel inq,
  ) async {
    try {
      final chatId = await ref
          .read(inquiryRepositoryProvider)
          .acceptInquiry(
            inquiryId: inq.id,
            inquiry: inq,
            ownerName: user.name,
            ownerPhotoUrl: user.photoUrl,
          );

      if (context.mounted) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('Accepted! Chat opened with ${inq.customerName}'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to chat thread
        context.push(AppRoutes.chatThread.replaceAll(':chatId', chatId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Open existing chat for accepted inquiry ──
  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    InquiryModel inq,
  ) async {
    try {
      // Find or create the chat (idempotent)
      final chatId = await ref
          .read(inquiryRepositoryProvider)
          .acceptInquiry(
            inquiryId: inq.id,
            inquiry: inq,
            ownerName: user.name,
            ownerPhotoUrl: user.photoUrl,
          );

      if (context.mounted) {
        context.push(AppRoutes.chatThread.replaceAll(':chatId', chatId));
      }
    } catch (_) {
      if (context.mounted) {
        context.push(AppRoutes.chatList);
      }
    }
  }

  void _showDeclineDialog(
    BuildContext context,
    WidgetRef ref,
    String inquiryId,
  ) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        title: const Text(
          'Decline inquiry',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optionally add a reason for the renter:',
              style: TextStyle(fontSize: 13, color: AppColors.grey600, height: 1.4),
            ),
            const SizedBox(height: 14),
            MkTextField(
              label: 'Reason (optional)',
              hint: 'e.g. Room is no longer available',
              controller: reasonCtrl,
              maxLines: 3,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(inquiryRepositoryProvider)
                  .declineInquiry(
                    inquiryId,
                    reason: reasonCtrl.text.trim().isEmpty
                        ? null
                        : reasonCtrl.text.trim(),
                  );
            },
            child: const Text(
              'Decline',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
