import 'package:cloud_firestore/cloud_firestore.dart';

/// Review state of an agent application. Only `pending` is writable by the
/// applicant; `approved`/`rejected` are admin decisions.
enum AgentApplicationStatus { pending, approved, rejected }

/// Application to become an agent, stored at
/// `agentApplications/{uid}` (one document per applicant).
///
/// Submitting an application grants nothing — agent privileges are unlocked
/// only when an admin approves it (which flips the applicant's
/// `agentStatus` to `verified`).
class AgentApplicationModel {
  final String uid;
  final String fullName;
  final String phone;
  final String location;
  final String? notes;
  final AgentApplicationStatus status;
  final String? reason;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;

  const AgentApplicationModel({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.location,
    this.notes,
    this.status = AgentApplicationStatus.pending,
    this.reason,
    required this.createdAt,
    this.decidedAt,
    this.decidedBy,
  });

  factory AgentApplicationModel.fromMap(Map<String, dynamic> map, String uid) {
    return AgentApplicationModel(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String?,
      status: AgentApplicationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AgentApplicationStatus.pending,
      ),
      reason: map['reason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      decidedAt: (map['decidedAt'] as Timestamp?)?.toDate(),
      decidedBy: map['decidedBy'] as String?,
    );
  }

  factory AgentApplicationModel.fromSnapshot(DocumentSnapshot doc) =>
      AgentApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'phone': phone,
    'location': location,
    'notes': notes,
    'status': status.name,
    'reason': reason,
    'createdAt': Timestamp.fromDate(createdAt),
    'decidedAt': decidedAt != null ? Timestamp.fromDate(decidedAt!) : null,
    'decidedBy': decidedBy,
  };
}
