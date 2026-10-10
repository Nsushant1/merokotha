import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'user_repository.g.dart';

/// Upper bound on push tokens stored per user. Beyond this the oldest device
/// registrations are dropped — a stale token can never be reactivated, so
/// keeping them only grows the fan-out cost of every send.
const int kMaxFcmTokensPerUser = 10;

class UserRepository {
  final FirebaseFirestore _db;

  UserRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  Future<bool> userExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Persist this device's push token alongside every other device the user
  /// has signed in from.
  ///
  /// [previousToken] is dropped on success — Firebase rotates tokens, and a
  /// stale entry would otherwise accumulate into undeliverable pushes. The list
  /// is capped so a user who reinstalls many times cannot grow it unbounded.
  Future<void> registerFcmToken(
    String uid,
    String token, {
    String? previousToken,
  }) async {
    await _db.runTransaction((txn) async {
      final ref = _users.doc(uid);
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final raw = snap.data()?['fcmTokens'];
      final existing = <String>[
        ...(raw is List ? raw.whereType<String>() : const <String>[]),
      ];

      if (previousToken != null) existing.remove(previousToken);
      if (!existing.contains(token)) existing.add(token);

      // Keep the most recent devices.
      final trimmed = existing.length > kMaxFcmTokensPerUser
          ? existing.sublist(existing.length - kMaxFcmTokensPerUser)
          : existing;

      txn.update(ref, {
        'fcmTokens': trimmed,
        // Retained so anything already reading `fcmToken` keeps working.
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.watch(firebaseFirestoreProvider));
}
