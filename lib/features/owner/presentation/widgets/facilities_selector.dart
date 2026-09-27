import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

class FacilitiesSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const FacilitiesSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    ('WiFi', Icons.wifi_rounded),
    ('Parking', Icons.local_parking_rounded),
    ('Water', Icons.water_drop_outlined),
    ('Electricity', Icons.bolt_rounded),
    ('Kitchen', Icons.kitchen_outlined),
    ('Laundry', Icons.local_laundry_service_outlined),
    ('Security', Icons.shield_outlined),
    ('Lift', Icons.elevator_outlined),
    ('CCTV', Icons.videocam_outlined),
    ('Generator', Icons.electrical_services_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((option) {
        final (label, icon) = option;
        final isSelected = selected.contains(label);
        return Material(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            onTap: () {
              final updated = [...selected];
              isSelected ? updated.remove(label) : updated.add(label);
              onChanged(updated);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.6 : 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? AppColors.primary : AppColors.grey600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.primary : AppColors.grey600,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
