import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/agent/presentation/widgets/agent_bottom_nav.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/data/listings_repository.dart';
import 'package:merokotha/features/owner/data/inquiry_repository.dart';
import 'package:merokotha/features/owner/presentation/widgets/owner_widgets.dart';
import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Inbox for inquiries on the agent's listings.
///
/// Reuses the shared [InquiryRepository]: agent inquiries carry
/// `ownerId == agent uid`, so `watchByStatus` / accept / decline work
/// unchanged, and accepting opens a chat with the agent on the lister side.
/// The real-owner contact (masked publicly in Phase 4) is revealed here via
/// [_OwnerContactStrip] so the handling agent can coordinate with the owner.
class AgentInquiriesScreen extends ConsumerStatefulWidget {
  const AgentInquiriesScreen({super.key});

  @override
  ConsumerState<AgentInquiriesScreen> createState() =>
      _AgentInquiriesScreenState();
}

class _AgentInquiriesScreenState extends ConsumerState<AgentInquiriesScreen>
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
    final user = ref.watch(currentUserProvider).asData?.value;

    if (user?.isVerifiedAgent != true) {
      return Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: const MkAppBar(title: 'Inbox', showBack: false),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: MkEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Awaiting admin verification',
            subtitle:
                'Inquiries on your posted rooms will appear here after approval.',
          ),
        ),
        bottomNavigationBar: const AgentBottomNav(currentIndex: 3),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'Inbox', showBack: false, actions: []),
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
                _AgentInquiryTab(status: InquiryStatus.pending),
                _AgentInquiryTab(status: InquiryStatus.accepted),
                _AgentInquiryTab(status: InquiryStatus.declined),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 3),
    );
  }
}

class _AgentInquiryTab extends ConsumerWidget {
  final InquiryStatus status;
  const _AgentInquiryTab({required this.status});

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
                        ? 'Accepted inquiries open a chat — check Messages via the chat list'
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InquiryCard(
                          inquiry: inq,
                          onAccept: status == InquiryStatus.pending
                              ? () => _acceptAndChat(context, ref, user, inq)
                              : null,
                          onDecline: status == InquiryStatus.pending
                              ? () => _showDeclineDialog(context, ref, inq.id)
                              : null,
                          onOpenChat: status == InquiryStatus.accepted
                              ? () => _openChat(context, ref, user, inq)
                              : null,
                        ),
                        _OwnerContactStrip(listingId: inq.listingId),
                      ],
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
    UserModel user,
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
    UserModel user,
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

/// Reveals the real-owner contact for the handling agent.
///
/// The owner name/phone are masked on public listing views (Phase 4); here,
/// inside the agent's own inbox, they are shown so the agent can coordinate
/// with the owner. Uses a direct fetch (no view-count increment).
class _OwnerContactStrip extends ConsumerStatefulWidget {
  final String listingId;
  const _OwnerContactStrip({required this.listingId});

  @override
  ConsumerState<_OwnerContactStrip> createState() => _OwnerContactStripState();
}

class _OwnerContactStripState extends ConsumerState<_OwnerContactStrip> {
  Future<ListingModel?>? _listingFuture;

  @override
  void initState() {
    super.initState();
    _listingFuture = ref
        .read(listingsRepositoryProvider)
        .getListingById(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ListingModel?>(
      future: _listingFuture,
      builder: (context, snap) {
        final listing = snap.data;
        if (listing == null || !listing.isAgentListed) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.info),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.key_rounded,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Owner: ${listing.ownerName}'
                  '${listing.ownerPhone != null ? ' • ${listing.ownerPhone}' : ''}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
