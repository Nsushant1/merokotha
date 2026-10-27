import 'package:cloud_firestore/cloud_firestore.dart';

/// Sort options for advanced search. Values are persisted in saved searches.
enum ListingSort { newest, priceAsc, priceDesc, mostViewed, nearest }

/// A saved filter combination, stored at
/// `users/{uid}/savedSearches/{searchId}`.
///
/// Field names mirror the website schema — confirm against the web app
/// before going live.
class SavedSearchModel {
  final String id;
  final String name;
  final String? query;
  final String? roomType;
  final String? furnishing;
  final double? minRent;
  final double? maxRent;
  final List<String> facilities;
  final bool verifiedOnly;
  final ListingSort sort;
  final double? lat;
  final double? lng;
  final double? radiusKm;

  /// Last time the user viewed this search's results. Listings created
  /// after this are counted as "new".
  final DateTime? lastCheckedAt;
  final DateTime createdAt;

  const SavedSearchModel({
    required this.id,
    required this.name,
    this.query,
    this.roomType,
    this.furnishing,
    this.minRent,
    this.maxRent,
    this.facilities = const [],
    this.verifiedOnly = false,
    this.sort = ListingSort.newest,
    this.lat,
    this.lng,
    this.radiusKm,
    this.lastCheckedAt,
    required this.createdAt,
  });

  factory SavedSearchModel.fromMap(Map<String, dynamic> map, String id) {
    return SavedSearchModel(
      id: id,
      name: map['name'] as String? ?? 'Saved search',
      query: map['query'] as String?,
      roomType: map['roomType'] as String?,
      furnishing: map['furnishing'] as String?,
      minRent: (map['minRent'] as num?)?.toDouble(),
      maxRent: (map['maxRent'] as num?)?.toDouble(),
      facilities: List<String>.from(map['facilities'] ?? const []),
      verifiedOnly: map['verifiedOnly'] as bool? ?? false,
      sort: ListingSort.values.firstWhere(
        (e) => e.name == map['sort'],
        orElse: () => ListingSort.newest,
      ),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      radiusKm: (map['radiusKm'] as num?)?.toDouble(),
      lastCheckedAt: (map['lastCheckedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory SavedSearchModel.fromSnapshot(DocumentSnapshot doc) =>
      SavedSearchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'name': name,
    'query': query,
    'roomType': roomType,
    'furnishing': furnishing,
    'minRent': minRent,
    'maxRent': maxRent,
    'facilities': facilities,
    'verifiedOnly': verifiedOnly,
    'sort': sort.name,
    'lat': lat,
    'lng': lng,
    'radiusKm': radiusKm,
    'lastCheckedAt': lastCheckedAt != null
        ? Timestamp.fromDate(lastCheckedAt!)
        : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// Short human-readable summary of the filter combination.
  String get summary {
    final parts = <String>[];
    if (roomType != null) parts.add(roomType!);
    if (furnishing != null) parts.add(furnishing!);
    if (minRent != null || maxRent != null) {
      parts.add(
        '${minRent != null ? minRent!.toStringAsFixed(0) : '0'}–'
        '${maxRent != null ? maxRent!.toStringAsFixed(0) : 'any'}',
      );
    }
    if (facilities.isNotEmpty) parts.add('${facilities.length} facilities');
    if (verifiedOnly) parts.add('Verified only');
    if (radiusKm != null) parts.add('within ${radiusKm!.toStringAsFixed(0)} km');
    if (parts.isEmpty) return query?.isNotEmpty == true ? query! : 'All rooms';
    return parts.join(' · ');
  }
}
