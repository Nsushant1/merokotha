import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/i18n/localization.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/agent/data/agent_directory_repository.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/widgets/contact_buttons.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// One agent's public directory entry.
final agentPublicProfileProvider =
    FutureProvider.family<AgentDirectoryEntry?, String>((ref, uid) {
      return ref.watch(agentDirectoryRepositoryProvider).getAgent(uid);
    });

/// Public profile of a verified agent: bio, contact buttons, active rentals.
class AgentPublicProfileScreen extends ConsumerWidget {
  final String uid;
  const AgentPublicProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];
    final agentFuture = ref.watch(agentPublicProfileProvider(uid));
    final rentalsAsync = ref.watch(agentRentalsProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'Agent'),
      body: agentFuture.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (agent) {
          if (agent == null || !agent.isActive) {
            return const MkEmptyState(
              title: 'Agent not found',
              subtitle: 'This agent profile is unavailable.',
              icon: Icons.badge_outlined,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppSizes.shadowCard,
                  ),
                  child: Column(
                    children: [
                      UserAvatar(
                        name: agent.displayName,
                        photoUrl: agent.photoUrl,
                        size: 72,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              agent.displayName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grey900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      if (agent.location?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          agent.location!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                      if (agent.bio?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 10),
                        Text(
                          agent.bio!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 14),
                      ContactButtons(
                        publicPhone: agent.publicPhone,
                        whatsappNumber: agent.whatsappNumber,
                        listingId: 'agent_$uid',
                        ownerId: uid,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  tr(ref, 'agents_rentals'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 12),
                rentalsAsync.when(
                  loading: () => const MkLoading(fullScreen: false),
                  error: (e, _) => MkErrorWidget(message: e.toString()),
                  data: (rentals) {
                    if (rentals.isEmpty) {
                      return const MkEmptyState(
                        title: 'No active rentals',
                        subtitle:
                            'This agent has no active listings right now.',
                        icon: Icons.house_outlined,
                      );
                    }
                    return Column(
                      children: [
                        for (final l in rentals)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListingRow(
                              listing: l,
                              isFavourited: favIds.contains(l.id),
                              onFavourite: () => ref
                                  .read(favouriteProvider.notifier)
                                  .toggle(l),
                              onTap: () => context.push(
                                AppRoutes.roomDetail.replaceAll(':id', l.id),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
