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

  // ── Email / password ──────────────────────────────────────────────

  /// Register with email + password. Returns the new credential, or null
  /// when Firebase auto-links (rare). Throws [FirebaseAuthException].
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email + password. Throws [FirebaseAuthException]
  /// (`user-not-found`, `wrong-password` / `invalid-credential`).
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Send a password-reset email. Never reveals whether the address exists
  /// (Firebase returns success either way for valid addresses).
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Link the Google provider to the CURRENT user (e.g. an email/password
  /// account linking Google) so both sign-in methods share the same UID.
  /// Returns null when the user cancels the Google flow.
  Future<UserCredential?> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Google sign-in failed (missing ID token).',
      );
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
    return await user.linkWithCredential(credential);
  }

  /// Link an email/password credential to the CURRENT user (e.g. a Google
  /// account adding a password). Same UID is preserved.
  Future<UserCredential> linkWithEmail({
    required String email,
    required String password,
  }) {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    return user.linkWithCredential(credential);
  }

  /// Provider ids linked to the current user (e.g. 'google.com', 'password').
  List<String> get linkedProviders =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
      const [];
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
}
