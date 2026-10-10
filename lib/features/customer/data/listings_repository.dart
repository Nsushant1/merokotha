import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'listings_repository.g.dart';

class ListingsRepository {
  final FirebaseFirestore _db;
  ListingsRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('listings');

  Stream<List<ListingModel>> watchActiveListings() {
    return _col
        .where('status', isEqualTo: ListingStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ListingModel.fromSnapshot(d)).toList());
  }

  Future<ListingModel?> getListingById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromSnapshot(doc);
  }

  Future<List<ListingModel>> searchListings(SearchFilter filter) async {
    Query<Map<String, dynamic>> q = _col.where(
      'status',
      isEqualTo: ListingStatus.active.name,
    );

    if (filter.categoryL1Id != null) {
      q = q.where('roomType', isEqualTo: filter.categoryL1Id);
    }

    if (filter.furnishing != null) {
      q = q.where('furnishing', isEqualTo: filter.furnishing!.name);
    }
    if (filter.minRent != null) {
      q = q.where('rentPerMonth', isGreaterThanOrEqualTo: filter.minRent);
    }
    if (filter.maxRent != null) {
      q = q.where('rentPerMonth', isLessThanOrEqualTo: filter.maxRent);
    }
    // Move orderBy after the range filters
    q = q.orderBy('rentPerMonth');

    final snap = await q.get();
    var results = snap.docs.map((d) => ListingModel.fromSnapshot(d)).toList();

    if (filter.query != null && filter.query!.isNotEmpty) {
      final kw = filter.query!.toLowerCase();
      results = results
          .where(
            (l) =>
                l.title.toLowerCase().contains(kw) ||
                (l.address?.toLowerCase().contains(kw) ?? false) ||
                (l.nearbyLandmarks?.toLowerCase().contains(kw) ?? false),
          )
          .toList();
    }

    if (filter.facilities.isNotEmpty) {
      results = results
          .where(
            (l) => filter.facilities.every((f) => l.facilities.contains(f)),
          )
          .toList();
    }

    return results;
  }

  Future<List<ListingModel>> getAllActiveForMap() async {
    final snap = await _col
        .where('status', isEqualTo: ListingStatus.active.name)
        .get();
    return snap.docs.map((d) => ListingModel.fromSnapshot(d)).toList();
  }

  /// Best-effort view counter: display-only, so a failure (offline,
  /// legacy document, rules rejection) must never surface to the UI.
  Future<void> incrementView(String id) async {
    try {
      await _col.doc(id).update({'viewCount': FieldValue.increment(1)});
    } catch (_) {
      // Ignore — the counter is non-critical.
    }
  }

  Future<List<ListingModel>> getSimilarListings(
    String excludeId, {
    int limit = 4,
  }) async {
    final snap = await _col
        .where('status', isEqualTo: ListingStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(limit + 1)
        .get();
    return snap.docs
        .map((d) => ListingModel.fromSnapshot(d))
        .where((l) => l.id != excludeId)
        .take(limit)
        .toList();
  }
}

class SearchFilter {
  final String? query;
  final String? categoryL1Id;
  final FurnishingType? furnishing;
  final double? minRent;
  final double? maxRent;
  final List<String> facilities;

  const SearchFilter({
    this.query,
    this.categoryL1Id,
    this.furnishing,
    this.minRent,
    this.maxRent,
    this.facilities = const [],
  });

  SearchFilter copyWith({
    String? query,
    String? categoryL1Id,
    FurnishingType? furnishing,
    double? minRent,
    double? maxRent,
    List<String>? facilities,
    bool clearQuery = false,
    bool clearCategory = false,
    bool clearFurnishing = false,
    bool clearMinRent = false,
    bool clearMaxRent = false,
  }) => SearchFilter(
    query: clearQuery ? null : (query ?? this.query),
    categoryL1Id: clearCategory ? null : (categoryL1Id ?? this.categoryL1Id),
    furnishing: clearFurnishing ? null : (furnishing ?? this.furnishing),
    minRent: clearMinRent ? null : (minRent ?? this.minRent),
    maxRent: clearMaxRent ? null : (maxRent ?? this.maxRent),
    facilities: facilities ?? this.facilities,
  );

  bool get hasActiveFilters =>
      categoryL1Id != null ||
      furnishing != null ||
      minRent != null ||
      maxRent != null ||
      facilities.isNotEmpty;

  SearchFilter get cleared => const SearchFilter();
}

@riverpod
ListingsRepository listingsRepository(Ref ref) =>
    ListingsRepository(ref.watch(firebaseFirestoreProvider));
