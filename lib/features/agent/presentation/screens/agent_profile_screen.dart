import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/agent/presentation/widgets/agent_bottom_nav.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/auth/providers/pending_inquiry_provider.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// Agent profile: verification status, browsing shortcut, sign out.
/// Verified agents reach the shared home via Browse; there is no role to
/// switch — agent access derives from the approved application.
class AgentProfileScreen extends ConsumerWidget {
  const AgentProfileScreen({super.key});

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
    // Clears session state only; the saved Firestore role/profile stays
    // so the next sign-in restores it directly.
    await signOutAndClearSession(ref);
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Verified by admin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MkButton(
                  label: 'Browse rooms',
                  onPressed: () => context.push(AppRoutes.home),
                  variant: MkButtonVariant.secondary,
                  prefixIcon: Icons.search_rounded,
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
