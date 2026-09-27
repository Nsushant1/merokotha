import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';

/// Owner dashboard greeting — unified header type:
/// tracked uppercase eyebrow + 28px extrabold name.
class OwnerGreeting extends StatelessWidget {
  final String name;
  const OwnerGreeting({super.key, required this.name});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name.split(' ').first,
          style: textTheme.displayMedium,
        ),
      ],
    );
  }
}
