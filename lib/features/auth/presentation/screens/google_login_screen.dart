import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/auth/providers/pending_inquiry_provider.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/app_back_scope.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  Future<void> _signInWithGoogle() async {
    final success = await ref
        .read(googleSignInProvider.notifier)
        .signInWithGoogle();
    if (!success || !mounted) return;

    // Use the synchronous FirebaseAuth user, not the async stream provider
    // value — authStateProvider may not have emitted yet, which previously
    // caused a silent no-navigation after a successful sign-in.
    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser == null) return;

    final pendingRole = GoRouterState.of(context).extra;

    // Firestore/App Check failures here must not be mistaken for login
    // failures; fall back to role selection so the user is not stuck.
    try {
      final userExists = await ref
          .read(userRepositoryProvider)
          .userExists(firebaseUser.uid);
      if (!mounted) return;

      // Guest tapped Message Owner before signing in: resume straight
      // into that room's inquiry flow instead of losing the selection.
      final pending = ref.read(pendingInquiryProvider);
      if (pending != null && userExists) {
        ref.read(pendingInquiryProvider.notifier).clear();
        if (!mounted) return;
        context.pushReplacement(
          AppRoutes.inquire.replaceAll(':id', pending.id),
          extra: pending,
        );
        return;
      }

      if (!userExists) {
        // A role chosen on the role-selection screen (reached before login
        // from Landing) is carried through, so onboarding starts pre-filled.
        // Push (not go) keeps the room route mounted so a pending guest
        // inquiry survives for onboarding to resume after profile setup.
        // New users without a role pick one during onboarding's guard.
        if (pendingRole is UserRole) {
          context.push(AppRoutes.onboarding, extra: pendingRole);
        } else {
          context.go(AppRoutes.roleSelect);
        }
      } else {
        final user = await ref
            .read(userRepositoryProvider)
            .getUser(firebaseUser.uid);
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
    // Back from login always returns to Landing (never closes the app),
    // no matter how this page was reached (push, go, or auth redirect).
    return AppBackScope(
      homeRoute: AppRoutes.landing,
      popWhenPossible: true,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
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
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppSizes.shadowCard,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Image.asset(
                          'assets/merokotha.png',
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: textTheme.displaySmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        children: const [
                          TextSpan(text: 'Welcome to '),
                          TextSpan(
                            text: 'Mero ',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(
                            text: 'Kotha',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to list rooms, save favourites, and chat with owners.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    MkButton(
                      label: 'Continue with Google',
                      onPressed: signInState.isLoading
                          ? null
                          : _signInWithGoogle,
                      isLoading: signInState.isLoading,
                      variant: MkButtonVariant.outline,
                      prefixIcon: Icons.g_mobiledata_rounded,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By continuing you agree to our Terms & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (signInState.errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
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
      ),
    );
  }
}
