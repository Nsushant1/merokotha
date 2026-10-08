import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Search input matching design.jpeg: white 14px-radius card, hairline
/// border, soft blue shadow, dark search icon, grey-blue hint.
class MkSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final Widget? suffix;

  const MkSearchField.editable({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.suffix,
  }) : readOnly = false,
       onTap = null;

  const MkSearchField.readOnly({
    super.key,
    required this.hint,
    required this.onTap,
    this.suffix,
  }) : readOnly = true,
       onChanged = null,
       controller = null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D063B7A),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    );

    const prefix = Icon(
      Icons.search_rounded,
      size: 21,
      color: AppColors.textPrimary,
    );

    if (readOnly) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.fromLTRB(16, 0, 7, 0),
          decoration: decoration,
          child: Row(
            children: [
              prefix,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
      );
    }

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: decoration,
      child: Row(
        children: [
          prefix,
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }
}

/// Red gradient circular filter button inside search (design.jpeg).
class MkSearchSuffixButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const MkSearchSuffixButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x40FF1F2D),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
