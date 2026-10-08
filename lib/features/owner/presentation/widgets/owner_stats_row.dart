import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/features/owner/presentation/widgets/stats_card.dart';
import 'package:merokotha/shared/models/listing_model.dart';

class OwnerStatsRow extends StatelessWidget {
  final List<ListingModel> listings;
  const OwnerStatsRow({super.key, required this.listings});

  @override
  Widget build(BuildContext context) {
    final active = listings
        .where((l) => l.status == ListingStatus.active)
        .length;
    final paused = listings
        .where((l) => l.status == ListingStatus.paused)
        .length;
    final rented = listings
        .where((l) => l.status == ListingStatus.rented)
        .length;

    return Row(
      children: [
        Expanded(
          child: StatsCard(
            label: 'Active',
            value: '$active',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatsCard(
            label: 'Paused',
            value: '$paused',
            icon: Icons.pause_circle_outline_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatsCard(
            label: 'Rented',
            value: '$rented',
            icon: Icons.home_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
