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

class GoogleSignInState {
  final bool isLoading;
  final String? errorMessage;

  const GoogleSignInState({
    this.isLoading = false,
    this.errorMessage,
  });

  GoogleSignInState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoogleSignInState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@riverpod
class GoogleSignInNotifier extends _$GoogleSignInNotifier {
  @override
  GoogleSignInState build() => const GoogleSignInState();

  Future<bool> signInWithGoogle() async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (credential == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'Invalid sign-in credentials. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
