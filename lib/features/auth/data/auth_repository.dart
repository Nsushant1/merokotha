import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/providers/firebase_providers.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    int? forceResendingToken,
    void Function(String verificationId)? onAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        // 120s timeout: default 60s was too short on slow networks
        timeout: const Duration(seconds: 120),
        forceResendingToken: forceResendingToken,
        verificationCompleted: onAutoVerified,
        verificationFailed: onError,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (verificationId) {
          onAutoRetrievalTimeout?.call(verificationId);
        },
      );
    } on FirebaseAuthException catch (e) {
      onError(e);
    } catch (_) {
      onError(
        FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Could not reach the OTP service. Check connection and retry.',
        ),
      );
    }
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
}
