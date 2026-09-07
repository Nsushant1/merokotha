import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:merokotha/features/notification/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';
import 'package:merokotha/features/chat/data/chat_repository.dart';

part 'inquiry_repository.g.dart';

class InquiryRepository {
  final FirebaseFirestore _db;

  InquiryRepository(this._db);

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

  Stream<List<InquiryModel>> watchCustomerInquiries(String customerId) {
    return _inquiries
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => InquiryModel.fromSnapshot(d)).toList());
  }

  Future<String> createInquiry(InquiryModel inquiry) async {
    final ref = await _inquiries.add(inquiry.toMap());
    return ref.id;
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

    // Auto-create a chat thread between owner and customer on acceptance
    final chatRepo = ChatRepository(_db);
    final chatId = await chatRepo.createChat(
      ownerId: inquiry.ownerId,
      ownerName: ownerName,
      ownerPhotoUrl: ownerPhotoUrl,
      customerId: inquiry.customerId,
      customerName: inquiry.customerName,
      customerPhotoUrl: inquiry.customerPhotoUrl,
      listingId: inquiry.listingId,
      listingTitle: inquiry.listingTitle,
    );

    await NotificationService().showInquiryAccepted(
      listingTitle: inquiry.listingTitle,
    );

    return chatId;
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
  return InquiryRepository(ref.watch(firebaseFirestoreProvider));
}
