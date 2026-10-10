import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'customer_inquiry_repository.g.dart';

class CustomerInquiryRepository {
  final FirebaseFirestore _db;
  CustomerInquiryRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('inquiries');

  // Watch all inquiries sent by this customer
  Stream<List<InquiryModel>> watchMyInquiries(String customerId) {
    return _col
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => InquiryModel.fromSnapshot(d)).toList());
  }

  // Check if customer already sent inquiry for a listing
  Future<bool> hasInquired(String customerId, String listingId) async {
    final snap = await _col
        .where('customerId', isEqualTo: customerId)
        .where('listingId', isEqualTo: listingId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Get inquiry for a specific listing (to show status)
  Future<InquiryModel?> getInquiryForListing(
    String customerId,
    String listingId,
  ) async {
    final snap = await _col
        .where('customerId', isEqualTo: customerId)
        .where('listingId', isEqualTo: listingId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return InquiryModel.fromSnapshot(snap.docs.first);
  }
}

@riverpod
CustomerInquiryRepository customerInquiryRepository(Ref ref) {
  return CustomerInquiryRepository(ref.watch(firebaseFirestoreProvider));
}
