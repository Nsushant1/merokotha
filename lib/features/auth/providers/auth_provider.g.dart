// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'c88cb36d6c93a5c7df685b2918f2d0f0710965a0';

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

final class CurrentUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserModel?>,
          UserModel?,
          FutureOr<UserModel?>
        >
    with $FutureModifier<UserModel?>, $FutureProvider<UserModel?> {
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $FutureProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserModel?> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'1eefb03ba0c7ffbb3a1b97d0f9c35260b0de5796';

@ProviderFor(GoogleSignInNotifier)
final googleSignInProvider = GoogleSignInNotifierProvider._();

final class GoogleSignInNotifierProvider
    extends $NotifierProvider<GoogleSignInNotifier, GoogleSignInState> {
  GoogleSignInNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleSignInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleSignInNotifierHash();

  @$internal
  @override
  GoogleSignInNotifier create() => GoogleSignInNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleSignInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleSignInState>(value),
    );
  }
}

String _$googleSignInNotifierHash() =>
    r'240e2634251496b8199373046c3f67aed742d8b6';

abstract class _$GoogleSignInNotifier extends $Notifier<GoogleSignInState> {
  GoogleSignInState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoogleSignInState, GoogleSignInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoogleSignInState, GoogleSignInState>,
              GoogleSignInState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
