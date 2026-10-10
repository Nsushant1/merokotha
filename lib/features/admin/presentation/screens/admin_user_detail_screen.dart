import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:merokotha/features/admin/providers/admin_providers.dart';
import 'package:merokotha/features/home/providers/agent_application_providers.dart';
import 'package:merokotha/shared/models/agent_application_model.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  final String uid;
  const AdminUserDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserDetailProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const AdminAppBar(title: 'User detail', showBack: true),
      body: userAsync.when(
        loading: () => ShimmerLoading(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              children: [
                ShimmerBox(
                  height: 260,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                const SizedBox(height: 16),
                ShimmerBox(
                  height: 160,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                const SizedBox(height: 16),
                ShimmerBox(
                  height: 220,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ],
            ),
          ),
        ),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (user) {
          if (user == null) {
            return const MkErrorWidget(message: 'User not found');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: user.isBanned
                        ? Border.all(color: AppColors.error, width: 1.5)
                        : Border.all(color: AppColors.border),
                    boxShadow: AppSizes.shadowCard,
                  ),
                  child: Column(
                    children: [
                      if (user.isBanned)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.block_rounded,
                                size: 14,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'This user is banned',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (user.isBanned) const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: UserAvatar(
                          name: user.name,
                          photoUrl: user.photoUrl,
                          size: 76,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Joined ${Formatters.date(user.createdAt)}',
                          ),
                          _RoleBadgeDetail(role: user.role),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _Card(
                  title: 'Admin actions',
                  children: [
                    if (!user.isBanned)
                      _ActionTile(
                        icon: Icons.block_rounded,
                        label: 'Ban this user',
                        color: AppColors.error,
                        onTap: () => _showBanDialog(context, ref, user),
                      )
                    else
                      _ActionTile(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Unban this user',
                        color: AppColors.success,
                        onTap: () async {
                          final ok = await ref
                              .read(adminActionProvider.notifier)
                              .unbanUser(user.id);
                          if (!context.mounted) return;
                          if (ok) {
                            context.pop();
                          } else {
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
                      ),
                    const Divider(height: 1, color: AppColors.border),
                    _ActionTile(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Change role',
                      color: AppColors.info,
                      onTap: () => _showRoleDialog(context, ref, user),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _AgentApplicationCard(user: user),

                const SizedBox(height: 16),

                _Card(
                  title: 'Account info',
                  children: [
                    _InfoRow(label: 'User ID', value: user.id),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      label: 'Role',
                      value:
                          user.role.name[0].toUpperCase() +
                          user.role.name.substring(1),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      label: 'Joined',
                      value: Formatters.date(user.createdAt),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      label: 'Location',
                      value: user.location ?? 'Not set',
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      label: 'Verified',
                      value: user.isVerified ? 'Yes' : 'No',
                    ),
                    if (user.isBanned) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _InfoRow(
                        label: 'Ban status',
                        value: 'Banned',
                        valueColor: AppColors.error,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBanDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ban ${user.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This user will not be able to access the app.',
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
                    user.id,
                    reason: reasonCtrl.text.trim().isEmpty
                        ? null
                        : reasonCtrl.text.trim(),
                  );
              if (!context.mounted) return;
              if (ok) {
                context.pop();
              } else {
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
            child: const Text('Ban', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select new role for this user:',
              style: TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
            const SizedBox(height: 12),
            ...UserRole.values
                .where((r) => r != UserRole.superAdmin)
                .map(
                  (r) => ListTile(
                    leading: Icon(
                      r == UserRole.owner
                          ? Icons.house_rounded
                          : r == UserRole.agent
                          ? Icons.support_agent_rounded
                          : Icons.search_rounded,
                      color: r == UserRole.owner
                          ? AppColors.ownerPrimary
                          : r == UserRole.agent
                          ? AppColors.agentPrimary
                          : AppColors.customerPrimary,
                    ),
                    title: Text(r.name[0].toUpperCase() + r.name.substring(1)),
                    selected: user.role == r,
                    onTap: () {
                      Navigator.pop(context);
                      ref
                          .read(adminActionProvider.notifier)
                          .setUserRole(user.id, r)
                          .then((_) => context.pop());
                    },
                  ),
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
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: color.withValues(alpha: 0.5),
          ),
        ],
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(color: AppColors.border),
      boxShadow: AppSizes.shadowCard,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.grey600,
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.grey400),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.grey600),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.grey400),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.grey800,
          ),
        ),
      ],
    ),
  );
}

/// Agent application review for one user.
///
/// Driven by the `agentApplications/{uid}` document: shows submitted
/// details while pending with Approve/Reject actions, the verdict once
/// decided, and a hint when no application exists. Decisions flip the
/// applicant's `agentStatus` atomically — the legacy `isVerified` flag is
/// no longer consulted for access.
class _AgentApplicationCard extends ConsumerWidget {
  final UserModel user;
  const _AgentApplicationCard({required this.user});

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool approved,
    String? reason,
  }) async {
    final ok = await ref
        .read(agentDecisionProvider.notifier)
        .decide(uid: user.id, approved: approved, reason: reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approved ? 'Agent approved.' : 'Application rejected.')
              : 'Failed to save decision. Please try again.',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  /// Returns the entered reason (possibly empty) on Reject, or null when
  /// the dialog is cancelled — so rejecting without a reason works.
  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject application?'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason shown to the applicant (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: const Text(
              'Reject',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    await _decide(
      context,
      ref,
      approved: false,
      reason: result.isEmpty ? null : result,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(agentApplicationProvider(user.id));
    return _Card(
      title: 'Agent application',
      children: [
        appAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text(
            'Failed to load: $e',
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
          data: (app) {
            if (app == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No application filed.',
                    style: TextStyle(fontSize: 13, color: AppColors.grey600),
                  ),
                  if (user.isAgent) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Legacy role-agent account. Ask the user to apply from Profile, or change their role.',
                      style: TextStyle(fontSize: 12, color: AppColors.grey400),
                    ),
                  ],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Name', value: app.fullName),
                const Divider(height: 1, color: AppColors.border),
                _InfoRow(label: 'Phone', value: app.phone),
                const Divider(height: 1, color: AppColors.border),
                _InfoRow(label: 'Location', value: app.location),
                if (app.notes?.isNotEmpty ?? false) ...[
                  const Divider(height: 1, color: AppColors.border),
                  _InfoRow(label: 'Notes', value: app.notes!),
                ],
                const Divider(height: 1, color: AppColors.border),
                _InfoRow(
                  label: 'Status',
                  value: app.status.name,
                  valueColor: switch (app.status) {
                    AgentApplicationStatus.approved => AppColors.success,
                    AgentApplicationStatus.rejected => AppColors.error,
                    AgentApplicationStatus.pending => AppColors.warning,
                  },
                ),
                if (app.status == AgentApplicationStatus.rejected &&
                    (app.reason?.isNotEmpty ?? false)) ...[
                  const Divider(height: 1, color: AppColors.border),
                  _InfoRow(label: 'Reason', value: app.reason!),
                ],
                if (app.status == AgentApplicationStatus.pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DecisionButton(
                          label: 'Approve',
                          color: AppColors.success,
                          onTap: () => _decide(context, ref, approved: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DecisionButton(
                          label: 'Reject',
                          color: AppColors.error,
                          outlined: true,
                          onTap: () => _showRejectDialog(context, ref),
                        ),
                      ),
                    ],
                  ),
                ],
                if (app.status != AgentApplicationStatus.pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DecisionButton(
                          label: app.status == AgentApplicationStatus.approved
                              ? 'Revoke access'
                              : 'Approve',
                          color: app.status == AgentApplicationStatus.approved
                              ? AppColors.error
                              : AppColors.success,
                          outlined: true,
                          onTap: () =>
                              app.status == AgentApplicationStatus.approved
                              ? _showRejectDialog(context, ref)
                              : _decide(context, ref, approved: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: outlined ? color : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadgeDetail extends StatelessWidget {
  final UserRole role;
  const _RoleBadgeDetail({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role == UserRole.owner
        ? AppColors.ownerPrimary
        : role == UserRole.agent
        ? AppColors.agentPrimary
        : role == UserRole.superAdmin
        ? const Color(0xFFB5790E)
        : AppColors.customerPrimary;
    final bg = role == UserRole.owner
        ? AppColors.ownerLight
        : role == UserRole.agent
        ? AppColors.agentLight
        : role == UserRole.superAdmin
        ? AdminColors.accentLight
        : AppColors.customerLight;
    final label = role.name[0].toUpperCase() + role.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
