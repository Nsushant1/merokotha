import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  Future<void> _signInWithGoogle() async {
    final success = await ref.read(googleSignInProvider.notifier).signInWithGoogle();
    if (!success || !mounted) return;

    final firebaseUser = ref.read(authStateProvider).value;
    if (firebaseUser == null) return;

    final userExists = await ref.read(userRepositoryProvider).userExists(firebaseUser.uid);
    if (!mounted) return;

    if (!userExists) {
      context.go(AppRoutes.roleSelect);
    } else {
      final user = await ref.read(userRepositoryProvider).getUser(firebaseUser.uid);
      if (!mounted) return;
      if (user?.isAdmin == true) {
        context.go(AppRoutes.adminHome);
      } else if (user?.isAgent == true) {
        context.go(AppRoutes.agentHome);
      } else if (user?.isOwner == true) {
        context.go(AppRoutes.ownerHome);
      } else {
        context.go(AppRoutes.customerHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(googleSignInProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/merokotha.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to MeroKotha',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to list rooms, save favourites, and chat with owners.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey600,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              MkButton(
                label: 'Continue with Google',
                onPressed: signInState.isLoading ? null : _signInWithGoogle,
                isLoading: signInState.isLoading,
                prefixIcon: Icons.g_mobiledata_rounded,
              ),
              const SizedBox(height: 16),
              if (signInState.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Text(
                    signInState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
