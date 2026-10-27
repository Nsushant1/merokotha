import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/i18n/localization.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/agent/data/agent_directory_repository.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Searchable public directory of admin-verified agents.
class AgentDirectoryScreen extends ConsumerStatefulWidget {
  const AgentDirectoryScreen({super.key});

  @override
  ConsumerState<AgentDirectoryScreen> createState() =>
      _AgentDirectoryScreenState();
}

class _AgentDirectoryScreenState extends ConsumerState<AgentDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentDirectoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(title: tr(ref, 'agents_title')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: tr(ref, 'agents_search_hint'),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(ref, 'agents_subtitle'),
                style: const TextStyle(fontSize: 13, color: AppColors.grey600),
              ),
            ),
          ),
          Expanded(
            child: agentsAsync.when(
              loading: () => const MkLoading(),
              error: (e, _) => MkErrorWidget(message: e.toString()),
              data: (agents) {
                final filtered = _query.isEmpty
                    ? agents
                    : agents.where((a) {
                        final q = _query;
                        return a.name.toLowerCase().contains(q) ||
                            (a.location?.toLowerCase().contains(q) ?? false) ||
                            (a.bio?.toLowerCase().contains(q) ?? false);
                      }).toList();
                if (filtered.isEmpty) {
                  return MkEmptyState(
                    title: tr(ref, 'agents_no_results'),
                    subtitle: tr(ref, 'agents_subtitle'),
                    icon: Icons.badge_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _AgentTile(
                    agent: filtered[i],
                    onTap: () => context.push(
                      AppRoutes.agentDetail.replaceAll(':uid', filtered[i].uid),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 4),
    );
  }
}

class _AgentTile extends StatelessWidget {
  final AgentDirectoryEntry agent;
  final VoidCallback onTap;
  const _AgentTile({required this.agent, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: Row(
              children: [
                UserAvatar(
                  name: agent.displayName,
                  photoUrl: agent.photoUrl,
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agent.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      if (agent.location?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          agent.location!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (agent.bio?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          agent.bio!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
