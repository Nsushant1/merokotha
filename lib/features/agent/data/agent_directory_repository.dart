import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

/// Public projection of a verified agent, stored at `agentsPublic/{uid}`.
/// Field names mirror the website schema — confirm against the web app
/// before going live.
class AgentDirectoryEntry {
  final String uid;
  final String name;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final String? publicPhone;
  final String? whatsappNumber;
  final bool hideDisplayName;

  /// 'active' | 'suspended'. Suspended entries stay stored but are hidden
  /// from the public directory until restored.
  final String status;

  const AgentDirectoryEntry({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.bio,
    this.location,
    this.publicPhone,
    this.whatsappNumber,
    this.hideDisplayName = false,
    this.status = 'active',
  });

  bool get isActive => status == 'active';

  String get displayName => hideDisplayName ? 'Agent' : name;

  factory AgentDirectoryEntry.fromMap(Map<String, dynamic> map, String uid) {
    return AgentDirectoryEntry(
      uid: uid,
      name: map['name'] as String? ?? 'Agent',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      location: map['location'] as String?,
      publicPhone: map['publicPhone'] as String?,
      whatsappNumber: map['whatsappNumber'] as String?,
      hideDisplayName: map['hideDisplayName'] as bool? ?? false,
      status: map['status'] as String? ?? 'active',
    );
  }

  factory AgentDirectoryEntry.fromSnapshot(DocumentSnapshot doc) =>
      AgentDirectoryEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'photoUrl': photoUrl,
    'bio': bio,
    'location': location,
    'publicPhone': publicPhone,
    'whatsappNumber': whatsappNumber,
    'hideDisplayName': hideDisplayName,
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class AgentDirectoryRepository {
  final FirebaseFirestore _db;
  AgentDirectoryRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _agents =>
      _db.collection('agentsPublic');

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _agents.doc(uid);

  /// Active (non-suspended) directory entries, newest first.
  Stream<List<AgentDirectoryEntry>> watchActiveAgents() {
    return _agents
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (s) => s.docs.map(AgentDirectoryEntry.fromSnapshot).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Future<AgentDirectoryEntry?> getAgent(String uid) async {
    final doc = await _doc(uid).get();
    if (!doc.exists) return null;
    return AgentDirectoryEntry.fromSnapshot(doc);
  }

  /// Active rentals posted by the agent.
  Stream<List<ListingModel>> watchAgentRentals(String agentId) {
    return _db
        .collection('listings')
        .where('agentId', isEqualTo: agentId)
        .where('status', isEqualTo: ListingStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ListingModel.fromSnapshot).toList());
  }

  // ── Synchronization (called from admin + profile flows) ────────────

  /// Upsert on approval / restore / profile edit.
  Future<void> upsertFromUser({
    required String uid,
    required String name,
    String? photoUrl,
    String? bio,
    String? location,
    String? publicPhone,
    String? whatsappNumber,
    bool hideDisplayName = false,
  }) async {
    await _doc(uid).set({
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'bio': bio,
      'location': location,
      'publicPhone': publicPhone,
      'whatsappNumber': whatsappNumber,
      'hideDisplayName': hideDisplayName,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove on rejection / revoke.
  Future<void> remove(String uid) async {
    final doc = await _doc(uid).get();
    if (doc.exists) await _doc(uid).delete();
  }

  /// Suspend (ban) or restore (unban) without losing stored data.
  Future<void> setSuspended(String uid, bool suspended) async {
    await _doc(uid).set({
      'status': suspended ? 'suspended' : 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final agentDirectoryRepositoryProvider = Provider<AgentDirectoryRepository>(
  (ref) => AgentDirectoryRepository(ref.watch(firebaseFirestoreProvider)),
);

/// Public verified-agent directory (active entries only).
final agentDirectoryProvider = StreamProvider<List<AgentDirectoryEntry>>((
  ref,
) {
  return ref.watch(agentDirectoryRepositoryProvider).watchActiveAgents();
});

/// Active rentals of one agent (public profile screen).
final agentRentalsProvider =
    StreamProvider.family<List<ListingModel>, String>((ref, agentId) {
      return ref
          .watch(agentDirectoryRepositoryProvider)
          .watchAgentRentals(agentId);
    });
