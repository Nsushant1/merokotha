import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-controlled banner ad shown on landing + customer home.
///
/// Firestore: `ads/{adId}` — public read, superAdmin write
/// (see firestore.rules). Composite index:
/// `placement ASC + status ASC + priority DESC`.
class AdModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;

  /// Where the banner may show: 'all' | 'landing' | 'home'.
  final String placement;

  /// 'active' | 'paused'.
  final String status;

  /// Higher shows first (orderBy priority DESC).
  final int priority;

  /// 'none' | 'listing' | 'external'.
  final String linkType;
  final String? listingId;
  final String? externalUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AdModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.placement = 'all',
    this.status = 'active',
    this.priority = 0,
    this.linkType = 'none',
    this.listingId,
    this.externalUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory AdModel.fromMap(Map<String, dynamic> map, String id) {
    return AdModel(
      id: id,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      placement: map['placement'] as String? ?? 'all',
      status: map['status'] as String? ?? 'active',
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      linkType: map['linkType'] as String? ?? 'none',
      listingId: map['listingId'] as String?,
      externalUrl: map['externalUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AdModel.fromSnapshot(DocumentSnapshot doc) =>
      AdModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'placement': placement,
    'status': status,
    'priority': priority,
    'linkType': linkType,
    'listingId': listingId,
    'externalUrl': externalUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
