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

  /// Name/photo projection readable by any signed-in user. Phone, email,
  /// tokens and moderation flags live only in `users/{uid}`, which is
  /// restricted to the owner and admins.
  CollectionReference<Map<String, dynamic>> get _usersPublic =>
      _db.collection('usersPublic');

  Future<void> createUser(UserModel user) async {
    final batch = _db.batch();
    batch.set(_users.doc(user.id), user.toMap());
    batch.set(
      _usersPublic.doc(user.id),
      PublicProfile(
        uid: user.id,
        name: user.name,
        photoUrl: user.photoUrl,
        bio: user.bio,
        publicPhone: user.publicPhone,
        whatsappNumber: user.whatsappNumber,
        hideDisplayName: user.hideDisplayName,
      ).toMap(),
    );
    await batch.commit();
  }

  /// Display name/photo of any user. Returns null when the user never
  /// published one (legacy accounts predate this collection) — callers
  /// must fall back to denormalized names from listings/chats.
  Future<PublicProfile?> getPublicProfile(String uid) async {
    final doc = await _usersPublic.doc(uid).get();
    if (!doc.exists) return null;
    return PublicProfile.fromSnapshot(doc);
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
    final batch = _db.batch();
    batch.update(_users.doc(uid), {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Keep the public projection in sync when display fields change.
    final public = <String, dynamic>{};
    if (data['name'] is String) public['name'] = data['name'];
    if (data.containsKey('photoUrl')) public['photoUrl'] = data['photoUrl'];
    if (data.containsKey('bio')) public['bio'] = data['bio'];
    if (data.containsKey('publicPhone')) {
      public['publicPhone'] = data['publicPhone'];
    }
    if (data.containsKey('whatsappNumber')) {
      public['whatsappNumber'] = data['whatsappNumber'];
    }
    if (data['hideDisplayName'] is bool) {
      public['hideDisplayName'] = data['hideDisplayName'];
    }
    if (public.isNotEmpty) {
      public['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(_usersPublic.doc(uid), public, SetOptions(merge: true));
    }
    await batch.commit();

    // Merge the same display fields into the public agent directory when
    // the editor is a verified agent (best-effort).
    try {
      const displayKeys = {
        'name',
        'photoUrl',
        'bio',
        'location',
        'publicPhone',
        'whatsappNumber',
        'hideDisplayName',
      };
      if (data.keys.any(displayKeys.contains)) {
        final user = await _users.doc(uid).get();
        final current = user.data();
        if (current != null &&
            (current['agentStatus'] as String? ?? 'none') == 'verified' &&
            (current['isBanned'] as bool? ?? false) == false) {
          final dir = <String, dynamic>{
            'uid': uid,
            'status': 'active',
            'updatedAt': FieldValue.serverTimestamp(),
          };
          for (final k in displayKeys) {
            if (data.containsKey(k)) dir[k] = data[k];
          }
          await _db.collection('agentsPublic').doc(uid).set(
            dir,
            SetOptions(merge: true),
          );
        }
      }
    } catch (_) {
      // Best-effort.
    }
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

  /// Remove this device's token when signing out so pushes for this
  /// account stop reaching the device. Best-effort: sign-out must never
  /// fail because of it — callers swallow errors.
  Future<void> unregisterFcmToken(String uid, String token) async {
    final ref = _users.doc(uid);
    if (!(await ref.get()).exists) return;
    await ref.update({
      'fcmTokens': FieldValue.arrayRemove([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Clear the legacy single-token field only if it is this device's
    // token; another device may have rotated it since.
    final snap = await _users.doc(uid).get();
    if (snap.data()?['fcmToken'] == token) {
      await _users.doc(uid).update({'fcmToken': FieldValue.delete()});
    }
  }
}

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.watch(firebaseFirestoreProvider));
}
