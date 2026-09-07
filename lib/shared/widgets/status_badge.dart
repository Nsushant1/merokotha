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
    color: AppColors.error,
    backgroundColor: AppColors.errorLight,
  );

  factory StatusBadge.fromListingStatus(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return StatusBadge.active();
      case ListingStatus.paused:
        return StatusBadge.paused();
      case ListingStatus.rented:
        return StatusBadge.rented();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
