import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

const _facilityOptions = [
  ('wifi', 'WiFi', Icons.wifi_rounded),
  ('parking', 'Parking', Icons.local_parking_rounded),
  ('water', 'Water', Icons.water_drop_outlined),
  ('electricity', 'Electricity', Icons.bolt_rounded),
  ('kitchen', 'Kitchen', Icons.kitchen_outlined),
  ('laundry', 'Laundry', Icons.local_laundry_service_outlined),
];

class FacilityFilterRow extends StatelessWidget {
  final List<String> selected;
  final void Function(List<String>) onChanged;

  const FacilityFilterRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _facilityOptions.map((f) {
        final isOn = selected.contains(f.$1);
        return GestureDetector(
          onTap: () {
            final updated = List<String>.from(selected);
            isOn ? updated.remove(f.$1) : updated.add(f.$1);
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isOn ? AppColors.accentLight : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: isOn ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  f.$3,
                  size: 14,
                  color: isOn ? AppColors.accentDark : AppColors.grey400,
                ),
                const SizedBox(width: 5),
                Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn ? AppColors.accentDark : AppColors.grey600,
                    fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
