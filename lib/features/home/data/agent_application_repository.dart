import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/agent_application_model.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'agent_application_repository.g.dart';

/// Persists "Become an Agent" applications.
///
/// Filing an application never grants privileges. Approval is an explicit
/// admin decision that flips the applicant's `agentStatus` in the same
/// batch as the application verdict.
class AgentApplicationRepository {
  final FirebaseFirestore _db;

  AgentApplicationRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _applications =>
      _db.collection('agentApplications');

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _applications.doc(uid);

  /// The caller's application, if any.
  Stream<AgentApplicationModel?> watchMyApplication(String uid) {
    return _doc(uid).snapshots().map(
      (s) => s.exists ? AgentApplicationModel.fromSnapshot(s) : null,
    );
  }

  /// Any single application (admin review).
  Stream<AgentApplicationModel?> watchApplication(String uid) =>
      watchMyApplication(uid);

  /// File (or re-file) a pending application.
  ///
  /// Re-application preserves the original `createdAt` and prior decision
  /// metadata (rules keep them immutable applicant-side) while resetting
  /// the verdict to pending with a cleared reason.
  Future<void> submitApplication({
    required String uid,
    required String fullName,
    required String phone,
    required String location,
    String? notes,
  }) async {
    final existing = await _doc(uid).get();
    if (!existing.exists) {
      final now = DateTime.now();
      await _doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'phone': phone,
        'location': location,
        'notes': notes,
        'status': AgentApplicationStatus.pending.name,
        'reason': null,
        'createdAt': Timestamp.fromDate(now),
        'decidedAt': null,
        'decidedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await _doc(uid).update({
      'fullName': fullName,
      'phone': phone,
      'location': location,
      'notes': notes,
      'status': AgentApplicationStatus.pending.name,
      'reason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin decision. Approval unlocks the Agent interface by flipping
  /// `agentStatus`; rejection resets it so the user may re-apply.
  /// Both documents change atomically — never one without the other.
  Future<void> decideApplication({
    required String uid,
    required bool approved,
    required String decidedBy,
    String? reason,
  }) async {
    final now = Timestamp.now();
    final batch = _db.batch();
    batch.update(_doc(uid), {
      'status': approved
          ? AgentApplicationStatus.approved.name
          : AgentApplicationStatus.rejected.name,
      'reason': reason,
      'decidedAt': now,
      'decidedBy': decidedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('users').doc(uid), {
      'agentStatus': approved
          ? AgentStatus.verified.name
          : AgentStatus.none.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}

@riverpod
AgentApplicationRepository agentApplicationRepository(Ref ref) {
  return AgentApplicationRepository(ref.watch(firebaseFirestoreProvider));
}
