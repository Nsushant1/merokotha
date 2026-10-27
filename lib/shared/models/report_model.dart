import 'package:cloud_firestore/cloud_firestore.dart';

/// Moderation state of a user-submitted listing report.
enum ReportStatus { pending, resolved, dismissed }

/// Report categories shown in the report dialog.
const reportCategories = [
  'Spam or scam',
  'Wrong information',
  'Inappropriate photos',
  'Already rented / unavailable',
  'Prohibited content',
  'Other',
];

/// A user report against a listing, stored at `reports/{reportId}`.
///
/// Field names mirror the website schema — confirm against the web app
/// before going live (`category`, `details`, `status`, `decisionNote`,
/// `decidedBy`, `decidedAt`).
class ReportModel {
  final String id;
  final String reporterId;
  final String? reporterName;
  final String listingId;
  final String? listingTitle;
  final String? ownerId;
  final String category;
  final String details;
  final ReportStatus status;
  final String? decisionNote;
  final String? decidedBy;
  final DateTime? decidedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    this.reporterName,
    required this.listingId,
    this.listingTitle,
    this.ownerId,
    required this.category,
    this.details = '',
    this.status = ReportStatus.pending,
    this.decisionNote,
    this.decidedBy,
    this.decidedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String?,
      listingId: map['listingId'] as String? ?? '',
      listingTitle: map['listingTitle'] as String?,
      ownerId: map['ownerId'] as String?,
      category: map['category'] as String? ?? 'Other',
      details: map['details'] as String? ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      decisionNote: map['decisionNote'] as String?,
      decidedBy: map['decidedBy'] as String?,
      decidedAt: (map['decidedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ReportModel.fromSnapshot(DocumentSnapshot doc) =>
      ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'reporterId': reporterId,
    'reporterName': reporterName,
    'listingId': listingId,
    'listingTitle': listingTitle,
    'ownerId': ownerId,
    'category': category,
    'details': details,
    'status': status.name,
    'decisionNote': decisionNote,
    'decidedBy': decidedBy,
    'decidedAt': decidedAt != null ? Timestamp.fromDate(decidedAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  bool get isPending => status == ReportStatus.pending;
}

/// One entry of the shared moderation / decision history log
/// (`moderationHistory/{autoId}`).
///
/// Written on every admin decision: listing verify/reject/suspend/restore,
/// agent approve/reject/revoke, report resolve/dismiss, ban/unban.
class ModerationEntry {
  final String id;

  /// 'listing' | 'agent' | 'report' | 'user'.
  final String targetType;
  final String targetId;

  /// Human-readable action: 'verified', 'rejected', 'suspended', 'restored',
  /// 'approved', 'revoked', 'resolved', 'dismissed', 'banned', 'unbanned'.
  final String action;
  final String? note;
  final String decidedBy;
  final DateTime createdAt;

  const ModerationEntry({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.action,
    this.note,
    required this.decidedBy,
    required this.createdAt,
  });

  factory ModerationEntry.fromMap(Map<String, dynamic> map, String id) {
    return ModerationEntry(
      id: id,
      targetType: map['targetType'] as String? ?? '',
      targetId: map['targetId'] as String? ?? '',
      action: map['action'] as String? ?? '',
      note: map['note'] as String?,
      decidedBy: map['decidedBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ModerationEntry.fromSnapshot(DocumentSnapshot doc) =>
      ModerationEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'targetType': targetType,
    'targetId': targetId,
    'action': action,
    'note': note,
    'decidedBy': decidedBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
