import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_nav.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

class AdminUserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onBan;
  final VoidCallback? onUnban;

  const AdminUserTile({
    super.key,
    required this.user,
    this.onTap,
    this.onBan,
    this.onUnban,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: user.isBanned ? AppColors.errorLight : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: user.isBanned
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: user.isBanned ? null : AppSizes.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                UserAvatar(
                  name: user.name,
                  photoUrl: user.photoUrl,
                  size: 44,
                  backgroundColor: user.isOwner
                      ? AppColors.ownerLight
                      : user.isAdmin
                      ? AdminColors.accentLight
                      : AppColors.customerLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey900,
                              ),
                            ),
                          ),
                          if (user.isBanned) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BANNED',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: const TextStyle(fontSize: 12, color: AppColors.grey400),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _RoleBadge(role: user.role),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.timeAgo(user.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (user.isBanned && onUnban != null)
                  _SmallAction(
                    label: 'Unban',
                    color: AppColors.success,
                    onTap: onUnban!,
                  )
                else if (!user.isBanned && !user.isAdmin && onBan != null)
                  _SmallAction(label: 'Ban', color: AppColors.error, onTap: onBan!),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.grey400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminListingTile extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onTap;

  const AdminListingTile({
    super.key,
    required this.listing,
    this.onDelete,
    this.onToggleStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppSizes.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: listing.photoUrls.isNotEmpty
                      ? Image.network(
                          listing.photoUrls.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder,
                        )
                      : _placeholder,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        listing.ownerName,
                        style: const TextStyle(fontSize: 11, color: AppColors.grey400),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          PriceBadge(amount: listing.rentPerMonth, fontSize: 12),
                          const SizedBox(width: 8),
                          _statusBadge(listing.status),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (onToggleStatus != null)
                      _SmallAction(
                        label: listing.isActive ? 'Pause' : 'Activate',
                        color: AppColors.warning,
                        onTap: onToggleStatus!,
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(height: 4),
                      _SmallAction(
                        label: 'Delete',
                        color: AppColors.error,
                        onTap: onDelete!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get _placeholder => Container(
    width: 60,
    height: 60,
    color: AppColors.backgroundSecondary,
    child: const Icon(Icons.image_outlined, color: AppColors.grey200, size: 24),
  );

  Widget _statusBadge(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return StatusBadge.active();
      case ListingStatus.paused:
        return StatusBadge.paused();
      case ListingStatus.rented:
        return StatusBadge.rented();
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (role) {
      case UserRole.owner:
        bg = AppColors.ownerLight;
        fg = AppColors.ownerPrimary;
        label = 'Owner';
        break;
      case UserRole.customer:
        bg = AppColors.customerLight;
        fg = AppColors.customerPrimary;
        label = 'Customer';
        break;
      case UserRole.agent:
        bg = AppColors.agentLight;
        fg = AppColors.agentPrimary;
        label = 'Agent';
        break;
      case UserRole.superAdmin:
        bg = AdminColors.accentLight;
        fg = const Color(0xFFB5790E);
        label = 'Admin';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
