import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
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

    // Use the synchronous FirebaseAuth user, not the async stream provider
    // value — authStateProvider may not have emitted yet, which previously
    // caused a silent no-navigation after a successful sign-in.
    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser == null) return;

    // Firestore/App Check failures here must not be mistaken for login
    // failures; fall back to role selection so the user is not stuck.
    try {
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
    } catch (_) {
      if (!mounted) return;
      context.go(AppRoutes.roleSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(googleSignInProvider);

    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.pagePaddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/merokotha.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Welcome to MeroKotha',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to list rooms, save favourites, and chat with owners.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.grey600,
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        signInState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
