import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/agent/presentation/widgets/agent_bottom_nav.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/promo_banner_carousel.dart';

/// Agent dashboard: posting on behalf of owners and handling inquiries.
/// Full posting / listings / inbox flows land in later phases.
class AgentHomeScreen extends ConsumerWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const MkAppBar(title: 'Agent Hub', showBack: false),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste, ${user.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Post rooms for owners and handle inquiries.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                      // Only verified agents reach this screen (router
                      // guard); unverified visitors see their application
                      // status on the shared home profile instead.
                    ],
                  );
                },
              ),
              // ── Promo banner (external destinations, 3s auto-scroll) ──
              // Same reusable carousel as Landing / Customer / Owner home.
              const SizedBox(height: 16),
              const PromoBannerCarousel(),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  _AgentAction(
                    label: 'Post a room',
                    icon: Icons.add_home_work_outlined,
                    onTap: () => context.push(AppRoutes.agentUpload),
                  ),
                  _AgentAction(
                    label: 'My listings',
                    icon: Icons.list_alt_outlined,
                    onTap: () => context.push(AppRoutes.agentListings),
                  ),
                  _AgentAction(
                    label: 'Inbox',
                    icon: Icons.inbox_outlined,
                    onTap: () => context.push(AppRoutes.agentInquiries),
                  ),
                  _AgentAction(
                    label: 'Browse rooms',
                    icon: Icons.search_rounded,
                    onTap: () => context.push(AppRoutes.home),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 0),
    );
  }
}

class _AgentAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AgentAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border),
      boxShadow: AppSizes.shadowCard,
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.agentLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, size: 17, color: AppColors.agentPrimary),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
