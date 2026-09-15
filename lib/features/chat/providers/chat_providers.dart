import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/chat/data/chat_model.dart';
import 'package:merokotha/features/chat/data/chat_repository.dart';

part 'chat_providers.g.dart';

@riverpod
Stream<List<ChatModel>> myChats(Ref ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return const Stream.empty();

  // Agents act on the lister side (same ownerId slot as owners).
  if (user.isLister) {
    return ref.watch(chatRepositoryProvider).watchOwnerChats(user.id);
  } else {
    return ref.watch(chatRepositoryProvider).watchCustomerChats(user.id);
  }
}

@riverpod
Stream<ChatModel?> chatThread(Ref ref, String chatId) {
  return ref.watch(chatRepositoryProvider).watchChat(chatId);
}

@riverpod
Stream<List<MessageModel>> chatMessages(Ref ref, String chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
}

@riverpod
Stream<int> totalUnread(Ref ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return Stream.value(0);

  return ref
      .watch(chatRepositoryProvider)
      .watchTotalUnread(userId: user.id, isOwner: user.isLister);
}

class SendMessageState {
  final bool isSending;
  final String? error;
  const SendMessageState({this.isSending = false, this.error});
}

@riverpod
class SendMessageNotifier extends _$SendMessageNotifier {
  @override
  SendMessageState build() => const SendMessageState();

  Future<void> send({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
    required bool senderIsOwner,
  }) async {
    if (text.trim().isEmpty && imageUrl == null) return;
    state = const SendMessageState(isSending: true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            chatId: chatId,
            senderId: senderId,
            text: text.trim(),
            imageUrl: imageUrl,
            senderIsOwner: senderIsOwner,
          );
      state = const SendMessageState();
    } catch (e) {
      state = SendMessageState(error: e.toString());
    }
  }
}
