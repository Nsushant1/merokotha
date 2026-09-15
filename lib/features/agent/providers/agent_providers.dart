import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/features/agent/data/agent_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/owner/data/inquiry_repository.dart';

part 'agent_providers.g.dart';

/// Listings posted by the signed-in agent (via `agentId`), newest first.
@riverpod
Stream<List<ListingModel>> agentListings(Ref ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(agentRepositoryProvider).watchAgentListings(user.uid);
}

/// Pending inquiries on the agent's listings.
/// Works via the shared inquiry repo because agent listings carry
/// `ownerId == agent uid`.
@riverpod
Stream<int> agentPendingInquiryCount(Ref ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value(0);
  return ref.watch(inquiryRepositoryProvider).watchPendingCount(user.uid);
}

class AgentUploadState {
  final bool isLoading;
  final String? error;
  final bool success;

  const AgentUploadState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  AgentUploadState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool clearError = false,
  }) => AgentUploadState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    success: success ?? this.success,
  );
}

@riverpod
class AgentUploadNotifier extends _$AgentUploadNotifier {
  @override
  AgentUploadState build() => const AgentUploadState();

  /// Posts a room on behalf of an owner. Only admin-verified agents may post
  /// (also enforced by Firestore rules); the guard below fails fast in UI.
  Future<String?> uploadAgentListing({
    required String agentId,
    String? agentPhotoUrl,
    required String ownerName,
    required String ownerPhone,
    required String title,
    required String roomType,
    required double rentPerMonth,
    required double depositAmount,
    required int floor,
    required int totalFloors,
    required FurnishingType furnishing,
    required List<String> facilities,
    required String description,
    required DateTime availableFrom,
    GeoPoint? geoPoint,
    String? address,
    String? nearbyLandmarks,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final caller = await ref.read(currentUserProvider.future);
      if (caller?.isVerifiedAgent != true) {
        state = state.copyWith(
          isLoading: false,
          error: 'Only verified agents can post rooms.',
        );
        return null;
      }

      final now = DateTime.now();
      final listing = ListingModel(
        id: '',
        ownerId: agentId,
        ownerName: ownerName,
        agentId: agentId,
        ownerPhone: ownerPhone,
        ownerPhotoUrl: agentPhotoUrl,
        title: title,
        rentPerMonth: rentPerMonth,
        depositAmount: depositAmount,
        floor: floor,
        totalFloors: totalFloors,
        furnishing: furnishing,
        facilities: facilities,
        description: description,
        photoUrls: const [],
        geoPoint: geoPoint,
        address: address,
        nearbyLandmarks: nearbyLandmarks,
        availableFrom: availableFrom,
        status: ListingStatus.active,
        createdAt: now,
        updatedAt: now,
        roomType: roomType,
      );

      final id = await ref
          .read(agentRepositoryProvider)
          .createAgentListing(listing);

      state = state.copyWith(isLoading: false, success: true);
      return id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save listing. Please try again.',
      );
      return null;
    }
  }

  Future<void> updateExistingAgentListing({
    required String listingId,
    required String ownerName,
    required String ownerPhone,
    required String title,
    required String roomType,
    required double rentPerMonth,
    required double depositAmount,
    required int floor,
    required int totalFloors,
    required FurnishingType furnishing,
    required List<String> facilities,
    required String description,
    required DateTime availableFrom,
    GeoPoint? geoPoint,
    String? address,
    String? nearbyLandmarks,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(agentRepositoryProvider).updateAgentListing(listingId, {
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'title': title,
        'roomType': roomType,
        'rentPerMonth': rentPerMonth,
        'depositAmount': depositAmount,
        'floor': floor,
        'totalFloors': totalFloors,
        'furnishing': furnishing.name,
        'facilities': facilities,
        'description': description,
        'availableFrom': Timestamp.fromDate(availableFrom),
        'geoPoint': ?geoPoint,
        'address': ?address,
        'nearbyLandmarks': ?nearbyLandmarks,
      });
      state = state.copyWith(isLoading: false, success: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update listing. Please try again.',
      );
    }
  }

  void reset() => state = const AgentUploadState();
}

@riverpod
class AgentListingStatusNotifier extends _$AgentListingStatusNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> toggle(String listingId, ListingStatus newStatus) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(agentRepositoryProvider)
          .toggleAgentListingStatus(listingId, newStatus),
    );
  }

  Future<void> delete(String listingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(agentRepositoryProvider).deleteAgentListing(listingId),
    );
  }
}
