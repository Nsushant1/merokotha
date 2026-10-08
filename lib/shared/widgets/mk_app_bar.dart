import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';

/// Top bar matching design.jpeg list screens: white with hairline bottom,
/// 40px circular back button, centered 17px w800 dark title, optional
/// red text action (Reset) or icon actions on the right.
class MkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final Color? backgroundColor;
  final VoidCallback? onBack;
  final bool centerTitle;

  const MkAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.backgroundColor,
    this.onBack,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(61);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      toolbarHeight: 60,
      titleSpacing: 4,
      leading:
          leading ??
          (showBack && canPop
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: MkCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack ?? () => Navigator.pop(context),
                  ),
                )
              : null),
      leadingWidth: (showBack && canPop) || leading != null ? 56 : 0,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.2,
          color: AppColors.textPrimary,
        ),
      ),
      actions: actions != null
          ? [...actions!, const SizedBox(width: 8)]
          : [const SizedBox(width: 56)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

/// 40px white circular icon button with hairline border + soft shadow.
/// Used for back / share / favourite / filter actions over photos and bars.
class MkCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;
  final bool selected;

  const MkCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14063B7A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            size: 19,
            color: selected
                ? AppColors.accent
                : (iconColor ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Red text button for app-bar trailing actions (Reset, Clear).
class MkBarTextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const MkBarTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(48, 40),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
