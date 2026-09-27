import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

enum MkButtonVariant { primary, secondary, outline, ghost, danger }

class MkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MkButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? prefixIcon;
  final double? height;

  const MkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MkButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.prefixIcon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? AppSizes.buttonHeight;
    final radius = BorderRadius.circular(AppSizes.radiusMd);

    final spinnerColor = switch (variant) {
      MkButtonVariant.primary => Colors.white,
      MkButtonVariant.danger => AppColors.error,
      _ => AppColors.primary,
    };

    Widget child = isLoading
        ? SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: spinnerColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final size = Size(fullWidth ? double.infinity : 0, h);
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2);

    switch (variant) {
      case MkButtonVariant.primary:
        return _TapScale(
          onTap: isLoading ? null : onPressed,
          child: Container(
            width: fullWidth ? double.infinity : null,
            height: h,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: onPressed == null && !isLoading
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: onPressed == null && !isLoading ? AppColors.grey100 : null,
              boxShadow: onPressed == null ? null : AppSizes.shadowButton,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: isLoading ? null : onPressed,
                splashColor: Colors.white.withValues(alpha: 0.12),
                highlightColor: Colors.white.withValues(alpha: 0.06),
                child: Center(
                  child: DefaultTextStyle(
                    style: textStyle.copyWith(color: Colors.white),
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case MkButtonVariant.secondary:
        return SizedBox(
          width: size.width,
          height: h,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.grey50,
              shape: RoundedRectangleBorder(borderRadius: radius),
              elevation: 0,
              textStyle: textStyle,
            ),
            child: child,
          ),
        );

      case MkButtonVariant.outline:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: h,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.grey900,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: textStyle,
            ),
            child: child,
          ),
        );

      case MkButtonVariant.ghost:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: h,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: textStyle,
            ),
            child: child,
          ),
        );

      case MkButtonVariant.danger:
        return SizedBox(
          width: size.width,
          height: h,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              foregroundColor: AppColors.error,
              disabledBackgroundColor: AppColors.grey50,
              shape: RoundedRectangleBorder(borderRadius: radius),
              elevation: 0,
              textStyle: textStyle,
            ),
            child: child,
          ),
        );
    }
  }
}

/// Subtle press-down scale for a more tactile, premium tap feel.
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
