import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImage;
  final bool isSending;
  final bool enabled;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onImage,
    this.isSending = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _RoundIconTap(
            onTap: enabled ? onImage : null,
            icon: Icons.image_outlined,
            background: AppColors.backgroundSecondary,
            iconColor: AppColors.grey600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Rebuilds whenever the controller notifies (text, selection) or the
          // send state flips, so the button reflects both.
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final hasText = controller.text.trim().isNotEmpty;
              final active = enabled && !isSending && hasText;
              return _RoundIconTap(
                onTap: active ? onSend : null,
                icon: isSending ? Icons.more_horiz_rounded : Icons.send_rounded,
                background: active ? AppColors.accent : AppColors.grey100,
                iconColor: Colors.white,
                shadow: active,
                loading: isSending,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoundIconTap extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final bool shadow;
  final bool loading;

  const _RoundIconTap({
    required this.onTap,
    required this.icon,
    required this.background,
    required this.iconColor,
    this.shadow = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: shadow ? AppSizes.shadowButton : null,
          ),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  ),
                )
              : Icon(icon, size: 19, color: iconColor),
        ),
      ),
    );
  }
}
