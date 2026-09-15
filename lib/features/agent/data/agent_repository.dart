import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'agent_repository.g.dart';

/// Firestore access for agent-posted listings.
///
/// Agent listings store the agent's uid in both [ListingModel.ownerId] and
/// [ListingModel.agentId] (so existing `ownerId == uid` rules/queries keep
/// working), plus the manually entered real-owner contact in
/// [ListingModel.ownerName]/[ListingModel.ownerPhone] (masked publicly).
class AgentRepository {
  final FirebaseFirestore _db;

  AgentRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('listings');

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
}

@riverpod
AgentRepository agentRepository(Ref ref) {
  return AgentRepository(ref.watch(firebaseFirestoreProvider));
}
