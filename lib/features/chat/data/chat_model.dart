import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Which side of a 1:1 conversation a user sits on.
///
/// Chats store the lister in [ChatModel.ownerId] and the enquirer in
/// [ChatModel.customerId]. Agents act on the lister side, so the side must be
/// derived from the stored ids rather than from the caller's *role* — an agent
/// is an `ownerId` holder but is not `UserRole.owner`. Deriving from role was
/// the root cause of agents incrementing `unreadCustomer` on send and never
/// clearing `unreadOwner` on open.
enum ChatSide { owner, customer, unknown }

class ChatModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String customerId;
  final String customerName;
  final String? customerPhotoUrl;
  final String listingId;
  final String listingTitle;

  /// Source inquiry. Present on every chat created after the rules hardening;
  /// `null` on legacy chats created before it existed. Firestore rules require
  /// it on create, so it is used to authorise chat creation.
  final String? inquiryId;

  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadOwner; // unread count for owner
  final int unreadCustomer; // unread count for customer
  final DateTime createdAt;

  const ChatModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.customerId,
    required this.customerName,
    this.customerPhotoUrl,
    required this.listingId,
    required this.listingTitle,
    this.inquiryId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadOwner = 0,
    this.unreadCustomer = 0,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhotoUrl: map['customerPhotoUrl'] as String?,
      listingId: map['listingId'] as String? ?? '',
      listingTitle: map['listingTitle'] as String? ?? '',
      inquiryId: map['inquiryId'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      unreadOwner: map['unreadOwner'] as int? ?? 0,
      unreadCustomer: map['unreadCustomer'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ChatModel.fromSnapshot(DocumentSnapshot doc) =>
      ChatModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownerPhotoUrl': ownerPhotoUrl,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhotoUrl': customerPhotoUrl,
    'listingId': listingId,
    'listingTitle': listingTitle,
    'inquiryId': inquiryId,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null
        ? Timestamp.fromDate(lastMessageAt!)
        : null,
    'lastMessageSenderId': lastMessageSenderId,
    'unreadOwner': unreadOwner,
    'unreadCustomer': unreadCustomer,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  // ── Participant lookups (identity based, never role based) ──────────────

  /// The side [myUid] sits on, or [ChatSide.unknown] if they are not a
  /// participant of this conversation.
  ChatSide sideFor(String myUid) {
    if (myUid.isEmpty) return ChatSide.unknown;
    if (myUid == ownerId) return ChatSide.owner;
    if (myUid == customerId) return ChatSide.customer;
    return ChatSide.unknown;
  }

  bool isParticipant(String myUid) => sideFor(myUid) != ChatSide.unknown;

  /// Get other person's name (given my uid)
  String otherName(String myUid) => myUid == ownerId ? customerName : ownerName;

  String? otherPhoto(String myUid) =>
      myUid == ownerId ? customerPhotoUrl : ownerPhotoUrl;

  int unreadFor(String myUid) =>
      myUid == ownerId ? unreadOwner : unreadCustomer;

  /// Which unread field belongs to [myUid] — `null` when not a participant.
  String? unreadFieldFor(String myUid) => switch (sideFor(myUid)) {
    ChatSide.owner => 'unreadOwner',
    ChatSide.customer => 'unreadCustomer',
    ChatSide.unknown => null,
  };

  /// The counter that must be incremented when [senderUid] sends a message —
  /// i.e. the *other* party's counter. `null` when the sender is not a
  /// participant.
  String? otherUnreadFieldFor(String senderUid) => switch (sideFor(senderUid)) {
    ChatSide.owner => 'unreadCustomer',
    ChatSide.customer => 'unreadOwner',
    ChatSide.unknown => null,
  };

  /// Timestamp used to sort the conversation list by latest activity.
  /// Falls back to [createdAt] so legacy chats (which have no `lastMessageAt`)
  /// still sort deterministically instead of disappearing from the list.
  DateTime get activityAt => lastMessageAt ?? createdAt;

  ChatModel copyWith({
    String? inquiryId,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    int? unreadOwner,
    int? unreadCustomer,
  }) {
    return ChatModel(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerPhotoUrl: ownerPhotoUrl,
      customerId: customerId,
      customerName: customerName,
      customerPhotoUrl: customerPhotoUrl,
      listingId: listingId,
      listingTitle: listingTitle,
      inquiryId: inquiryId ?? this.inquiryId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadOwner: unreadOwner ?? this.unreadOwner,
      unreadCustomer: unreadCustomer ?? this.unreadCustomer,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatModel &&
          other.id == id &&
          other.ownerId == ownerId &&
          other.customerId == customerId &&
          other.listingId == listingId &&
          other.inquiryId == inquiryId &&
          other.lastMessage == lastMessage &&
          other.lastMessageAt == lastMessageAt &&
          other.lastMessageSenderId == lastMessageSenderId &&
          other.unreadOwner == unreadOwner &&
          other.unreadCustomer == unreadCustomer;

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    customerId,
    listingId,
    inquiryId,
    lastMessage,
    lastMessageAt,
    lastMessageSenderId,
    unreadOwner,
    unreadCustomer,
  );

  @override
  String toString() =>
      'ChatModel(id: $id, owner: $ownerId, customer: $customerId, '
      'listing: $listingId)';
}

@immutable
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  /// Set while a message is still being written to Firestore, so the UI can
  /// render it optimistically. Never persisted.
  final bool isPending;

  /// Set when the send failed, so the UI can offer a retry.
  final String? failureReason;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
    this.isPending = false,
    this.failureReason,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory MessageModel.fromSnapshot(DocumentSnapshot doc) =>
      MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'imageUrl': imageUrl,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// A send is only successful once the server round-trip has completed.
  bool get isFailed => failureReason != null;

  MessageModel copyWith({
    bool? isRead,
    bool? isPending,
    String? failureReason,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      isPending: isPending ?? this.isPending,
      failureReason: failureReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          other.id == id &&
          other.senderId == senderId &&
          other.text == text &&
          other.imageUrl == imageUrl &&
          other.isRead == isRead &&
          other.createdAt == createdAt &&
          other.isPending == isPending &&
          other.failureReason == failureReason;

  @override
  int get hashCode => Object.hash(
    id,
    senderId,
    text,
    imageUrl,
    isRead,
    createdAt,
    isPending,
    failureReason,
  );

  @override
  String toString() =>
      'MessageModel(id: $id, from: $senderId, read: $isRead, '
      'pending: $isPending, failed: $isFailed)';
}
