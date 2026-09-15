import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  }

  Future<void> unbanUser(String uid) async {
    await _users.doc(uid).update({
      'isBanned': false,
      'banReason': null,
      'bannedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserRole(String uid, UserRole role) async {
    await _users.doc(uid).update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks an agent as admin-verified (or revokes verification).
  /// Posting privileges for agents require isVerified == true.
  Future<void> setVerified(String uid, bool verified) async {
    await _users.doc(uid).update({
      'isVerified': verified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ListingModel>> watchAllListings() {
    return _listings
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ListingModel.fromSnapshot(d)).toList());
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
