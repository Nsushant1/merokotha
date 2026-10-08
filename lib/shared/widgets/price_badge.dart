import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/utils/formatters.dart';

class PriceBadge extends StatelessWidget {
  final double amount;
  final bool showPerMonth;
  final double fontSize;

  const PriceBadge({
    super.key,
    required this.amount,
    this.showPerMonth = true,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Rs. ${_format(amount)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.price,
            ),
          ),
          if (showPerMonth)
            TextSpan(
              text: '/mo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
        ],
      ),
    );
  }

  String _format(double v) => Formatters.amount(v);
}
