// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardStats)
final dashboardStatsProvider = DashboardStatsProvider._();

final class DashboardStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminStats>,
          AdminStats,
          FutureOr<AdminStats>
        >
    with $FutureModifier<AdminStats>, $FutureProvider<AdminStats> {
  DashboardStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardStatsHash();

  @$internal
  @override
  $FutureProviderElement<AdminStats> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AdminStats> create(Ref ref) {
    return dashboardStats(ref);
  }
}

String _$dashboardStatsHash() => r'cc72131ba923238e933ee43a90c33a3b8303dbde';

@ProviderFor(allUsers)
final allUsersProvider = AllUsersProvider._();

final class AllUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserModel>>,
          List<UserModel>,
          Stream<List<UserModel>>
        >
    with $FutureModifier<List<UserModel>>, $StreamProvider<List<UserModel>> {
  AllUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allUsersHash();

  @$internal
  @override
  $StreamProviderElement<List<UserModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<UserModel>> create(Ref ref) {
    return allUsers(ref);
  }
}

String _$allUsersHash() => r'5dbe9d87dcbd21f5f3324a0ef215ba201f4eddff';

@ProviderFor(allListings)
final allListingsProvider = AllListingsProvider._();

final class AllListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ListingModel>>,
          List<ListingModel>,
          Stream<List<ListingModel>>
        >
    with
        $FutureModifier<List<ListingModel>>,
        $StreamProvider<List<ListingModel>> {
  AllListingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allListingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allListingsHash();

  @$internal
  @override
  $StreamProviderElement<List<ListingModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ListingModel>> create(Ref ref) {
    return allListings(ref);
  }
}

String _$allListingsHash() => r'edb3ae52fc067286249c43be086fa8ec8b3fe561';

@ProviderFor(allInquiries)
final allInquiriesProvider = AllInquiriesProvider._();

final class AllInquiriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InquiryModel>>,
          List<InquiryModel>,
          Stream<List<InquiryModel>>
        >
    with
        $FutureModifier<List<InquiryModel>>,
        $StreamProvider<List<InquiryModel>> {
  AllInquiriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allInquiriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allInquiriesHash();

  @$internal
  @override
  $StreamProviderElement<List<InquiryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InquiryModel>> create(Ref ref) {
    return allInquiries(ref);
  }
}

String _$allInquiriesHash() => r'b3dbe817e41a47bf1cea12c49c093378d56f4eb7';

@ProviderFor(recentUsers)
final recentUsersProvider = RecentUsersProvider._();

final class RecentUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserModel>>,
          List<UserModel>,
          FutureOr<List<UserModel>>
        >
    with $FutureModifier<List<UserModel>>, $FutureProvider<List<UserModel>> {
  RecentUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentUsersHash();

  @$internal
  @override
  $FutureProviderElement<List<UserModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserModel>> create(Ref ref) {
    return recentUsers(ref);
  }
}

String _$recentUsersHash() => r'04bd276e5af44a0e94ac30e611854a1ea18ad533';

@ProviderFor(recentListings)
final recentListingsProvider = RecentListingsProvider._();

final class RecentListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ListingModel>>,
          List<ListingModel>,
          FutureOr<List<ListingModel>>
        >
    with
        $FutureModifier<List<ListingModel>>,
        $FutureProvider<List<ListingModel>> {
  RecentListingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentListingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentListingsHash();

  @$internal
  @override
  $FutureProviderElement<List<ListingModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ListingModel>> create(Ref ref) {
    return recentListings(ref);
  }
}

String _$recentListingsHash() => r'dc36af4d90463b35ea7b68342588d3c60c3a193b';

@ProviderFor(adminUserDetail)
final adminUserDetailProvider = AdminUserDetailFamily._();

final class AdminUserDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserModel?>,
          UserModel?,
          FutureOr<UserModel?>
        >
    with $FutureModifier<UserModel?>, $FutureProvider<UserModel?> {
  AdminUserDetailProvider._({
    required AdminUserDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminUserDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminUserDetailHash();

  @override
  String toString() {
    return r'adminUserDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserModel?> create(Ref ref) {
    final argument = this.argument as String;
    return adminUserDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUserDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminUserDetailHash() => r'17cb9c54e583f1771c79f94648de997a80e5cc17';

final class AdminUserDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserModel?>, String> {
  AdminUserDetailFamily._()
    : super(
        retry: null,
        name: r'adminUserDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminUserDetailProvider call(String uid) =>
      AdminUserDetailProvider._(argument: uid, from: this);

  @override
  String toString() => r'adminUserDetailProvider';
}

@ProviderFor(UserSearch)
final userSearchProvider = UserSearchProvider._();

final class UserSearchProvider extends $NotifierProvider<UserSearch, String> {
  UserSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSearchHash();

  @$internal
  @override
  UserSearch create() => UserSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$userSearchHash() => r'623c92cb1ba9049766eff07d6dc7a926f1336b24';

abstract class _$UserSearch extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(searchedUsers)
final searchedUsersProvider = SearchedUsersProvider._();

final class SearchedUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserModel>>,
          List<UserModel>,
          FutureOr<List<UserModel>>
        >
    with $FutureModifier<List<UserModel>>, $FutureProvider<List<UserModel>> {
  SearchedUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchedUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchedUsersHash();

  @$internal
  @override
  $FutureProviderElement<List<UserModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserModel>> create(Ref ref) {
    return searchedUsers(ref);
  }
}

String _$searchedUsersHash() => r'6049b7e9d039a366ef83b8f6ea3818ad541a1478';

@ProviderFor(AdminAction)
final adminActionProvider = AdminActionProvider._();

final class AdminActionProvider
    extends $NotifierProvider<AdminAction, AdminActionState> {
  AdminActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminActionHash();

  @$internal
  @override
  AdminAction create() => AdminAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminActionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminActionState>(value),
    );
  }
}

String _$adminActionHash() => r'59a8099766c0f2b31249f9c17e64422671c1301c';

abstract class _$AdminAction extends $Notifier<AdminActionState> {
  AdminActionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminActionState, AdminActionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminActionState, AdminActionState>,
              AdminActionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
