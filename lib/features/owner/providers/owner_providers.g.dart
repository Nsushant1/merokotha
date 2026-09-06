// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ownerListings)
final ownerListingsProvider = OwnerListingsProvider._();

final class OwnerListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ListingModel>>,
          List<ListingModel>,
          Stream<List<ListingModel>>
        >
    with
        $FutureModifier<List<ListingModel>>,
        $StreamProvider<List<ListingModel>> {
  OwnerListingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerListingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerListingsHash();

  @$internal
  @override
  $StreamProviderElement<List<ListingModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ListingModel>> create(Ref ref) {
    return ownerListings(ref);
  }
}

String _$ownerListingsHash() => r'e6e22d77870ab5d8fafee099b834f4b1d83c84f8';

@ProviderFor(pendingInquiryCount)
final pendingInquiryCountProvider = PendingInquiryCountProvider._();

final class PendingInquiryCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  PendingInquiryCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInquiryCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInquiryCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return pendingInquiryCount(ref);
  }
}

String _$pendingInquiryCountHash() =>
    r'be0f0aff9c011d792152372aea6c076bef55f679';

@ProviderFor(UploadListingNotifier)
final uploadListingProvider = UploadListingNotifierProvider._();

final class UploadListingNotifierProvider
    extends $NotifierProvider<UploadListingNotifier, UploadListingState> {
  UploadListingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadListingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadListingNotifierHash();

  @$internal
  @override
  UploadListingNotifier create() => UploadListingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadListingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadListingState>(value),
    );
  }
}

String _$uploadListingNotifierHash() =>
    r'e4aae10f3b7024f17d7dc44989173a80e9b48f4c';

abstract class _$UploadListingNotifier extends $Notifier<UploadListingState> {
  UploadListingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UploadListingState, UploadListingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UploadListingState, UploadListingState>,
              UploadListingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ListingStatusNotifier)
final listingStatusProvider = ListingStatusNotifierProvider._();

final class ListingStatusNotifierProvider
    extends $NotifierProvider<ListingStatusNotifier, AsyncValue<void>> {
  ListingStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listingStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listingStatusNotifierHash();

  @$internal
  @override
  ListingStatusNotifier create() => ListingStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$listingStatusNotifierHash() =>
    r'0c7cc6f4d54fbf4a7ae7dc1dedf99ebceb16a371';

abstract class _$ListingStatusNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
