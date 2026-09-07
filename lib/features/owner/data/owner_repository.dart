import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'owner_repository.g.dart';

class OwnerRepository {
  final FirebaseFirestore _db;

  OwnerRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('listings');

  Stream<List<ListingModel>> watchMyListings(String ownerId) {
    return _listings
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ListingModel.fromSnapshot(d)).toList(),
        );
  }

  Future<String> createListing(ListingModel listing) async {
    final ref = await _listings.add(listing.toMap());
    return ref.id;
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _listings.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }

  Future<void> toggleListingStatus(String id, ListingStatus status) async {
    await _listings.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

@riverpod
OwnerRepository ownerRepository(Ref ref) {
  return OwnerRepository(ref.watch(firebaseFirestoreProvider));
}
