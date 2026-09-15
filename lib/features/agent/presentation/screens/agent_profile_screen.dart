import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/agent/presentation/widgets/agent_bottom_nav.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Agent profile shell (Phase 2): verification status, role switch, sign out.
class AgentProfileScreen extends ConsumerWidget {
  const AgentProfileScreen({super.key});

  Future<void> _switchToCustomer(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Switch to Room Seeker?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will be switched to Room Seeker mode.',
          style: TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Switch',
              style: TextStyle(
                color: AppColors.customerPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(userRepositoryProvider).updateRole(user.id, UserRole.customer);
    if (context.mounted) context.go(AppRoutes.customerHome);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Sign out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'Profile', showBack: false),
      body: userAsync.when(
        loading: () => const MkLoading(),
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
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppSizes.shadowCard,
                  ),
                  child: Column(
                    children: [
                      UserAvatar(
                        name: user.name,
                        photoUrl: user.photoUrl,
                        size: 72,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.agentLight,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: const Text(
                          'Agent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.agentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            user.isVerified
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            size: 16,
                            color: user.isVerified
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.isVerified
                                ? 'Verified by admin'
                                : 'Awaiting admin verification',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: user.isVerified
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MkButton(
                  label: 'Switch to Room Seeker mode',
                  onPressed: () => _switchToCustomer(context, ref, user),
                  variant: MkButtonVariant.secondary,
                  prefixIcon: Icons.swap_horiz_rounded,
                ),
                const SizedBox(height: 12),
                MkButton(
                  label: 'Sign out',
                  onPressed: () => _signOut(context, ref),
                  variant: MkButtonVariant.danger,
                  prefixIcon: Icons.logout_rounded,
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 4),
    );
  }
}
