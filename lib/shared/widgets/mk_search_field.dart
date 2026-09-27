import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Unified search input — one visual pattern for landing, customer home,
/// search, admin, and map screens.
///
/// [MkSearchField.readOnly]: fake button-style search (navigates on tap).
/// [MkSearchField.editable]: real TextField bound to [onChanged].
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
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border, width: 1.2),
    );

    final prefix = const Icon(
      Icons.search_rounded,
      size: 20,
      color: AppColors.grey400,
    );

    if (readOnly) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSizes.inputHeight,
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          decoration: decoration,
          child: Row(
            children: [
              prefix,
              const SizedBox(width: 10),
              Expanded(
                child: Text(hint, style: textTheme.bodyMedium),
              ),
              ?suffix,
            ],
          ),
        ),
      );
    }

    return Container(
      height: AppSizes.inputHeight,
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
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }
}

/// Circular primary action suffix used inside [MkSearchField.readOnly]
/// (e.g. the filter button on customer home).
class MkSearchSuffixButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const MkSearchSuffixButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}
