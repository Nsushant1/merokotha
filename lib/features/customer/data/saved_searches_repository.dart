import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/models/saved_search_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

class SavedSearchesRepository {
  final FirebaseFirestore _db;
  SavedSearchesRepository(this._db);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('savedSearches');

  Stream<List<SavedSearchModel>> watchSavedSearches(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SavedSearchModel.fromSnapshot).toList());
  }

  Future<String> saveSearch(String uid, SavedSearchModel search) async {
    final ref = await _col(uid).add(search.toMap());
    return ref.id;
  }

  Future<void> deleteSearch(String uid, String searchId) async {
    await _col(uid).doc(searchId).delete();
  }

  Future<void> markSeen(String uid, String searchId) async {
    await _col(uid).doc(searchId).update({
      'lastCheckedAt': FieldValue.serverTimestamp(),
    });
  }
}

final savedSearchesRepositoryProvider = Provider<SavedSearchesRepository>(
  (ref) => SavedSearchesRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Saved searches of the signed-in user.
final mySavedSearchesProvider = StreamProvider<List<SavedSearchModel>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value(const <SavedSearchModel>[]);
  return ref.watch(savedSearchesRepositoryProvider).watchSavedSearches(user.uid);
});
