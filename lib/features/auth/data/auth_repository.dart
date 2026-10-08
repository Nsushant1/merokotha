import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'auth_repository.g.dart';

/// Web (type 3) OAuth client from google-services.json.
/// Required so Google returns an ID token that Firebase can verify,
/// including on Play-App-Signing builds where the APK signature differs
/// from the upload/debug keystores.
const String kGoogleServerClientId =
    '125819822476-unapaidn42h338m4c8ravo0no7tud4ja.apps.googleusercontent.com';

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._auth, {GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: const ['email', 'profile'],
            serverClientId: kGoogleServerClientId,
          );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      // This happens when the APK signature (e.g. Play App Signing cert)
      // has no matching Android OAuth client in Firebase/Google Cloud.
      // Surface a clear log; the notifier maps it to a user message.
      debugPrint(
        'AuthRepository.signInWithGoogle: missing idToken. '
        'Check Play App Signing SHA-1 is registered in Firebase.',
      );
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message:
            'Google sign-in failed (missing ID token). The Play Store signing key may not be registered.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
}
