import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/chat/data/chat_model.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
    this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final failed = message.isFailed;
    final dimmed = message.isPending || failed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Opacity(
        opacity: dimmed ? 0.65 : 1,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  child: Container(
                    padding: message.hasImage
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.white,
                      border: isMe
                          ? Border.all(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.3,
                              ),
                            )
                          : Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 6),
                        bottomRight: Radius.circular(isMe ? 6 : 20),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A1A1A18),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (message.hasImage) _attachment(),
                        if (message.text.isNotEmpty)
                          Padding(
                            padding: message.hasImage
                                ? const EdgeInsets.fromLTRB(10, 6, 10, 8)
                                : EdgeInsets.zero,
                            child: Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: isMe ? Colors.white : AppColors.grey900,
                                height: 1.45,
                              ),
                            ),
                          ),
                        _footer(),
                      ],
                    ),
                  ),
                ),
                if (isMe) const SizedBox(width: 4),
              ],
            ),
            if (failed) _failureRow(context),
          ],
        ),
      ),
    );
  }

  Widget _attachment() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: message.imageUrl!.startsWith('/')
          ? Image.file(
              File(message.imageUrl!),
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : CachedNetworkImage(
              imageUrl: message.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ShimmerLoading(
                child: ShimmerBox(height: 160, width: double.infinity),
              ),
              errorWidget: (_, _, _) => Container(
                height: 120,
                color: AppColors.grey100,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.grey400,
                ),
              ),
            ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: message.hasImage
          ? const EdgeInsets.fromLTRB(10, 0, 10, 6)
          : const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Formatters.time(message.createdAt),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.75)
                  : AppColors.grey400,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            if (message.isPending)
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              )
            else
              Icon(
                message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                size: 13,
                color: message.isRead
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
          ],
        ],
      ),
    );
  }

  Widget _failureRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 4, right: isMe ? 4 : 0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            message.failureReason ?? 'Message not sent',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onRetry != null)
                _FailureAction(label: 'Retry', onTap: onRetry!),
              if (onRetry != null && onDiscard != null)
                const SizedBox(width: 10),
              if (onDiscard != null)
                _FailureAction(label: 'Delete', onTap: onDiscard!),
            ],
          ),
        ],
      ),
    );
  }
}

class _FailureAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FailureAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.error,
          ),
        ),
      ),
    );
  }
}
