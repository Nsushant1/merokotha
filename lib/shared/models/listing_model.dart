import 'package:cloud_firestore/cloud_firestore.dart';

enum FurnishingType { furnished, semiFurnished, unfurnished }

enum ListingStatus { active, paused, rented, suspended }

/// Moderation state of a listing, independent of [ListingStatus].
///
/// New listings and every owner/agent edit start as `pending`. Only an admin
/// decision moves a listing to `verified` or `rejected` (with [reviewReason]).
/// Mirrors the website schema (`verificationStatus`, `reviewReason`,
/// `reviewedAt`, `reviewedBy`) — confirm exact field names against the web app
/// before going live.
enum VerificationStatus { pending, verified, rejected }

class ListingModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;

  /// UID of the agent who posted this listing on behalf of an owner.
  /// Null for regular owner-posted listings.
  /// When set, [ownerId] is the agent's uid and [ownerName]/[ownerPhone]
  /// hold the manually entered real-owner contact (masked publicly).
  final String? agentId;

  /// Manually entered real-owner phone for agent-posted listings.
  /// Null for regular owner-posted listings. Masked until inquiry accepted.
  final String? ownerPhone;
  final String title;
  final String roomType; // stored as string, maps to RoomType enum
  final double rentPerMonth;
  final double depositAmount;
  final int floor;
  final int totalFloors;
  final FurnishingType furnishing;
  final List<String> facilities;
  final String description;
  final List<String> photoUrls;
  final GeoPoint? geoPoint;
  final String? address;
  final String? nearbyLandmarks;
  final DateTime availableFrom;
  final ListingStatus status;

  /// Admin moderation state. Defaults to `pending` for legacy documents that
  /// predate verification.
  final VerificationStatus verificationStatus;

  /// Admin-provided reason when [verificationStatus] is `rejected`
  /// (also used for decision notes on suspension).
  final String? reviewReason;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  /// Optional separate public contact numbers. When absent, contact goes
  /// through in-app messaging only.
  final String? publicPhone;
  final String? whatsappNumber;

  /// When true, the lister's name is masked publicly ("Property Owner").
  final bool hideDisplayName;

  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ListingModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    this.agentId,
    this.ownerPhone,
    required this.title,
    required this.roomType,
    required this.rentPerMonth,
    required this.depositAmount,
    required this.floor,
    required this.totalFloors,
    required this.furnishing,
    required this.facilities,
    required this.description,
    required this.photoUrls,
    this.geoPoint,
    this.address,
    this.nearbyLandmarks,
    required this.availableFrom,
    required this.status,
    this.verificationStatus = VerificationStatus.pending,
    this.reviewReason,
    this.reviewedAt,
    this.reviewedBy,
    this.publicPhone,
    this.whatsappNumber,
    this.hideDisplayName = false,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map, String id) {
    return ListingModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      agentId: map['agentId'] as String?,
      ownerPhone: map['ownerPhone'] as String?,
      title: map['title'] as String? ?? '',
      roomType: map['roomType'] as String? ?? 'room',
      rentPerMonth: (map['rentPerMonth'] as num?)?.toDouble() ?? 0,
      depositAmount: (map['depositAmount'] as num?)?.toDouble() ?? 0,
      floor: map['floor'] as int? ?? 0,
      totalFloors: map['totalFloors'] as int? ?? 1,
      furnishing: FurnishingType.values.firstWhere(
        (e) => e.name == map['furnishing'],
        orElse: () => FurnishingType.unfurnished,
      ),
      facilities: List<String>.from(map['facilities'] ?? []),
      description: map['description'] as String? ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      geoPoint: map['geoPoint'] as GeoPoint?,
      address: map['address'] as String?,
      nearbyLandmarks: map['nearbyLandmarks'] as String?,
      availableFrom:
          (map['availableFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ListingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ListingStatus.active,
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == map['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      reviewReason: map['reviewReason'] as String?,
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'] as String?,
      publicPhone: map['publicPhone'] as String?,
      whatsappNumber: map['whatsappNumber'] as String?,
      hideDisplayName: map['hideDisplayName'] as bool? ?? false,
      viewCount: map['viewCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ListingModel.fromSnapshot(DocumentSnapshot doc) =>
      ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownerPhotoUrl': ownerPhotoUrl,
    'agentId': agentId,
    'ownerPhone': ownerPhone,
    'title': title,
    'roomType': roomType,
    'rentPerMonth': rentPerMonth,
    'depositAmount': depositAmount,
    'floor': floor,
    'totalFloors': totalFloors,
    'furnishing': furnishing.name,
    'facilities': facilities,
    'description': description,
    'photoUrls': photoUrls,
    'geoPoint': geoPoint,
    'address': address,
    'nearbyLandmarks': nearbyLandmarks,
    'availableFrom': Timestamp.fromDate(availableFrom),
    'status': status.name,
    'verificationStatus': verificationStatus.name,
    'reviewReason': reviewReason,
    'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    'reviewedBy': reviewedBy,
    'publicPhone': publicPhone,
    'whatsappNumber': whatsappNumber,
    'hideDisplayName': hideDisplayName,
    'viewCount': viewCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  ListingModel copyWith({
    String? ownerName,
    String? ownerPhotoUrl,
    String? agentId,
    String? ownerPhone,
    String? title,
    String? roomType,
    double? rentPerMonth,
    double? depositAmount,
    int? floor,
    int? totalFloors,
    FurnishingType? furnishing,
    List<String>? facilities,
    String? description,
    List<String>? photoUrls,
    GeoPoint? geoPoint,
    String? address,
    String? nearbyLandmarks,
    DateTime? availableFrom,
    ListingStatus? status,
    VerificationStatus? verificationStatus,
    String? reviewReason,
    String? publicPhone,
    String? whatsappNumber,
    bool? hideDisplayName,
    int? viewCount,
  }) => ListingModel(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName ?? this.ownerName,
    ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
    agentId: agentId ?? this.agentId,
    ownerPhone: ownerPhone ?? this.ownerPhone,
    title: title ?? this.title,
    roomType: roomType ?? this.roomType,
    rentPerMonth: rentPerMonth ?? this.rentPerMonth,
    depositAmount: depositAmount ?? this.depositAmount,
    floor: floor ?? this.floor,
    totalFloors: totalFloors ?? this.totalFloors,
    furnishing: furnishing ?? this.furnishing,
    facilities: facilities ?? this.facilities,
    description: description ?? this.description,
    photoUrls: photoUrls ?? this.photoUrls,
    geoPoint: geoPoint ?? this.geoPoint,
    address: address ?? this.address,
    nearbyLandmarks: nearbyLandmarks ?? this.nearbyLandmarks,
    availableFrom: availableFrom ?? this.availableFrom,
    status: status ?? this.status,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    reviewReason: reviewReason ?? this.reviewReason,
    publicPhone: publicPhone ?? this.publicPhone,
    whatsappNumber: whatsappNumber ?? this.whatsappNumber,
    hideDisplayName: hideDisplayName ?? this.hideDisplayName,
    viewCount: viewCount ?? this.viewCount,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  // ── Helpers ──
  bool get isActive => status == ListingStatus.active;
  bool get isSuspended => status == ListingStatus.suspended;
  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get isPendingReview =>
      verificationStatus == VerificationStatus.pending;
  bool get isRejected => verificationStatus == VerificationStatus.rejected;

  /// True when posted by an agent on behalf of an owner.
  bool get isAgentListed => agentId != null && agentId!.isNotEmpty;

  // Human readable room type label
  String get roomTypeLabel {
    switch (roomType) {
      case 'room':
        return 'Room';
      case 'flat':
        return 'Flat';
      case 'apartment':
        return 'Apartment';
      case 'house':
        return 'House';
      case 'office':
        return 'Office';
      case 'shop':
        return 'Shop';
      case 'land':
        return 'Land';
      default:
        return 'Other';
    }
  }

  String get furnishingLabel {
    switch (furnishing) {
      case FurnishingType.furnished:
        return 'Furnished';
      case FurnishingType.semiFurnished:
        return 'Semi-furnished';
      case FurnishingType.unfurnished:
        return 'Unfurnished';
    }
  }
}
