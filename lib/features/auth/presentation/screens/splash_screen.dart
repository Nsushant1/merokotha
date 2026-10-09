import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';

/// Splash screen — visual reference: design.jpeg first frame.
/// Full-bleed Kathmandu photo (assets/design/splash_screen_image.jpg)
/// with the brand mark over the sky and a deep-blue wave panel at the
/// bottom holding a red loading pill (echoes the "Get Started" CTA).
/// Auto-routes after auth check; no user interaction required.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final firebaseUser = await ref.read(authStateProvider.future);

    if (firebaseUser == null) {
      if (!mounted) return;
      context.go(AppRoutes.landing);
      return;
    }

    // A Firestore failure (e.g. offline) must not freeze the splash:
    // fall back to the public landing screen and let later screens retry.
    // Role selection only appears when no valid saved role exists.
    try {
      final userExists = await ref
          .read(userRepositoryProvider)
          .userExists(firebaseUser.uid);

      if (!mounted) return;

      if (!userExists) {
        context.go(AppRoutes.roleSelect);
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
      context.go(AppRoutes.landing);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo backdrop ──
            Image.asset(
              'assets/design/splash_screen_image.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            // Soft top veil so the status bar stays legible over the sky.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            // ── Content ──
            SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        // Logo badge
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/merokotha.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Wordmark — dark on sky, exactly like design.jpeg
                        RichText(
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              shadows: [
                                Shadow(
                                  color: Color(0x66FFFFFF),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            children: [
                              TextSpan(
                                text: 'Mero ',
                                style: TextStyle(color: AppColors.primaryDark),
                              ),
                              TextSpan(
                                text: 'Kotha',
                                style: TextStyle(color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'तपाईंको सपनाको घर, अब सजिलै',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                              shadows: [
                                Shadow(color: Color(0x99FFFFFF), blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // ── Bottom wave panel ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            28,
                            26,
                            28,
                            22 + bottomPadding,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0757B8), Color(0xFF063B7A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(36),
                              topRight: Radius.circular(36),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Find your perfect room',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              // Red pill — mirrors the "Get Started" CTA,
                              // spinner inside signals auto-routing.
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x40FF1F2D),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Finding your kotha…',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Rooms · Flats · Houses across Nepal',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
