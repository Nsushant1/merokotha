import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/agent_application_model.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'admin_repository.g.dart';

class AdminStats {
  final int totalUsers;
  final int totalOwners;
  final int totalCustomers;
  final int totalAgents;
  final int totalListings;
  final int activeListings;
  final int totalInquiries;
  final int pendingInquiries;
  final int bannedUsers;

  const AdminStats({
    this.totalUsers = 0,
    this.totalOwners = 0,
    this.totalCustomers = 0,
    this.totalAgents = 0,
    this.totalListings = 0,
    this.activeListings = 0,
    this.totalInquiries = 0,
    this.pendingInquiries = 0,
    this.bannedUsers = 0,
  });
}

class AdminRepository {
  final FirebaseFirestore _db;
  AdminRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('listings');
  CollectionReference<Map<String, dynamic>> get _inquiries =>
      _db.collection('inquiries');

  Future<AdminStats> getDashboardStats() async {
    final results = await Future.wait([
      _users.get(),
      _users.where('role', isEqualTo: 'owner').get(),
      _users.where('role', isEqualTo: 'customer').get(),
      _users.where('role', isEqualTo: 'agent').get(),
      _users.where('isBanned', isEqualTo: true).get(),
      _listings.get(),
      _listings.where('status', isEqualTo: 'active').get(),
      _inquiries.get(),
      _inquiries.where('status', isEqualTo: 'pending').get(),
    ]);

    return AdminStats(
      totalUsers: results[0].docs.length,
      totalOwners: results[1].docs.length,
      totalCustomers: results[2].docs.length,
      totalAgents: results[3].docs.length,
      bannedUsers: results[4].docs.length,
      totalListings: results[5].docs.length,
      activeListings: results[6].docs.length,
      totalInquiries: results[7].docs.length,
      pendingInquiries: results[8].docs.length,
    );
  }

  Stream<List<UserModel>> watchAllUsers() {
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromSnapshot(d)).toList());
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snap = await _users.get();
    final all = snap.docs.map((d) => UserModel.fromSnapshot(d)).toList();
    final q = query.toLowerCase();
    return all
        .where((u) => u.name.toLowerCase().contains(q) || u.phone.contains(q))
        .toList();
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  Future<void> banUser(String uid, {String? reason}) async {
    await _users.doc(uid).update({
      'isBanned': true,
      'banReason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Suspend the public agent entry (if any) without losing stored data.
    try {
      await _db.collection('agentsPublic').doc(uid).set({
        'status': 'suspended',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort: only verified agents have directory entries.
    }
  }

  Future<void> unbanUser(String uid) async {
    await _users.doc(uid).update({
      'isBanned': false,
      'banReason': null,
      'bannedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Restore the public agent entry for still-verified agents.
    try {
      final user = await _users.doc(uid).get();
      final data = user.data();
      if (data != null &&
          (data['agentStatus'] as String? ?? 'none') == 'verified') {
        await _db.collection('agentsPublic').doc(uid).set({
          'uid': uid,
          'name': data['name'] ?? '',
          'photoUrl': data['photoUrl'],
          'bio': data['bio'],
          'location': data['location'],
          'publicPhone': data['publicPhone'],
          'whatsappNumber': data['whatsappNumber'],
          'hideDisplayName': data['hideDisplayName'] ?? false,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> setUserRole(String uid, UserRole role) async {
    await _users.doc(uid).update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ListingModel>> watchAllListings() {
    return _listings
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ListingModel.fromSnapshot(d)).toList());
  }

  Stream<List<ListingModel>> watchPendingListings() {
    return _listings
        .where(
          'verificationStatus',
          isEqualTo: VerificationStatus.pending.name,
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ListingModel.fromSnapshot(d)).toList());
  }

  Stream<List<AgentApplicationModel>> watchPendingAgentApplications() {
    return _db
        .collection('agentApplications')
        .where('status', isEqualTo: AgentApplicationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map(AgentApplicationModel.fromSnapshot).toList(),
        );
  }

  Future<void> deleteListing(String listingId) async {
    await _listings.doc(listingId).delete();
  }

  Future<void> setListingStatus(String listingId, ListingStatus status) async {
    await _listings.doc(listingId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin listing review: verify or reject with a reason. Appends a shared
  /// audit entry so the decision history is visible across admin screens.
  Future<void> reviewListing({
    required String listingId,
    required bool approved,
    String? reason,
    required String decidedBy,
  }) async {
    await _listings.doc(listingId).update({
      'verificationStatus': approved
          ? VerificationStatus.verified.name
          : VerificationStatus.rejected.name,
      'reviewReason': reason,
      'reviewedBy': decidedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('moderationHistory').add({
      'targetType': 'listing',
      'targetId': listingId,
      'action': approved ? 'verified' : 'rejected',
      'note': reason,
      'decidedBy': decidedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Suspend a listing (e.g. from report review) or restore it to active.
  /// Restoring returns the listing to pending review.
  Future<void> setListingSuspended(
    String listingId,
    bool suspended, {
    String? reason,
    required String decidedBy,
  }) async {
    await _listings.doc(listingId).update({
      'status': suspended
          ? ListingStatus.suspended.name
          : ListingStatus.active.name,
      if (suspended) 'reviewReason': reason,
      if (suspended) 'reviewedBy': decidedBy,
      if (suspended) 'reviewedAt': FieldValue.serverTimestamp(),
      if (!suspended)
        'verificationStatus': VerificationStatus.pending.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('moderationHistory').add({
      'targetType': 'listing',
      'targetId': listingId,
      'action': suspended ? 'suspended' : 'restored',
      'note': reason,
      'decidedBy': decidedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<InquiryModel>> watchAllInquiries() {
    return _inquiries
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => InquiryModel.fromSnapshot(d)).toList());
  }

  Future<List<ListingModel>> getListingsByOwner(String ownerId) async {
    final snap = await _listings.where('ownerId', isEqualTo: ownerId).get();
    return snap.docs.map((d) => ListingModel.fromSnapshot(d)).toList();
  }

  Future<List<InquiryModel>> getInquiriesByUser(String userId) async {
    final snap = await _inquiries
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => InquiryModel.fromSnapshot(d)).toList();
  }

  Future<List<UserModel>> getRecentUsers({int limit = 5}) async {
    final snap = await _users
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => UserModel.fromSnapshot(d)).toList();
  }

  Future<List<ListingModel>> getRecentListings({int limit = 5}) async {
    final snap = await _listings
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => ListingModel.fromSnapshot(d)).toList();
  }
}

@riverpod
AdminRepository adminRepository(Ref ref) =>
    AdminRepository(ref.watch(firebaseFirestoreProvider));
