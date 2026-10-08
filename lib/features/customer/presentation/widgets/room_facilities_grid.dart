import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

const _facilityIcons = <String, IconData>{
  'wifi': Icons.wifi_rounded,
  'parking': Icons.local_parking_rounded,
  'water': Icons.water_drop_outlined,
  'electricity': Icons.bolt_rounded,
  'kitchen': Icons.kitchen_outlined,
  'laundry': Icons.local_laundry_service_outlined,
  'lift': Icons.elevator_outlined,
  'security': Icons.security_outlined,
};

class RoomFacilitiesGrid extends StatelessWidget {
  final List<String> facilities;
  const RoomFacilitiesGrid(this.facilities, {super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: facilities.map((f) {
      final icon = _facilityIcons[f] ?? Icons.check_circle_outlined;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              f[0].toUpperCase() + f.substring(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
