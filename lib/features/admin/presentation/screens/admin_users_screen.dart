import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:merokotha/features/admin/providers/admin_providers.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

enum _UserFilter { all, pendingAgents, verifiedAgents, banned }

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  _UserFilter _filter = _UserFilter.all;

  bool _matchesFilter(UserModel u) {
    switch (_filter) {
      case _UserFilter.all:
        return true;
      case _UserFilter.pendingAgents:
        return u.agentStatus == AgentStatus.pending;
      case _UserFilter.verifiedAgents:
        return u.agentStatus == AgentStatus.verified;
      case _UserFilter.banned:
        return u.isBanned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(searchedUsersProvider);
    final query = ref.watch(userSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AdminAppBar(
        title: 'Users',
        showBack: false,
        actions: [
          if (query.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(userSearchProvider.notifier).clear();
                _searchCtrl.clear();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AdminColors.primary,            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(userSearchProvider.notifier).setQuery(v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: const TextStyle(
                  color: AppColors.grey400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.grey400,
                  size: 20,
                ),
                filled: true,
                fillColor: AdminColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: const BorderSide(
                    color: AdminColors.accent,
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Review filter chips
          Container(
            color: AdminColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _UserFilterChip(
                    label: 'All',
                    selected: _filter == _UserFilter.all,
                    onTap: () => setState(() => _filter = _UserFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _UserFilterChip(
                    label: 'Pending agents',
                    selected: _filter == _UserFilter.pendingAgents,
                    onTap: () =>
                        setState(() => _filter = _UserFilter.pendingAgents),
                  ),
                  const SizedBox(width: 8),
                  _UserFilterChip(
                    label: 'Verified agents',
                    selected: _filter == _UserFilter.verifiedAgents,
                    onTap: () =>
                        setState(() => _filter = _UserFilter.verifiedAgents),
                  ),
                  const SizedBox(width: 8),
                  _UserFilterChip(
                    label: 'Banned',
                    selected: _filter == _UserFilter.banned,
                    onTap: () => setState(() => _filter = _UserFilter.banned),
                  ),
                ],
              ),
            ),
          ),

          // User list
          Expanded(
            child: usersAsync.when(
              loading: () => ShimmerLoading(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, _) => ShimmerBox(
                    height: 84,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
              ),
              error: (e, _) => MkErrorWidget(message: e.toString()),
              data: (all) {
                final users = all.where(_matchesFilter).toList();
                if (users.isEmpty) {
                  return MkEmptyState(
                    title: query.isNotEmpty ? 'No users found' : 'No users yet',
                    subtitle: query.isNotEmpty
                        ? 'Try a different name or phone number'
                        : 'Users will appear here after they sign up',
                    icon: Icons.people_outline_rounded,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return AdminUserTile(
                      user: u,
                      onTap: () => context.push(
                        AppRoutes.adminUserDetail.replaceAll(':uid', u.id),
                      ),
                      onBan: () => _showBanDialog(context, ref, u.id, u.name),
                      onUnban: () async {
                        final ok = await ref
                            .read(adminActionProvider.notifier)
                            .unbanUser(u.id);
                        if (!ok && context.mounted) {
                          final err =
                              ref.read(adminActionProvider).error ??
                              'Failed to unban. Please try again.';
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppColors.error,
                              ),
                            );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showBanDialog(
    BuildContext context,
    WidgetRef ref,
    String uid,
    String name,
  ) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ban $name?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This user will not be able to use the app. Add an optional reason:',
              style: TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Reason (optional)'),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref
                  .read(adminActionProvider.notifier)
                  .banUser(
                    uid,
                    reason: reasonCtrl.text.trim().isEmpty
                        ? null
                        : reasonCtrl.text.trim(),
                  );
              if (!ok && context.mounted) {
                final err =
                    ref.read(adminActionProvider).error ??
                    'Failed to ban. Please try again.';
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                    ),
                  );
              }
            },
            child: const Text(
              'Ban user',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UserFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
}
