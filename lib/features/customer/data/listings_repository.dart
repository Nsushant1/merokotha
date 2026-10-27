import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/models/saved_search_model.dart' show ListingSort;
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'listings_repository.g.dart';

/// Haversine distance in km between two points.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earth = Distance();
  return earth.as(
    LengthUnit.Kilometer,
    LatLng(lat1, lng1),
    LatLng(lat2, lng2),
  );
}

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

    if (filter.verifiedOnly) {
      results = results.where((l) => l.isVerified).toList();
    }

    if (filter.lat != null && filter.lng != null && filter.radiusKm != null) {
      results = results.where((l) {
        final g = l.geoPoint;
        if (g == null) return false;
        return distanceKm(filter.lat!, filter.lng!, g.latitude, g.longitude) <=
            filter.radiusKm!;
      }).toList();
    }

    switch (filter.sort) {
      case ListingSort.priceAsc:
        results.sort((a, b) => a.rentPerMonth.compareTo(b.rentPerMonth));
        break;
      case ListingSort.priceDesc:
        results.sort((a, b) => b.rentPerMonth.compareTo(a.rentPerMonth));
        break;
      case ListingSort.mostViewed:
        results.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case ListingSort.nearest:
        if (filter.lat != null && filter.lng != null) {
          results.sort((a, b) {
            double d(ListingModel l) => l.geoPoint == null
                ? double.infinity
                : distanceKm(
                    filter.lat!,
                    filter.lng!,
                    l.geoPoint!.latitude,
                    l.geoPoint!.longitude,
                  );
            return d(a).compareTo(d(b));
          });
        }
        break;
      case ListingSort.newest:
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
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
  final bool verifiedOnly;
  final ListingSort sort;
  final double? lat;
  final double? lng;
  final double? radiusKm;

  const SearchFilter({
    this.query,
    this.categoryL1Id,
    this.furnishing,
    this.minRent,
    this.maxRent,
    this.facilities = const [],
    this.verifiedOnly = false,
    this.sort = ListingSort.newest,
    this.lat,
    this.lng,
    this.radiusKm,
  });

  SearchFilter copyWith({
    String? query,
    String? categoryL1Id,
    FurnishingType? furnishing,
    double? minRent,
    double? maxRent,
    List<String>? facilities,
    bool? verifiedOnly,
    ListingSort? sort,
    double? lat,
    double? lng,
    double? radiusKm,
    bool clearQuery = false,
    bool clearCategory = false,
    bool clearFurnishing = false,
    bool clearMinRent = false,
    bool clearMaxRent = false,
    bool clearLocation = false,
  }) => SearchFilter(
    query: clearQuery ? null : (query ?? this.query),
    categoryL1Id: clearCategory ? null : (categoryL1Id ?? this.categoryL1Id),
    furnishing: clearFurnishing ? null : (furnishing ?? this.furnishing),
    minRent: clearMinRent ? null : (minRent ?? this.minRent),
    maxRent: clearMaxRent ? null : (maxRent ?? this.maxRent),
    facilities: facilities ?? this.facilities,
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    sort: sort ?? this.sort,
    lat: clearLocation ? null : (lat ?? this.lat),
    lng: clearLocation ? null : (lng ?? this.lng),
    radiusKm: clearLocation ? null : (radiusKm ?? this.radiusKm),
  );

  bool get hasActiveFilters =>
      categoryL1Id != null ||
      furnishing != null ||
      minRent != null ||
      maxRent != null ||
      facilities.isNotEmpty ||
      verifiedOnly ||
      radiusKm != null;

  SearchFilter get cleared => const SearchFilter();
}

@riverpod
ListingsRepository listingsRepository(Ref ref) =>
    ListingsRepository(ref.watch(firebaseFirestoreProvider));
