import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/chat/data/chat_model.dart';
import 'package:merokotha/features/chat/data/chat_repository.dart';

part 'chat_providers.g.dart';

/// Number of messages fetched per page when paging through a thread.
const int kChatMessagePageSize = 40;

@Riverpod(keepAlive: true)
Stream<List<ChatModel>> myChats(Ref ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return const Stream.empty();

  final repo = ref.watch(chatRepositoryProvider);
  var backfillStarted = false;

  return repo.watchChatsForUser(user.id).map((chats) {
    // Conversations created before `lastMessageAt` existed sort to the bottom
    // of an activity-ordered list. Fill the missing field once, in the
    // background — data is preserved, nothing is deleted.
    if (!backfillStarted && chats.any((c) => c.lastMessageAt == null)) {
      backfillStarted = true;
      unawaited(
        repo.backfillActivityTimestamps(chats).catchError((_) => <void>{}),
      );
    }
    return chats;
  });
}

@riverpod
Stream<ChatModel?> chatThread(Ref ref, String chatId) {
  return ref.watch(chatRepositoryProvider).watchChat(chatId);
}

@riverpod
Stream<int> totalUnread(Ref ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return Stream.value(0);

  return ref.watch(chatRepositoryProvider).watchTotalUnread(user.id);
}

// ─────────────────────────────────────────────────────────────────────────────
// Thread state
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ChatMessagesState {
  /// Confirmed messages from Firestore, oldest → newest.
  final List<MessageModel> messages;

  /// Messages that exist only on this device: in flight, or failed and
  /// awaiting retry / discard. Rendered after [messages].
  final List<MessageModel> pending;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final Object? loadMoreError;

  const ChatMessagesState({
    this.messages = const [],
    this.pending = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.loadMoreError,
  });

  /// Everything the list should render, chronologically ordered.
  List<MessageModel> get visibleMessages {
    if (pending.isEmpty) return messages;
    final merged = [...messages, ...pending]
      ..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });
    return merged;
  }

  bool get hasFailedMessages => pending.any((m) => m.isFailed);

  ChatMessagesState copyWith({
    List<MessageModel>? messages,
    List<MessageModel>? pending,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    Object? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }
}

/// Owns one thread: paged message history, the live tail, optimistic sends,
/// failure state and retry.
@riverpod
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  static int _seq = 0;

  bool _primed = false;

  /// Captured in [build]; family arguments are not otherwise readable from
  /// inside method bodies.
  late String chatId;

  @override
  ChatMessagesState build(String chatIdArg) {
    chatId = chatIdArg;
    final repo = ref.watch(chatRepositoryProvider);

    final sub = repo
        .watchLatestMessages(chatIdArg, kChatMessagePageSize)
        .listen(
          _onTail,
          onError: (Object e, StackTrace _) {
            if (!ref.mounted) return;
            state = state.copyWith(isLoading: false, error: e);
          },
        );
    ref.onDispose(sub.cancel);

    return const ChatMessagesState(isLoading: true);
  }

  /// Live tail arrived — merge it into whatever is already loaded.
  void _onTail(List<MessageModel> latest) {
    if (!ref.mounted) return;

    final byId = <String, MessageModel>{
      for (final m in state.messages) m.id: m,
    };
    for (final m in latest) {
      byId[m.id] = m;
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

    // A snapshot that exactly fills the page probably has more behind it.
    final mayHaveMore = _primed
        ? state.hasMore
        : latest.length >= kChatMessagePageSize;
    _primed = true;

    state = state.copyWith(
      messages: merged,
      isLoading: false,
      hasMore: mayHaveMore,
      clearError: true,
    );
  }

  /// Fetch the next older page. No-op when exhausted or already in flight.
  Future<void> loadMore() async {
    if (!ref.mounted) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.messages.isEmpty) return;

    final oldest = state.messages.first;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);

    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .fetchMessagesBefore(
            chatId: chatId,
            cursor: MessageCursor(createdAt: oldest.createdAt, id: oldest.id),
            limit: kChatMessagePageSize,
          );

      if (!ref.mounted) return;

      if (page.messages.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      final byId = <String, MessageModel>{
        for (final m in state.messages) m.id: m,
      };
      for (final m in page.messages) {
        byId[m.id] = m;
      }
      final merged = byId.values.toList()
        ..sort((a, b) {
          final byDate = a.createdAt.compareTo(b.createdAt);
          if (byDate != 0) return byDate;
          return a.id.compareTo(b.id);
        });

      state = state.copyWith(
        messages: merged,
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: e);
    }
  }

  // ── Sending ─────────────────────────────────────────────────────────────

  /// Send a message. The message appears immediately as a pending bubble;
  /// on failure it stays in place marked as failed so it can be retried.
  /// Returns true when the write succeeded.
  Future<bool> send({required String text, String? imageUrl}) async {
    // Awaited rather than read synchronously: `currentUserProvider` is async,
    // and a send tapped before the profile resolves would otherwise be
    // silently dropped.
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return false;

    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl == null) return false;
    if (trimmed.length > 1000) {
      // Surfaced as a failed bubble so the user sees why, and can trim it.
      state = state.copyWith(
        pending: [
          ...state.pending,
          MessageModel(
            id: 'pending_invalid_${_seq++}',
            senderId: user.id,
            text: trimmed,
            createdAt: DateTime.now(),
            failureReason: 'Message is too long (max 1000 characters)',
          ),
        ],
      );
      return false;
    }

    final localId =
        'pending_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';
    final optimistic = MessageModel(
      id: localId,
      senderId: user.id,
      text: trimmed,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isPending: true,
    );

    state = state.copyWith(pending: [...state.pending, optimistic]);

    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            chatId: chatId,
            senderId: user.id,
            text: trimmed,
            imageUrl: imageUrl,
          );
      _dropPending(localId);
      return true;
    } catch (e) {
      _markFailed(localId, e);
      return false;
    }
  }

  /// Re-attempt a previously failed message.
  Future<void> retry(String pendingId) async {
    final failed = state.pending.where((m) => m.id == pendingId).firstOrNull;
    if (failed == null) return;

    // Remove the failed bubble first, then go through the normal send path so
    // the retry gets a fresh in-flight entry rather than leaving the old
    // failure marker behind alongside it.
    _dropPending(pendingId);
    await send(text: failed.text, imageUrl: failed.imageUrl);
  }

  /// Discard a failed message.
  void discardPending(String pendingId) => _dropPending(pendingId);

  void _dropPending(String id) => _dropPendingWhere((m) => m.id == id);

  void _dropPendingWhere(bool Function(MessageModel) test) {
    if (!ref.mounted) return;
    state = state.copyWith(
      pending: state.pending.where((m) => !test(m)).toList(),
    );
  }

  void _markFailed(String id, Object error) {
    if (!ref.mounted) return;
    state = state.copyWith(
      pending: [
        for (final m in state.pending)
          if (m.id == id)
            m.copyWith(isPending: false, failureReason: _describe(error))
          else
            m,
      ],
    );
  }

  String _describe(Object error) {
    if (error is ChatSendException) {
      final cause = error.cause;
      if (cause is String) return cause;
      return 'Message not sent. Check your connection and try again.';
    }
    if (error is ChatNotParticipantException) {
      return 'You are not a participant of this conversation.';
    }
    return 'Message not sent. Check your connection and try again.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Read state
// ─────────────────────────────────────────────────────────────────────────────

/// Flips read receipts and clears the conversation badge for a thread.
///
/// Kept alive across screen disposal so a retry scheduled by a disposed
/// screen still completes.
@Riverpod(keepAlive: true)
class ThreadReadMarker extends _$ThreadReadMarker {
  final Set<String> _inFlight = <String>{};

  @override
  void build() {}

  /// Mark the thread read. Safe to call repeatedly — writes are skipped when
  /// there is nothing to clear.
  Future<void> markRead(String chatId, String readerUid) async {
    if (_inFlight.contains(chatId)) return;
    _inFlight.add(chatId);
    try {
      final repo = ref.read(chatRepositoryProvider);
      // Receipts and the badge are independent: a failure on one must not
      // stop the other from being applied.
      await Future.wait([
        repo.markMessagesRead(chatId: chatId, readerUid: readerUid),
        repo.markConversationRead(chatId: chatId, readerUid: readerUid),
      ]).catchError((_) => <void>[]);
    } finally {
      _inFlight.remove(chatId);
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
