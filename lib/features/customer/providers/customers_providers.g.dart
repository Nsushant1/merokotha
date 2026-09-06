// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeListings)
final activeListingsProvider = ActiveListingsProvider._();

final class ActiveListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ListingModel>>,
          List<ListingModel>,
          Stream<List<ListingModel>>
        >
    with
        $FutureModifier<List<ListingModel>>,
        $StreamProvider<List<ListingModel>> {
  ActiveListingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeListingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeListingsHash();

  @$internal
  @override
  $StreamProviderElement<List<ListingModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ListingModel>> create(Ref ref) {
    return activeListings(ref);
  }
}

String _$activeListingsHash() => r'c093bb49bf23ff9b2abd95bbb9b1c6750222f595';

@ProviderFor(listingDetail)
final listingDetailProvider = ListingDetailFamily._();

final class ListingDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ListingModel?>,
          ListingModel?,
          FutureOr<ListingModel?>
        >
    with $FutureModifier<ListingModel?>, $FutureProvider<ListingModel?> {
  ListingDetailProvider._({
    required ListingDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listingDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listingDetailHash();

  @override
  String toString() {
    return r'listingDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ListingModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ListingModel?> create(Ref ref) {
    final argument = this.argument as String;
    return listingDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListingDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listingDetailHash() => r'37418a0ff39801dbe68c7103d58db0acb81581ee';

final class ListingDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ListingModel?>, String> {
  ListingDetailFamily._()
    : super(
        retry: null,
        name: r'listingDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ListingDetailProvider call(String listingId) =>
      ListingDetailProvider._(argument: listingId, from: this);

  @override
  String toString() => r'listingDetailProvider';
}

@ProviderFor(SearchFilterNotifier)
final searchFilterProvider = SearchFilterNotifierProvider._();

final class SearchFilterNotifierProvider
    extends $NotifierProvider<SearchFilterNotifier, SearchFilter> {
  SearchFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchFilterNotifierHash();

  @$internal
  @override
  SearchFilterNotifier create() => SearchFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchFilter>(value),
    );
  }
}

String _$searchFilterNotifierHash() =>
    r'189116ad20487e218a1ba3c3bab376f4ababcc69';

abstract class _$SearchFilterNotifier extends $Notifier<SearchFilter> {
  SearchFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchFilter, SearchFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchFilter, SearchFilter>,
              SearchFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchResults)
final searchResultsProvider = SearchResultsProvider._();

final class SearchResultsProvider
    extends $AsyncNotifierProvider<SearchResults, List<ListingModel>> {
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  SearchResults create() => SearchResults();
}

String _$searchResultsHash() => r'47bb49ea43291481b2961dc2dabeb4db22eddafd';

abstract class _$SearchResults extends $AsyncNotifier<List<ListingModel>> {
  FutureOr<List<ListingModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ListingModel>>, List<ListingModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ListingModel>>, List<ListingModel>>,
              AsyncValue<List<ListingModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(favouriteIds)
final favouriteIdsProvider = FavouriteIdsProvider._();

final class FavouriteIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  FavouriteIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouriteIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouriteIdsHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return favouriteIds(ref);
  }
}

String _$favouriteIdsHash() => r'dde833ddcdf18a8d20d83fc5c33c53d4c690cc6d';

@ProviderFor(isListingFavourited)
final isListingFavouritedProvider = IsListingFavouritedFamily._();

final class IsListingFavouritedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsListingFavouritedProvider._({
    required IsListingFavouritedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isListingFavouritedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isListingFavouritedHash();

  @override
  String toString() {
    return r'isListingFavouritedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isListingFavourited(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsListingFavouritedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isListingFavouritedHash() =>
    r'f6e58db9caa1f7a1b98720c691b69bb7ec8dbdd3';

final class IsListingFavouritedFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsListingFavouritedFamily._()
    : super(
        retry: null,
        name: r'isListingFavouritedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsListingFavouritedProvider call(String listingId) =>
      IsListingFavouritedProvider._(argument: listingId, from: this);

  @override
  String toString() => r'isListingFavouritedProvider';
}

@ProviderFor(favouriteListings)
final favouriteListingsProvider = FavouriteListingsProvider._();

final class FavouriteListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ListingModel>>,
          List<ListingModel>,
          FutureOr<List<ListingModel>>
        >
    with
        $FutureModifier<List<ListingModel>>,
        $FutureProvider<List<ListingModel>> {
  FavouriteListingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouriteListingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouriteListingsHash();

  @$internal
  @override
  $FutureProviderElement<List<ListingModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ListingModel>> create(Ref ref) {
    return favouriteListings(ref);
  }
}

String _$favouriteListingsHash() => r'e085c57ecbece29365526fdc66f335869078a17c';

@ProviderFor(FavouriteNotifier)
final favouriteProvider = FavouriteNotifierProvider._();

final class FavouriteNotifierProvider
    extends $NotifierProvider<FavouriteNotifier, AsyncValue<void>> {
  FavouriteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouriteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouriteNotifierHash();

  @$internal
  @override
  FavouriteNotifier create() => FavouriteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$favouriteNotifierHash() => r'68e74e09d9c053de9728f0fbf4bbceccc4110126';

abstract class _$FavouriteNotifier extends $Notifier<AsyncValue<void>> {
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

@ProviderFor(SendInquiryNotifier)
final sendInquiryProvider = SendInquiryNotifierProvider._();

final class SendInquiryNotifierProvider
    extends $NotifierProvider<SendInquiryNotifier, SendInquiryState> {
  SendInquiryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendInquiryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendInquiryNotifierHash();

  @$internal
  @override
  SendInquiryNotifier create() => SendInquiryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendInquiryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendInquiryState>(value),
    );
  }
}

String _$sendInquiryNotifierHash() =>
    r'06a94692262405619abb87adbbc3dd7fe336da28';

abstract class _$SendInquiryNotifier extends $Notifier<SendInquiryState> {
  SendInquiryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SendInquiryState, SendInquiryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SendInquiryState, SendInquiryState>,
              SendInquiryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(mapListings)
final mapListingsProvider = MapListingsProvider._();

final class MapListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ListingModel>>,
          List<ListingModel>,
          FutureOr<List<ListingModel>>
        >
    with
        $FutureModifier<List<ListingModel>>,
        $FutureProvider<List<ListingModel>> {
  MapListingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapListingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapListingsHash();

  @$internal
  @override
  $FutureProviderElement<List<ListingModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ListingModel>> create(Ref ref) {
    return mapListings(ref);
  }
}

String _$mapListingsHash() => r'0c5b0348fb70ac0f32a565f718beed8dad6e8e07';
