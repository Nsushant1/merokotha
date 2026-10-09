import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/shared/widgets/user_avatar.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppSizes.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.grey600,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSizes.cardPaddingLarge),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final int? count;
  final Color? countColor;
  final Color? countBackgroundColor;
  final VoidCallback? onTap;

  const ProfileSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.count,
    this.countColor,
    this.countBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  color: AppColors.grey900,
                ),
              ),
            ),
            if (count != null && count! > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: countBackgroundColor ?? AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: countColor ?? AppColors.grey600,
                  ),
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.border);
}

/// Gradient profile header matching design.jpeg: deep-blue gradient with
/// red wash, white avatar ring, white name + 70% email, gear action.
class MkProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback? onSettings;
  final String roleLabel;
  final IconData roleIcon;

  const MkProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
    this.onSettings,
    this.roleLabel = '',
    this.roleIcon = Icons.person_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        MediaQuery.paddingOf(context).top + 16,
        AppSizes.pagePadding,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF063B7A), Color(0xFF0757B8), Color(0xFFB3122E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 2.5,
              ),
            ),
            child: UserAvatar(
              name: name,
              photoUrl: photoUrl,
              size: 64,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                if (roleLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onSettings != null)
            GestureDetector(
              onTap: onSettings,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
