import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:merokotha/features/agent/presentation/widgets/agent_bottom_nav.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/chat/data/chat_model.dart';
import 'package:merokotha/features/chat/providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);
    final user = ref.watch(currentUserProvider).asData?.value;
    final isAgent = user?.isVerifiedAgent ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'Messages', showBack: false),
      body: chatsAsync.when(
        loading: () => const _ChatListSkeleton(),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (chats) {
          if (chats.isEmpty) {
            return const MkEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No messages yet',
              subtitle:
                  'When an inquiry is accepted, the chat thread will open here',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ChatTile(
              chat: chats[i],
              myUid: user?.id ?? '',
              onTap: () => context.push(
                AppRoutes.chatThread.replaceAll(':chatId', chats[i].id),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: isAgent
          ? const AgentBottomNav(currentIndex: 3)
          : const HomeBottomNav(currentIndex: 3),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String myUid;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.myUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadFor(myUid);
    final hasUnread = unread > 0;

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
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPaddingLarge),
            child: Row(
              children: [
                // Avatar
                UserAvatar(
                  name: chat.otherName(myUid),
                  photoUrl: chat.otherPhoto(myUid),
                  size: 54,
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.otherName(myUid),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppColors.grey900,
                              ),
                            ),
                          ),
                          if (chat.lastMessageAt != null)
                            Text(
                              Formatters.timeAgo(chat.lastMessageAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? AppColors.primary
                                    : AppColors.grey400,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Listing name
                      Text(
                        chat.listingTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Last message + unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage ?? 'Start chatting...',
                              style: TextStyle(
                                fontSize: 13,
                                color: hasUnread
                                    ? AppColors.grey800
                                    : AppColors.grey400,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(AppSizes.cardPaddingLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const ShimmerBox(
                width: 54,
                height: 54,
                borderRadius: BorderRadius.all(Radius.circular(27)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      height: 13,
                      width: 120,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      height: 11,
                      width: 90,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      height: 12,
                      width: 180,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
