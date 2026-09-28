import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/features/landing/presentation/widgets/landing_theme.dart';

/// Public search input — polished card matching the landing visual system.
///
/// API unchanged: still a live TextField bound to [onChanged], so the
/// landing screen's client-side filtering keeps working exactly as before.
class LandingSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const LandingSearchBar({super.key, required this.onChanged});

  @override
  State<LandingSearchBar> createState() => _LandingSearchBarState();
}

class _LandingSearchBarState extends State<LandingSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _focusNode.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasText = _controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: AppSizes.inputHeight + 4,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      decoration: BoxDecoration(
        color: LandingTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: _focused ? AppColors.primary : LandingTheme.hairline,
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: _focused
            ? const [
                BoxShadow(
                  color: Color(0x1F1D9E75),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ]
            : AppSizes.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: AppSizes.iconMd,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (v) {
                widget.onChanged(v);
                setState(() {});
              },
              style: textTheme.bodyLarge,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by location or name…',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: hasText
                ? GestureDetector(
                    key: const ValueKey('clear'),
                    onTap: _clear,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.grey100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: AppColors.grey600,
                        semanticLabel: 'Clear search',
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), width: 8),
          ),
        ],
      ),
    );
  }
}
