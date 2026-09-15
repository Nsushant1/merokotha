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
    if (state.isSending) return;
    if (state.isLockedOut) return;

    final formatted = normalizeNepalPhone(phoneNumber);
    if (formatted == null) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Enter a valid Nepal phone number',
      );
      return;
    }

    state = state.copyWith(
      isSending: true,
      clearError: true,
      clearLockout: true,
      failedAttempts: 0,
    );

    await ref
        .read(authRepositoryProvider)
        .sendOtp(
          phoneNumber: formatted,
          forceResendingToken: state.resendToken,
          onCodeSent: (verificationId, resendToken) {
            state = state.copyWith(
              isSending: false,
              codeSent: true,
              verificationId: verificationId,
              resendToken: resendToken,
            );
          },
          onAutoRetrievalTimeout: (verificationId) {
            // Keep the verificationId even if auto-retrieval times out
            // without codeSent firing (slow networks / Play Integrity delay).
            if (!state.codeSent && state.verificationId == null) {
              state = state.copyWith(
                isSending: false,
                codeSent: true,
                verificationId: verificationId,
              );
            } else if (state.isSending) {
              state = state.copyWith(isSending: false);
            }
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
    if (state.verificationId == null) {
      state = state.copyWith(errorMessage: 'OTP session expired. Request a new code');
      return false;
    }
    if (state.isLockedOut) return false;
    if (state.isVerifying) return false;

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

  /// Normalizes any user-typed Nepal number to E.164 (`+97798XXXXXXXX`).
  /// Returns null when the input cannot be a valid Nepal mobile number.
  /// Handles: spaces, dashes, brackets, leading '+', '977' prefix
  /// duplication, and a single trunk-zero.
  static String? normalizeNepalPhone(String input) {
    var cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return null;
    if (cleaned.startsWith('977')) cleaned = cleaned.substring(3);
    if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
    if (!RegExp(r'^(97|98)\d{8}$').hasMatch(cleaned)) return null;
    return '+977$cleaned';
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
      case 'missing-phone-number':
        return 'Invalid phone number format';
      case 'app-not-authorized':
      case 'invalid-app-credential':
      case 'missing-client-identifier':
        return 'OTP is blocked for this build. Please update the app or contact support';
      case 'captcha-check-failed':
        return 'Device verification failed. Use a real device with Play Services and retry';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'Too many attempts. Try again later';
      case 'invalid-verification-code':
        return 'Wrong OTP. Please try again';
      case 'invalid-verification-id':
        return 'Session invalid. Request a new OTP';
      case 'session-expired':
      case 'code-expired':
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
