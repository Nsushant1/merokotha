import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_nav.dart';
import 'package:merokotha/features/moderation/data/moderation_repository.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Shared decision/audit history across listing reviews, agent decisions,
/// report resolutions, and bans.
class AdminHistoryScreen extends ConsumerWidget {
  const AdminHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(moderationHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const AdminAppBar(title: 'Decision history', showBack: true),
      body: historyAsync.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(moderationHistoryProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const MkEmptyState(
              title: 'No decisions yet',
              subtitle: 'Admin reviews, approvals and suspensions log here.',
              icon: Icons.history_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = entries[i];
              return Container(
                padding: const EdgeInsets.all(AppSizes.cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _color(e.action).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Icon(
                        _icon(e.targetType),
                        size: 18,
                        color: _color(e.action),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.targetType} · ${e.action}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${e.targetId}'
                            '${e.note?.isNotEmpty ?? false ? ' — ${e.note}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.timeAgo(e.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  Color _color(String action) {
    switch (action) {
      case 'verified':
      case 'approved':
      case 'resolved':
      case 'restored':
      case 'unbanned':
        return AppColors.success;
      case 'rejected':
      case 'revoked':
      case 'suspended':
      case 'banned':
        return AppColors.error;
      default:
        return AppColors.grey600;
    }
  }

  IconData _icon(String targetType) {
    switch (targetType) {
      case 'listing':
        return Icons.home_work_outlined;
      case 'agent':
        return Icons.badge_outlined;
      case 'report':
        return Icons.flag_outlined;
      default:
        return Icons.person_outline_rounded;
    }
  }
}
