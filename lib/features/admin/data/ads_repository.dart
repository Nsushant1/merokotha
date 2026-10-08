import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/ad_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'ads_repository.g.dart';

class AdsRepository {
  final FirebaseFirestore _db;
  AdsRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _ads => _db.collection('ads');

  /// Public feed for one placement slot.
  /// Single-field query (no composite index needed); placement + priority
  /// are filtered/sorted client-side. Existing composite index on
  /// placement+status+priority remains valid for console queries.
  Stream<List<AdModel>> watchActiveAds(String slot) {
    return _ads.where('status', isEqualTo: 'active').snapshots().map((s) {
      final list =
          s.docs
              .map((d) => AdModel.fromSnapshot(d))
              .where((a) => a.placement == 'all' || a.placement == slot)
              .toList()
            ..sort((a, b) => b.priority.compareTo(a.priority));
      return list;
    });
  }

  Stream<List<AdModel>> watchAllAds() {
    return _ads.snapshots().map((s) {
      final list = s.docs.map((d) => AdModel.fromSnapshot(d)).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
      return list;
    });
  }

  Future<String> createAd(Map<String, dynamic> data) async {
    final doc = await _ads.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateAd(String id, Map<String, dynamic> data) async {
    await _ads.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAdStatus(String id, String status) async {
    await _ads.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAd(String id) async {
    await _ads.doc(id).delete();
  }
}

@riverpod
AdsRepository adsRepository(Ref ref) =>
    AdsRepository(ref.watch(firebaseFirestoreProvider));
