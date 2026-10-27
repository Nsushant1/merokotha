import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/auth/providers/pending_inquiry_provider.dart';
import 'package:merokotha/shared/widgets/app_back_scope.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

/// Combined sign-in screen: Google one-tap plus email/password
/// (sign in, registration, password reset). Linking between providers
/// happens in Profile (same Firebase UID is preserved either way).
class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isRegister = false;
  bool _isEmailBusy = false;
  bool _obscure = true;
  String? _emailError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Shared post-auth routing for Google + email flows: resumes a pending
  /// guest inquiry, falls back to onboarding for new users, and routes
  /// existing users by role/verification/ban state.
  Future<void> _routeAfterAuth() async {
    // Use the synchronous FirebaseAuth user, not the async stream provider
    // value — authStateProvider may not have emitted yet, which previously
    // caused a silent no-navigation after a successful sign-in.
    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser == null || !mounted) return;

    try {
      final userExists = await ref
          .read(userRepositoryProvider)
          .userExists(firebaseUser.uid);
      if (!mounted) return;

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
        context.push(AppRoutes.onboarding);
      } else {
        final user = await ref
            .read(userRepositoryProvider)
            .getUser(firebaseUser.uid);
        if (!mounted) return;
        if (user?.isBanned == true) {
          context.go(AppRoutes.banned);
        } else if (user?.isAdmin == true) {
          context.go(AppRoutes.adminHome);
        } else if (user?.isVerifiedAgent == true) {
          context.go(AppRoutes.agentHome);
        } else {
          context.go(AppRoutes.home);
        }
      }
    } catch (_) {
      if (!mounted) return;
      context.go(AppRoutes.onboarding);
    }
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref
        .read(googleSignInProvider.notifier)
        .signInWithGoogle();
    if (!success || !mounted) return;
    await _routeAfterAuth();
  }

  String _mapEmailError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in, or use Google and link email from Profile.';
      case 'account-exists-with-different-credential':
        return 'This email is already registered with Google. Sign in with Google, then link email from Profile.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isEmailBusy = true;
      _emailError = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isRegister) {
        await repo.signUpWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      } else {
        await repo.signInWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
      await _routeAfterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _emailError = _mapEmailError(e));
    } catch (_) {
      if (mounted) {
        setState(() => _emailError = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isEmailBusy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _emailError = 'Enter your account email above first.',
      );
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _emailError = _mapEmailError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(googleSignInProvider);
    final textTheme = Theme.of(context).textTheme;
    return AppBackScope(
      homeRoute: AppRoutes.landing,
      popWhenPossible: true,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePaddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
                    MkButton(
                      label: 'Continue with Google',
                      onPressed: signInState.isLoading
                          ? null
                          : _signInWithGoogle,
                      isLoading: signInState.isLoading,
                      variant: MkButtonVariant.outline,
                      prefixIcon: Icons.g_mobiledata_rounded,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or with email',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                Validators.required(v, fieldName: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (_isRegister && v.length < 6) {
                                return 'At least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                        child: Text(
                          _emailError!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    MkButton(
                      label: _isRegister ? 'Create Account' : 'Sign In',
                      onPressed: _isEmailBusy ? null : _submitEmail,
                      isLoading: _isEmailBusy,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _isRegister = !_isRegister;
                            _emailError = null;
                          }),
                          child: Text(
                            _isRegister
                                ? 'Have an account? Sign in'
                                : "No account? Register",
                          ),
                        ),
                        TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
