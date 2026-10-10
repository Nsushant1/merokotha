import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'agent_repository.g.dart';

/// Real-owner contact for an agent-posted listing.
///
/// Stored in `listings/{listingId}/ownerContact/info`, readable only by the
/// posting agent and superAdmin — never in the publicly readable listing
/// document. ([ListingModel.ownerPhone] is legacy: pre-migration listings
/// may still carry it top-level; new clients ignore it.)
class OwnerContact {
  final String name;
  final String phone;

  const OwnerContact({required this.name, required this.phone});

  factory OwnerContact.fromMap(Map<String, dynamic> map) => OwnerContact(
    name: map['name'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'name': name, 'phone': phone};
}

/// Firestore access for agent-posted listings.
///
/// Agent listings store the agent's uid in both [ListingModel.ownerId] and
/// [ListingModel.agentId] (so existing `ownerId == uid` rules/queries keep
/// working). The manually entered real-owner contact lives in the
/// restricted `ownerContact` subcollection (see [OwnerContact]).
class AgentRepository {
  final FirebaseFirestore _db;
  AgentRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('listings');

  DocumentReference<Map<String, dynamic>> _contactDoc(String listingId) =>
      _listings.doc(listingId).collection('ownerContact').doc('info');

  /// All listings posted by the given agent, newest first.
  Stream<List<ListingModel>> watchAgentListings(String agentId) {
    return _listings
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ListingModel.fromSnapshot(d)).toList(),
        );
  }

  Future<String> createAgentListing(ListingModel listing) async {
    final ref = await _listings.add(listing.toMap());
    return ref.id;
  }

  Future<void> updateAgentListing(String id, Map<String, dynamic> data) async {
    await _listings.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAgentListing(String id) async {
    await _listings.doc(id).delete();
  }

  Future<void> toggleAgentListingStatus(String id, ListingStatus status) async {
    await _listings.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Persist the real-owner contact for an agent-posted listing.
  Future<void> saveOwnerContact({
    required String listingId,
    required String name,
    required String phone,
  }) async {
    await _contactDoc(listingId).set(
      OwnerContact(name: name, phone: phone).toMap(),
      SetOptions(merge: true),
    );
  }

  /// Read the real-owner contact, or null when absent (e.g. legacy listing
  /// created before the contact subcollection existed).
  Future<OwnerContact?> getOwnerContact(String listingId) async {
    final doc = await _contactDoc(listingId).get();
    if (!doc.exists) return null;
    return OwnerContact.fromMap(doc.data()!);
  }
}

@riverpod
AgentRepository agentRepository(Ref ref) {
  return AgentRepository(ref.watch(firebaseFirestoreProvider));
}
