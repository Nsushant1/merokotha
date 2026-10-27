import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/models/report_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

/// Shared audit-log writer + reader for every admin decision.
class ModerationRepository {
  final FirebaseFirestore _db;
  ModerationRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _history =>
      _db.collection('moderationHistory');

  Future<void> log({
    required String targetType,
    required String targetId,
    required String action,
    String? note,
    required String decidedBy,
  }) async {
    await _history.add({
      'targetType': targetType,
      'targetId': targetId,
      'action': action,
      'note': note,
      'decidedBy': decidedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ModerationEntry>> watchRecent({int limit = 50}) {
    return _history
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ModerationEntry.fromSnapshot).toList());
  }

  Stream<List<ModerationEntry>> watchForTarget(
    String targetType,
    String targetId,
  ) {
    return _history
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(ModerationEntry.fromSnapshot).toList());
  }
}

class ReportsRepository {
  final FirebaseFirestore _db;
  final ModerationRepository _moderation;
  ReportsRepository(this._db, this._moderation);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  Future<String> submitReport({
    required String reporterId,
    String? reporterName,
    required String listingId,
    String? listingTitle,
    String? ownerId,
    required String category,
    String details = '',
  }) async {
    final now = DateTime.now();
    final ref = await _reports.add(
      ReportModel(
        id: '',
        reporterId: reporterId,
        reporterName: reporterName,
        listingId: listingId,
        listingTitle: listingTitle,
        ownerId: ownerId,
        category: category,
        details: details,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
    return ref.id;
  }

  Stream<List<ReportModel>> watchMyReports(String reporterId) {
    return _reports
        .where('reporterId', isEqualTo: reporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReportModel.fromSnapshot).toList());
  }

  Stream<List<ReportModel>> watchAllReports({ReportStatus? status}) {
    Query<Map<String, dynamic>> q = _reports.orderBy(
      'createdAt',
      descending: true,
    );
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map(
      (s) => s.docs.map(ReportModel.fromSnapshot).toList(),
    );
  }

  Stream<int> watchPendingCount() {
    return _reports
        .where('status', isEqualTo: ReportStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Resolve or dismiss a report. Optionally suspends (or restores) the
  /// reported listing in the same batch, and always appends an audit entry.
  Future<void> decideReport({
    required String reportId,
    required ReportModel report,
    required bool resolved,
    String? decisionNote,
    required String decidedBy,
    bool suspendListing = false,
    bool restoreListing = false,
  }) async {
    final batch = _db.batch();
    batch.update(_reports.doc(reportId), {
      'status': resolved ? ReportStatus.resolved.name : ReportStatus.dismissed.name,
      'decisionNote': decisionNote,
      'decidedBy': decidedBy,
      'decidedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (suspendListing && report.listingId.isNotEmpty) {
      batch.update(_db.collection('listings').doc(report.listingId), {
        'status': ListingStatus.suspended.name,
        'reviewReason': decisionNote,
        'reviewedBy': decidedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (restoreListing && report.listingId.isNotEmpty) {
      batch.update(_db.collection('listings').doc(report.listingId), {
        'status': ListingStatus.active.name,
        'verificationStatus': VerificationStatus.pending.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    await _moderation.log(
      targetType: 'report',
      targetId: reportId,
      action: resolved ? 'resolved' : 'dismissed',
      note: decisionNote,
      decidedBy: decidedBy,
    );
    if (suspendListing && report.listingId.isNotEmpty) {
      await _moderation.log(
        targetType: 'listing',
        targetId: report.listingId,
        action: 'suspended',
        note: decisionNote,
        decidedBy: decidedBy,
      );
    }
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(ref.watch(firebaseFirestoreProvider)),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(moderationRepositoryProvider),
  ),
);

/// All reports (admin), optionally filtered by status.
final allReportsProvider =
    StreamProvider.family<List<ReportModel>, ReportStatus?>((ref, status) {
      return ref.watch(reportsRepositoryProvider).watchAllReports(
        status: status,
      );
    });

/// Pending report count for the admin dashboard badge.
final pendingReportsCountProvider = StreamProvider<int>(
  (ref) => ref.watch(reportsRepositoryProvider).watchPendingCount(),
);

/// Recent shared decision history (admin).
final moderationHistoryProvider = StreamProvider<List<ModerationEntry>>(
  (ref) => ref.watch(moderationRepositoryProvider).watchRecent(),
);
