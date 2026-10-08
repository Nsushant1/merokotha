import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';

class RoomInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RoomInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey400),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.grey400),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
      ],
    ),
  );
}
