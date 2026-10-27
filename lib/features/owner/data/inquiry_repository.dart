import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:merokotha/features/notification/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';
import 'package:merokotha/features/chat/data/chat_repository.dart';

part 'inquiry_repository.g.dart';

class InquiryRepository {
  final FirebaseFirestore _db;
  final ChatRepository _chatRepository;

  InquiryRepository(this._db, this._chatRepository);

  CollectionReference<Map<String, dynamic>> get _inquiries =>
      _db.collection('inquiries');

  Stream<List<InquiryModel>> watchByStatus(
    String ownerId,
    InquiryStatus status,
  ) {
    return _inquiries
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => InquiryModel.fromSnapshot(d)).toList());
  }

  /// Single inquiry by id (used for the chat-thread context banner).
  /// Both participants may read it (see firestore.rules).
  Stream<InquiryModel?> watchInquiry(String inquiryId) {
    return _inquiries
        .doc(inquiryId)
        .snapshots()
        .map((s) => s.exists ? InquiryModel.fromSnapshot(s) : null);
  }

  Future<InquiryModel?> getInquiry(String inquiryId) async {
    final doc = await _inquiries.doc(inquiryId).get();
    if (!doc.exists) return null;
    return InquiryModel.fromSnapshot(doc);
  }

  /// Public name/photo projection for backfilling legacy inquiries that were
  /// created before `customerPhotoUrl`/`ownerName` were persisted.
  Future<Map<String, String?>> _publicProfile(String uid) async {
    try {
      final doc = await _db.collection('usersPublic').doc(uid).get();
      if (!doc.exists) return const {};
      final data = doc.data() ?? {};
      return {
        'name': data['name'] as String?,
        'photoUrl': data['photoUrl'] as String?,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<String> createInquiry(InquiryModel inquiry) async {
    final ref = await _inquiries.add(inquiry.toMap());
    return ref.id;
  }

  /// All inquiries received by one lister (any status) — used for the
  /// analytics dashboards (inquiry outcomes per listing).
  Stream<List<InquiryModel>> watchAllForOwner(String ownerId) {
    return _inquiries
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => InquiryModel.fromSnapshot(d)).toList());
  }

  Future<String> acceptInquiry({
    required String inquiryId,
    required InquiryModel inquiry,
    required String ownerName,
    String? ownerPhotoUrl,
  }) async {
    await _inquiries.doc(inquiryId).update({
      'status': InquiryStatus.accepted.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Backfill display names/photos for legacy inquiries created before
    // `customerPhotoUrl` was persisted, so the chat tile and thread header
    // show the sender's profile instead of a fallback initial.
    var customerName = inquiry.customerName;
    var customerPhotoUrl = inquiry.customerPhotoUrl;
    if (customerName.isEmpty || customerPhotoUrl == null) {
      final public = await _publicProfile(inquiry.customerId);
      if (customerName.isEmpty && (public['name']?.isNotEmpty ?? false)) {
        customerName = public['name']!;
      }
      customerPhotoUrl ??= public['photoUrl'];
    }

    // Auto-create a chat thread between owner and customer on acceptance.
    // The repository resolves the conversation id deterministically, so two
    // concurrent acceptances collapse into a single thread.
    try {
      final chatId = await _chatRepository.createChat(
        createdByUid: inquiry.ownerId,
        inquiryId: inquiryId,
        ownerId: inquiry.ownerId,
        ownerName: ownerName,
        ownerPhotoUrl: ownerPhotoUrl,
        customerId: inquiry.customerId,
        customerName: customerName,
        customerPhotoUrl: customerPhotoUrl,
        listingId: inquiry.listingId,
        listingTitle: inquiry.listingTitle,
      );

      await NotificationService().showInquiryAccepted(
        listingTitle: inquiry.listingTitle,
      );

      return chatId;
    } catch (_) {
      // The inquiry is already accepted above. Return the deterministic id
      // so the caller can still open the thread — the inquiry context banner
      // in the thread shows the original message, and the customer-side open
      // (or the `onInquiryAccepted` function) heals the chat document.
      final fallback = ChatRepository.deterministicChatId(
        ownerId: inquiry.ownerId,
        customerId: inquiry.customerId,
        listingId: inquiry.listingId,
      );
      await NotificationService().showInquiryAccepted(
        listingTitle: inquiry.listingTitle,
      );
      return fallback;
    }
  }

  /// Resolve the chat thread for an (already accepted) inquiry without
  /// touching its status or notifying — opening a thread must be free of
  /// side effects. Creation is idempotent via the deterministic chat id.
  Future<String> resolveChatId({
    required String inquiryId,
    required InquiryModel inquiry,
    required String ownerName,
    String? ownerPhotoUrl,
  }) async {
    var customerName = inquiry.customerName;
    var customerPhotoUrl = inquiry.customerPhotoUrl;
    if (customerName.isEmpty || customerPhotoUrl == null) {
      final public = await _publicProfile(inquiry.customerId);
      if (customerName.isEmpty && (public['name']?.isNotEmpty ?? false)) {
        customerName = public['name']!;
      }
      customerPhotoUrl ??= public['photoUrl'];
    }
    return _chatRepository.createChat(
      createdByUid: inquiry.ownerId,
      inquiryId: inquiryId,
      ownerId: inquiry.ownerId,
      ownerName: ownerName,
      ownerPhotoUrl: ownerPhotoUrl,
      customerId: inquiry.customerId,
      customerName: customerName,
      customerPhotoUrl: customerPhotoUrl,
      listingId: inquiry.listingId,
      listingTitle: inquiry.listingTitle,
    );
  }

  Future<void> declineInquiry(String id, {String? reason}) async {
    await _inquiries.doc(id).update({
      'status': InquiryStatus.declined.name,
      'declineReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> watchPendingCount(String ownerId) {
    return _inquiries
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: InquiryStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.length);
  }
}

@riverpod
InquiryRepository inquiryRepository(Ref ref) {
  return InquiryRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(chatRepositoryProvider),
  );
}
