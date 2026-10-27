import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/shared/models/listing_model.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  factory StatusBadge.active() => const StatusBadge(
    label: 'Active',
    color: AppColors.success,
    backgroundColor: AppColors.successLight,
  );

  factory StatusBadge.paused() => const StatusBadge(
    label: 'Paused',
    color: AppColors.warning,
    backgroundColor: AppColors.warningLight,
  );

  factory StatusBadge.rented() => const StatusBadge(
    label: 'Rented',
    color: AppColors.grey600,
    backgroundColor: AppColors.grey50,
  );

  factory StatusBadge.suspended() => const StatusBadge(
    label: 'Suspended',
    color: AppColors.error,
    backgroundColor: AppColors.errorLight,
  );

  factory StatusBadge.verified() => const StatusBadge(
    label: 'Verified',
    color: AppColors.success,
    backgroundColor: AppColors.successLight,
  );

  factory StatusBadge.needsChanges() => const StatusBadge(
    label: 'Needs changes',
    color: AppColors.error,
    backgroundColor: AppColors.errorLight,
  );

  factory StatusBadge.fromVerification(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return StatusBadge.verified();
      case VerificationStatus.rejected:
        return StatusBadge.needsChanges();
      case VerificationStatus.pending:
        return StatusBadge.pending();
    }
  }

  factory StatusBadge.pending() => const StatusBadge(
    label: 'Pending',
    color: AppColors.warning,
    backgroundColor: AppColors.warningLight,
  );

  factory StatusBadge.accepted() => const StatusBadge(
    label: 'Accepted',
    color: AppColors.success,
    backgroundColor: AppColors.successLight,
  );

  factory StatusBadge.declined() => const StatusBadge(
    label: 'Declined',
    color: AppColors.accentDark,
    backgroundColor: AppColors.accentLight,
  );

  factory StatusBadge.fromListingStatus(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return StatusBadge.active();
      case ListingStatus.paused:
        return StatusBadge.paused();
      case ListingStatus.rented:
        return StatusBadge.rented();
      case ListingStatus.suspended:
        return StatusBadge.suspended();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.1,
          color: color,
        ),
      ),
    );
  }
}

/// Solid overlay badge used on listing photos — matches design.jpeg:
/// red pill for sale, blue pill for rent, white bold text.
class ListingTypeBadge extends StatelessWidget {
  final String label;
  final bool forSale;

  const ListingTypeBadge({
    super.key,
    required this.label,
    required this.forSale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: forSale ? AppColors.accent : AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          height: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}
