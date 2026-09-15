import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/shared/models/listing_model.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';

import 'package:merokotha/features/admin/providers/admin_providers.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentUsersAsync = ref.watch(recentUsersProvider);
    final recentListingsAsync = ref.watch(recentListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AdminAppBar(
        title: 'Admin Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AdminColors.accent,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentUsersProvider);
          ref.invalidate(recentListingsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AdminColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: AppSizes.shadowRaised,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AdminColors.accent,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AdminColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    ref
                        .watch(currentUserProvider)
                        .when(
                          data: (u) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${u?.name ?? 'Admin'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Super Administrator',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.grey400,
                                ),
                              ),
                            ],
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const _SectionHeader('Platform overview'),
              const SizedBox(height: 12),

              statsAsync.when(
                loading: () => const _StatsGridSkeleton(),
                error: (e, _) => MkErrorWidget(message: e.toString()),
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            label: 'Total users',
                            value: '${stats.totalUsers}',
                            icon: Icons.people_rounded,
                            color: AppColors.primary,
                            onTap: () => context.go(AppRoutes.adminUsers),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminStatCard(
                            label: 'House owners',
                            value: '${stats.totalOwners}',
                            icon: Icons.house_rounded,
                            color: AppColors.info,
                            onTap: () => context.go(AppRoutes.adminUsers),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            label: 'Agents',
                            value: '${stats.totalAgents}',
                            icon: Icons.support_agent_rounded,
                            color: AppColors.success,
                            onTap: () => context.go(AppRoutes.adminUsers),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminStatCard(
                            label: 'Room seekers',
                            value: '${stats.totalCustomers}',
                            icon: Icons.search_rounded,
                            color: AppColors.customerPrimary,
                            onTap: () => context.go(AppRoutes.adminUsers),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            label: 'Active listings',
                            value: '${stats.activeListings}',
                            icon: Icons.home_work_rounded,
                            color: AppColors.secondary,
                            onTap: () => context.go(AppRoutes.adminListings),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminStatCard(
                            label: 'Total listings',
                            value: '${stats.totalListings}',
                            icon: Icons.list_alt_rounded,
                            color: AppColors.grey800,
                            onTap: () => context.go(AppRoutes.adminListings),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            label: 'Pending inquiries',
                            value: '${stats.pendingInquiries}',
                            icon: Icons.inbox_rounded,
                            color: AppColors.warning,
                            onTap: () => context.go(AppRoutes.adminInquiries),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminStatCard(
                            label: 'Banned users',
                            value: '${stats.bannedUsers}',
                            icon: Icons.block_rounded,
                            color: AppColors.error,
                            onTap: () => context.go(AppRoutes.adminUsers),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const _SectionHeader('Quick actions'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _QuickAction(
                    label: 'All users',
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.adminUsers),
                  ),
                  _QuickAction(
                    label: 'Listings',
                    icon: Icons.home_work_rounded,
                    color: AppColors.info,
                    onTap: () => context.push(AppRoutes.adminListings),
                  ),
                  _QuickAction(
                    label: 'Inquiries',
                    icon: Icons.inbox_rounded,
                    color: AppColors.warning,
                    onTap: () => context.push(AppRoutes.adminInquiries),
                  ),

                ],
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                'Recent signups',
                onSeeAll: () => context.go(AppRoutes.adminUsers),
              ),
              const SizedBox(height: 12),
              recentUsersAsync.when(
                loading: () => const _ListRowsSkeleton(),
                error: (_, _) => const SizedBox.shrink(),
                data: (users) => Column(
                  children: users
                      .map(
                        (u) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AdminUserTile(
                            user: u,
                            onTap: () => context.push(
                              AppRoutes.adminUserDetail.replaceAll(
                                ':uid',
                                u.id,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                'Recent listings',
                onSeeAll: () => context.go(AppRoutes.adminListings),
              ),
              const SizedBox(height: 12),
              recentListingsAsync.when(
                loading: () => const _ListRowsSkeleton(),
                error: (_, _) => const SizedBox.shrink(),
                data: (listings) => Column(
                  children: listings
                      .map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AdminListingTile(
                            listing: l,
                            onDelete: () =>
                                _confirmDelete(context, ref, l.id, l.title),
                            onToggleStatus: () => ref
                                .read(adminActionProvider.notifier)
                                .setListingStatus(
                                  l.id,
                                  l.isActive
                                      ? ListingStatus.paused
                                      : ListingStatus.active,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('Delete "$title"? This cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminActionProvider.notifier).deleteListing(id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader(this.title, {this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.grey900,
        ),
      ),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget tile() => Expanded(
      child: ShimmerBox(
        height: 116,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
    );
    return ShimmerLoading(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Row(children: [tile(), const SizedBox(width: 10), tile()]),
            if (i < 2) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ListRowsSkeleton extends StatelessWidget {
  const _ListRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShimmerBox(
                height: 74,
                width: double.infinity,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, size: 17, color: color),
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
