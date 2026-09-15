import 'package:cloud_firestore/cloud_firestore.dart';

// --------------- Inquiry Model ---------------

enum InquiryStatus { pending, accepted, declined }

class InquiryModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String customerId;
  final String customerName;
  final String? customerPhotoUrl;
  final String ownerId;
  final String? ownerName;

  /// UID of the agent handling this inquiry (for agent-posted listings).
  /// Mirrors the listing's [agentId]; null for owner-posted listings.
  final String? agentId;
  final String message;
  final DateTime moveInDate;
  final InquiryStatus status;
  final String? declineReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InquiryModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.customerId,
    required this.customerName,
    this.customerPhotoUrl,
    required this.ownerId,
    this.ownerName,
    this.agentId,
    required this.message,
    required this.moveInDate,
    required this.status,
    this.declineReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InquiryModel.fromMap(Map<String, dynamic> map, String id) {
    return InquiryModel(
      id: id,
      listingId: map['listingId'] as String? ?? '',
      listingTitle: map['listingTitle'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhotoUrl: map['customerPhotoUrl'] as String?,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String?,
      agentId: map['agentId'] as String?,
      message: map['message'] as String? ?? '',
      moveInDate: (map['moveInDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: InquiryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InquiryStatus.pending,
      ),
      declineReason: map['declineReason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory InquiryModel.fromSnapshot(DocumentSnapshot doc) {
    return InquiryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhotoUrl': customerPhotoUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'agentId': agentId,
      'message': message,
      'moveInDate': Timestamp.fromDate(moveInDate),
      'status': status.name,
      'declineReason': declineReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isPending => status == InquiryStatus.pending;
  bool get isAccepted => status == InquiryStatus.accepted;
  bool get isDeclined => status == InquiryStatus.declined;

  /// True when this inquiry is handled by an agent.
  bool get isAgentHandled => agentId != null && agentId!.isNotEmpty;

  InquiryModel copyWith({
    String? listingId,
    String? listingTitle,
    String? customerId,
    String? customerName,
    String? customerPhotoUrl,
    String? ownerId,
    String? ownerName,
    String? agentId,
    String? message,
    DateTime? moveInDate,
    InquiryStatus? status,
    String? declineReason,
  }) {
    return InquiryModel(
      id: id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      agentId: agentId ?? this.agentId,
      message: message ?? this.message,
      moveInDate: moveInDate ?? this.moveInDate,
      status: status ?? this.status,
      declineReason: declineReason ?? this.declineReason,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

