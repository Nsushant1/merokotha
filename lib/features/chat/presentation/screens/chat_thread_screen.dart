import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/chat/data/chat_model.dart';
import 'package:merokotha/features/chat/providers/chat_providers.dart';
import 'package:merokotha/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:merokotha/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:merokotha/features/chat/presentation/widgets/chat_date_divider.dart';
import 'package:merokotha/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:merokotha/features/notification/messaging_service.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatThreadScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen>
    with WidgetsBindingObserver {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  bool _atBottom = true;
  bool _uploading = false;
  String? _lastMarkedMessageId;

  /// `maxScrollExtent` captured before an older page is prepended, so the
  /// viewport can be re-anchored afterwards and the user keeps their place.
  double? _anchorExtent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollCtrl.addListener(_onScroll);
    // Suppress push notifications for the conversation already on screen.
    MessagingService.instance.activeChatId = widget.chatId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.removeListener(_onScroll);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    if (MessagingService.instance.activeChatId == widget.chatId) {
      MessagingService.instance.activeChatId = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Foregrounding the thread means anything that arrived while it was
    // backgrounded has now been seen.
    if (state == AppLifecycleState.resumed) _markRead();
  }

  Future<void> _markRead() async {
    // Awaited, not read synchronously: on a cold start into a deep link the
    // profile may still be loading, and a skipped mark-read would leave the
    // badge and receipts stale.
    final uid = (await ref.read(currentUserProvider.future))?.id;
    if (uid == null || !mounted) return;
    await ref
        .read(threadReadMarkerProvider.notifier)
        .markRead(widget.chatId, uid);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 80;
    if (atBottom != _atBottom && mounted) setState(() => _atBottom = atBottom);

    final thread = ref.read(chatMessagesProvider(widget.chatId));
    if (pos.pixels <= 80 && thread.hasMore && !thread.isLoadingMore) {
      _requestOlder();
    }
  }

  void _requestOlder() {
    if (!_scrollCtrl.hasClients) return;
    _anchorExtent = _scrollCtrl.position.maxScrollExtent;
    ref.read(chatMessagesProvider(widget.chatId).notifier).loadMore();
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      if (mounted && !_atBottom) setState(() => _atBottom = true);
    });
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _scrollToBottom();

    final ok = await ref
        .read(chatMessagesProvider(widget.chatId).notifier)
        .send(text: text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Message failed to send.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => ref
                  .read(chatMessagesProvider(widget.chatId).notifier)
                  .send(text: text),
            ),
          ),
        );
    }
  }

  Future<void> _sendImage() async {
    if (_uploading) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    setState(() => _uploading = true);
    final storage = ref.read(firebaseStorageProvider);

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final target = storage.ref().child('chats/${widget.chatId}/$fileName');
      final task = await target.putFile(
        File(picked.path),
        SettableMetadata(
          contentType: 'image/jpeg',
          // Storage rules bind chat uploads to their uploader, so either
          // participant can only manage their own attachments.
          customMetadata: {'uploadedBy': user.id},
        ),
      );
      final imageUrl = await task.ref.getDownloadURL();

      if (!mounted) return;
      _scrollToBottom();
      await ref
          .read(chatMessagesProvider(widget.chatId).notifier)
          .send(text: '', imageUrl: imageUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to send image. Try again.')),
        );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatThreadProvider(widget.chatId));
    final thread = ref.watch(chatMessagesProvider(widget.chatId));
    final notifier = ref.read(chatMessagesProvider(widget.chatId).notifier);
    final user = ref.watch(currentUserProvider).asData?.value;
    final myUid = user?.id ?? '';
    final messages = thread.visibleMessages;

    ref.listen(chatMessagesProvider(widget.chatId), (prev, next) {
      final grew = next.messages.length > (prev?.messages.length ?? 0);

      // Re-anchor the viewport after an older page is prepended.
      final anchor = _anchorExtent;
      if (anchor != null && grew) {
        _anchorExtent = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollCtrl.hasClients) return;
          final delta = _scrollCtrl.position.maxScrollExtent - anchor;
          if (delta > 0) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.pixels + delta);
          }
        });
      }

      // Only follow new messages when the user is already at the bottom —
      // otherwise yanking them down would destroy their place in the history.
      if (grew && _atBottom) _scrollToBottom();

      final confirmed = next.messages.where((m) => !m.isPending).toList();
      if (confirmed.isNotEmpty) {
        final newest = confirmed.last.id;
        if (newest != _lastMarkedMessageId) {
          _lastMarkedMessageId = newest;
          _markRead();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: chatAsync.when(
        data: (chat) => ChatAppBar(chat: chat, myUid: myUid),
        loading: () => AppBar(
          backgroundColor: Colors.white,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        error: (_, _) => AppBar(
          backgroundColor: Colors.white,
          leading: BackButton(onPressed: () => context.pop()),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _body(thread, messages, notifier, myUid),
                ),
                if (messages.isNotEmpty && !_atBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _JumpToLatest(
                      count: _newerThanMarked(messages),
                      onTap: _scrollToBottom,
                    ),
                  ),
              ],
            ),
          ),

          ChatInputBar(
            controller: _textCtrl,
            onSend: _sendText,
            onImage: _sendImage,
            isSending: _uploading,
          ),
        ],
      ),
    );
  }

  Widget _body(
    ChatMessagesState thread,
    List<MessageModel> messages,
    ChatMessagesNotifier notifier,
    String myUid,
  ) {
    if (thread.error != null && messages.isEmpty) {
      return MkErrorWidget(message: thread.error.toString());
    }
    if (messages.isEmpty) {
      return thread.isLoading
          ? const MkLoading()
          : const MkEmptyState(
              icon: Icons.waving_hand_rounded,
              title: 'Say hello!',
              subtitle: 'Start the conversation below',
            );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _HistoryHeader(
            hasMore: thread.hasMore,
            isLoadingMore: thread.isLoadingMore,
            error: thread.loadMoreError,
            onRetry: _requestOlder,
          );
        }

        final msg = messages[index - 1];
        final isMe = msg.senderId == myUid;
        final showDate =
            index == 1 ||
            !_sameDay(messages[index - 2].createdAt, msg.createdAt);

        return Column(
          children: [
            if (showDate) ChatDateDivider(msg.createdAt),
            ChatMessageBubble(
              message: msg,
              isMe: isMe,
              onRetry: msg.isFailed ? () => notifier.retry(msg.id) : null,
              onDiscard: msg.isFailed
                  ? () => notifier.discardPending(msg.id)
                  : null,
            ),
          ],
        );
      },
    );
  }

  int _newerThanMarked(List<MessageModel> messages) {
    final marked = _lastMarkedMessageId;
    if (marked == null) return 0;
    final idx = messages.indexWhere((m) => m.id == marked);
    if (idx < 0) return 0;
    return messages.length - idx - 1;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;
}

class _HistoryHeader extends StatelessWidget {
  final bool hasMore;
  final bool isLoadingMore;
  final Object? error;
  final VoidCallback onRetry;

  const _HistoryHeader({
    required this.hasMore,
    required this.isLoadingMore,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Could not load earlier messages. Tap to retry.'),
        ),
      );
    }
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore) {
      return Center(
        child: TextButton(
          onPressed: onRetry,
          child: const Text('Load earlier messages'),
        ),
      );
    }
    return const SizedBox(height: 4);
  }
}

class _JumpToLatest extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _JumpToLatest({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      elevation: 3,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: count > 0 ? 14 : 0),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_double_arrow_down_rounded,
                color: Colors.white,
                size: 20,
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
