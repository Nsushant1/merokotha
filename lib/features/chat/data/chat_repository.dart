import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/providers/firebase_providers.dart';
import 'package:merokotha/features/chat/data/chat_model.dart';

part 'chat_repository.g.dart';

/// Thrown when the caller is not a participant of the conversation they are
/// trying to act on. Raised client-side *before* a write is attempted so the
/// UI can show a meaningful error instead of a raw rules rejection.
class ChatNotParticipantException implements Exception {
  final String chatId;
  final String uid;
  const ChatNotParticipantException(this.chatId, this.uid);

  @override
  String toString() =>
      'ChatNotParticipantException: user $uid is not a participant of $chatId';
}

/// A send that failed. Carries everything needed to retry it verbatim.
class ChatSendException implements Exception {
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final Object cause;

  const ChatSendException({
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.cause,
    this.imageUrl,
  });

  @override
  String toString() => 'ChatSendException(chat: $chatId): $cause';
}

/// Cursor for loading older pages of a thread.
class MessageCursor {
  final DateTime createdAt;
  final String id;

  const MessageCursor({required this.createdAt, required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);

  @override
  String toString() => 'MessageCursor($id @ $createdAt)';
}

/// One page of messages, oldest → newest.
class MessagePage {
  final List<MessageModel> messages;
  final bool hasMore;
  final MessageCursor? cursor;

  const MessagePage({
    required this.messages,
    required this.hasMore,
    this.cursor,
  });

  static const empty = MessagePage(messages: [], hasMore: false);
}

/// Data-access contract for the chat feature.
///
/// Declared as an abstract class with a redirecting factory so tests can supply
/// an in-memory fake (`class FakeChatRepository implements ChatRepository`)
/// without standing up Firestore. Production code keeps using
/// `ChatRepository(db)`.
abstract class ChatRepository {
  factory ChatRepository(FirebaseFirestore db) = FirestoreChatRepository;

  /// Deterministically derived document id for a (lister, customer, listing)
  /// triple. Two concurrent acceptances produce the *same* id, so they
  /// collapse into one document instead of racing to create duplicates.
  static String deterministicChatId({
    required String ownerId,
    required String customerId,
    required String listingId,
  }) => 'c_${ownerId}_${customerId}_$listingId';

  Future<String> createChat({
    required String createdByUid,
    required String inquiryId,
    required String ownerId,
    required String ownerName,
    String? ownerPhotoUrl,
    required String customerId,
    required String customerName,
    String? customerPhotoUrl,
    required String listingId,
    required String listingTitle,
  });

  Stream<List<ChatModel>> watchChatsForUser(String userId);

  Stream<ChatModel?> watchChat(String chatId);

  Stream<int> watchTotalUnread(String userId);

  /// Live tail of a thread: at most [limit] most recent messages, ascending.
  Stream<List<MessageModel>> watchLatestMessages(String chatId, int limit);

  /// Older page of messages, strictly before [cursor]. Ascending.
  Future<MessagePage> fetchMessagesBefore({
    required String chatId,
    required MessageCursor cursor,
    required int limit,
  });

  Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  });

  /// Zero the conversation counter belonging to [readerUid].
  Future<void> markConversationRead({
    required String chatId,
    required String readerUid,
  });

  /// Flip `isRead` on every message in the thread not sent by [readerUid].
  /// Returns the number of messages updated.
  Future<int> markMessagesRead({
    required String chatId,
    required String readerUid,
    int maxBatch = 400,
    int maxTotal = 2000,
  });

  /// Give legacy chats (created before `lastMessageAt` existed) an activity
  /// timestamp so they keep sorting correctly once the list orders by
  /// `lastMessageAt`. Data-preserving: only fills a missing field.
  Future<void> backfillActivityTimestamps(List<ChatModel> chats);
}

class FirestoreChatRepository implements ChatRepository {
  final FirebaseFirestore _db;

  FirestoreChatRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _db.collection('chats').doc(chatId).collection('messages');

  // ── Conversation lifecycle ──────────────────────────────────────────────

  @override
  Future<String> createChat({
    required String createdByUid,
    required String inquiryId,
    required String ownerId,
    required String ownerName,
    String? ownerPhotoUrl,
    required String customerId,
    required String customerName,
    String? customerPhotoUrl,
    required String listingId,
    required String listingTitle,
  }) async {
    final chatId = ChatRepository.deterministicChatId(
      ownerId: ownerId,
      customerId: customerId,
      listingId: listingId,
    );

    // Fast path: the deterministic document already exists (including a
    // conversation created by a concurrent acceptance). Returning without
    // writing avoids a no-op update that Firestore rules would reject as an
    // identity-field change on legacy documents.
    final deterministic = await _chats.doc(chatId).get();
    if (deterministic.exists) {
      return chatId;
    }

    // Fallback for chats created before the deterministic-id scheme: reuse a
    // legacy thread for the same triple instead of opening a duplicate.
    // (Three chained equality filters need a composite index when the backend
    // enforces it; the deterministic get above already handles the common
    // case, so a missing index here only affects pre-scheme threads.)
    final existing = await _chats
        .where('ownerId', isEqualTo: ownerId)
        .where('customerId', isEqualTo: customerId)
        .where('listingId', isEqualTo: listingId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final data = <String, dynamic>{
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhotoUrl': customerPhotoUrl,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'inquiryId': inquiryId,
      'lastMessage': null,
      // Same server timestamp as createdAt so the conversation sorts into the
      // right position immediately instead of trailing every other thread.
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': null,
      'unreadOwner': 0,
      'unreadCustomer': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // merge:true means "create if absent, otherwise leave untouched". Two
    // concurrent acceptances both target the same deterministic id, so the
    // second one is a no-op update instead of a duplicate insert.
    await _chats.doc(chatId).set(data, SetOptions(merge: true));

    return chatId;
  }

  @override
  Future<void> backfillActivityTimestamps(List<ChatModel> chats) async {
    final stale = chats
        .where((c) => c.lastMessageAt == null && c.id.isNotEmpty)
        .take(50)
        .toList();
    if (stale.isEmpty) return;

    final batch = _db.batch();
    for (final chat in stale) {
      batch.update(_chats.doc(chat.id), {
        'lastMessageAt': Timestamp.fromDate(chat.createdAt),
      });
    }
    await batch.commit();
  }

  // ── Conversation reads ──────────────────────────────────────────────────

  @override
  Stream<List<ChatModel>> watchChatsForUser(String userId) {
    if (userId.isEmpty) return Stream.value(const []);

    // A user is on the owner side of some chats and the customer side of
    // others (e.g. an agent handling listings they posted, while also renting
    // as a customer). Both sides must be merged; deriving the field from the
    // caller's *role* instead of from the stored ids was the unread-count bug.
    final asOwner = _chats
        .where('ownerId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
    final asCustomer = _chats
        .where('customerId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();

    return _mergeStreams(asOwner, asCustomer)
        .map((snapshots) {
          final docs = [...snapshots.$1.docs, ...snapshots.$2.docs];
          final chats = docs.map(ChatModel.fromSnapshot).toList()
            ..sort((a, b) => b.activityAt.compareTo(a.activityAt));
          return chats;
        })
        .distinct(_listEqualsById);
  }

  static bool _listEqualsById(List<ChatModel> a, List<ChatModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Stream<ChatModel?> watchChat(String chatId) {
    return _chats
        .doc(chatId)
        .snapshots()
        .map((s) => s.exists ? ChatModel.fromSnapshot(s) : null);
  }

  @override
  Stream<int> watchTotalUnread(String userId) {
    return watchChatsForUser(userId).map(
      (chats) => chats.fold<int>(0, (total, c) => total + c.unreadFor(userId)),
    );
  }

  // ── Message reads ───────────────────────────────────────────────────────

  @override
  Stream<List<MessageModel>> watchLatestMessages(String chatId, int limit) {
    return _messages(chatId)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map((s) {
          final list = s.docs.map(MessageModel.fromSnapshot).toList()
            ..sort(_byCreatedAtThenId);
          return list;
        });
  }

  @override
  Future<MessagePage> fetchMessagesBefore({
    required String chatId,
    required MessageCursor cursor,
    required int limit,
  }) async {
    final snapshot = await _messages(chatId)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .startAfter([Timestamp.fromDate(cursor.createdAt), cursor.id])
        .limit(limit + 1)
        .get();

    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final page = hasMore ? docs.sublist(0, limit) : docs;

    final ascending = page.map(MessageModel.fromSnapshot).toList()
      ..sort(_byCreatedAtThenId);

    if (ascending.isEmpty) {
      return MessagePage(messages: const [], hasMore: false, cursor: cursor);
    }

    final oldest = ascending.first;
    return MessagePage(
      messages: ascending,
      hasMore: hasMore,
      cursor: MessageCursor(createdAt: oldest.createdAt, id: oldest.id),
    );
  }

  static int _byCreatedAtThenId(MessageModel a, MessageModel b) {
    final byDate = a.createdAt.compareTo(b.createdAt);
    if (byDate != 0) return byDate;
    return a.id.compareTo(b.id);
  }

  // ── Message writes ──────────────────────────────────────────────────────

  @override
  Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    final chatRef = _chats.doc(chatId);
    final chatSnap = await chatRef.get();
    if (!chatSnap.exists) {
      throw ChatSendException(
        chatId: chatId,
        senderId: senderId,
        text: text,
        imageUrl: imageUrl,
        cause: 'Conversation not found',
      );
    }

    final chat = ChatModel.fromSnapshot(chatSnap);
    // Which counter to bump is decided by the stored participant ids, not by
    // the sender's role — agents occupy the ownerId slot.
    final otherUnreadField = chat.otherUnreadFieldFor(senderId);
    if (otherUnreadField == null) {
      throw ChatNotParticipantException(chatId, senderId);
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl == null) {
      throw ChatSendException(
        chatId: chatId,
        senderId: senderId,
        text: text,
        imageUrl: imageUrl,
        cause: 'Message is empty',
      );
    }
    if (trimmed.length > 1000) {
      throw ChatSendException(
        chatId: chatId,
        senderId: senderId,
        text: trimmed,
        imageUrl: imageUrl,
        cause: 'Message is too long (max 1000 characters)',
      );
    }

    try {
      final batch = _db.batch();

      final msgRef = _messages(chatId).doc();
      // Server timestamp keeps the thread ordered consistently across devices
      // and is what the rules validate against request.time.
      final message = MessageModel(
        id: msgRef.id,
        senderId: senderId,
        text: trimmed,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      ).toMap()..['createdAt'] = FieldValue.serverTimestamp();
      batch.set(msgRef, message);

      batch.update(chatRef, {
        'lastMessage': imageUrl != null ? '📷 Photo' : trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        otherUnreadField: FieldValue.increment(1),
      });

      await batch.commit();
      return msgRef.id;
    } catch (e) {
      throw ChatSendException(
        chatId: chatId,
        senderId: senderId,
        text: trimmed,
        imageUrl: imageUrl,
        cause: e,
      );
    }
  }

  // ── Read state ──────────────────────────────────────────────────────────

  @override
  Future<void> markConversationRead({
    required String chatId,
    required String readerUid,
  }) async {
    final snap = await _chats.doc(chatId).get();
    if (!snap.exists) return;
    final chat = ChatModel.fromSnapshot(snap);
    final field = chat.unreadFieldFor(readerUid);
    if (field == null) return;
    if (chat.unreadFor(readerUid) == 0) return; // nothing to clear
    await _chats.doc(chatId).update({field: 0});
  }

  @override
  Future<int> markMessagesRead({
    required String chatId,
    required String readerUid,
    int maxBatch = 400,
    int maxTotal = 2000,
  }) async {
    var total = 0;
    while (total < maxTotal) {
      final snap = await _messages(
        chatId,
      ).where('isRead', isEqualTo: false).limit(maxBatch).get();

      if (snap.docs.isEmpty) break;

      final mine = snap.docs
          .where((d) => d.data()['senderId'] != readerUid)
          .toList();
      if (mine.isEmpty) break;

      final batch = _db.batch();
      for (final doc in mine) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      total += mine.length;

      // Fewer docs than the batch size means the unread backlog is drained.
      if (snap.docs.length < maxBatch) break;
    }
    return total;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Merge two document snapshot streams into one, keeping both alive for as
  /// long as at least one is still emitting.
  static Stream<
    (QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>)
  >
  _mergeStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>> a,
    Stream<QuerySnapshot<Map<String, dynamic>>> b,
  ) {
    late StreamController<
      (QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>)
    >
    controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subA;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subB;
    QuerySnapshot<Map<String, dynamic>>? lastA;
    QuerySnapshot<Map<String, dynamic>>? lastB;

    Future<void> emit() async {
      if (controller.isClosed) return;
      final currentA = lastA;
      final currentB = lastB;
      // Wait for both sides so the merged list never transiently drops a
      // conversation that only one side has loaded.
      if (currentA == null || currentB == null) return;
      controller.add((currentA, currentB));
    }

    controller = StreamController(
      onListen: () {
        subA = a.listen((v) {
          lastA = v;
          emit();
        }, onError: controller.addError);
        subB = b.listen((v) {
          lastB = v;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }
}

@riverpod
ChatRepository chatRepository(Ref ref) =>
    ChatRepository(ref.watch(firebaseFirestoreProvider));
