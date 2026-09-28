import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

void showLoginSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const LoginSheet(),
  );
}

class LoginSheet extends StatelessWidget {
  const LoginSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: AppSizes.shadowRaised,
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
                width: 1,
              ),
            ),
            child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            'Ready to Move In?',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to contact owners, save listings, and schedule viewings.',
            style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.grey600, height: 1.5),
          ),
          const SizedBox(height: 28),
          MkButton(
            label: 'Get Started',
            // Push (not go) so the login page sits on top of the current
            // stack — system back returns to the previous screen instead
            // of closing the app.
            onPressed: () => context.push(AppRoutes.login),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Maybe later',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
