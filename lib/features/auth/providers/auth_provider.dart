import 'package:firebase_auth/firebase_auth.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
Future<UserModel?> currentUser(Ref ref) async {
  final firebaseUser = ref
      .watch(authStateProvider)
      .whenData((data) => data)
      .value;
  if (firebaseUser == null) return null;
  return ref.watch(userRepositoryProvider).getUser(firebaseUser.uid);
}

class OtpState {
  final bool isSending;
  final bool isVerifying;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;
  final bool codeSent;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  const OtpState({
    this.isSending = false,
    this.isVerifying = false,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
    this.codeSent = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  int get lockoutSecondsRemaining {
    if (lockoutUntil == null) return 0;
    final diff = lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  OtpState copyWith({
    bool? isSending,
    bool? isVerifying,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
    bool? codeSent,
    int? failedAttempts,
    DateTime? lockoutUntil,
    bool clearError = false,
    bool clearLockout = false,
  }) {
    return OtpState(
      isSending: isSending ?? this.isSending,
      isVerifying: isVerifying ?? this.isVerifying,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      codeSent: codeSent ?? this.codeSent,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
    );
  }
}

@riverpod
class OtpNotifier extends _$OtpNotifier {
  @override
  OtpState build() => const OtpState();

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isSending: true,
      clearError: true,
      clearLockout: true,
      failedAttempts: 0,
    );

    final formatted = phoneNumber.startsWith('+')
        ? phoneNumber
        : '+977${phoneNumber.replaceAll(RegExp(r'^0'), '')}';

    await ref
        .read(authRepositoryProvider)
        .sendOtp(
          phoneNumber: formatted,
          onCodeSent: (verificationId, resendToken) {
            state = state.copyWith(
              isSending: false,
              codeSent: true,
              verificationId: verificationId,
              resendToken: resendToken,
            );
          },
          onError: (e) {
            state = state.copyWith(
              isSending: false,
              errorMessage: _mapFirebaseError(e.code),
            );
          },
          onAutoVerified: (credential) async {
            state = state.copyWith(isVerifying: true);
            try {
              await FirebaseAuth.instance.signInWithCredential(credential);
            } catch (_) {}
            state = state.copyWith(isVerifying: false);
          },
        );
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (state.verificationId == null) return false;
    if (state.isLockedOut) return false;

    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(verificationId: state.verificationId!, smsCode: smsCode);
      state = state.copyWith(isVerifying: false, clearLockout: true, failedAttempts: 0);
      return true;
    } on FirebaseAuthException catch (e) {
      final attempts = state.failedAttempts + 1;
      final locked = attempts >= 3;
      state = state.copyWith(
        isVerifying: false,
        errorMessage: locked
            ? 'Too many failed attempts. Please wait.'
            : _mapFirebaseError(e.code),
        failedAttempts: attempts,
        lockoutUntil: locked ? DateTime.now().add(const Duration(seconds: 10)) : null,
      );
      return false;
    }
  }

  void resetError() => state = state.copyWith(clearError: true);
  void resetAll() => state = const OtpState();

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'invalid-verification-code':
        return 'Wrong OTP. Please try again';
      case 'session-expired':
        return 'OTP expired. Request a new one';
      case 'network-request-failed':
        return 'No internet connection';
      case 'sms-retriever-timeout':
        return 'Could not retrieve SMS automatically. Please enter OTP manually';
      case 'sms-retriever-error':
        return 'SMS retrieval failed. Please enter OTP manually';
      default:
        return 'Something went wrong. Please try again';
    }
  }
}
