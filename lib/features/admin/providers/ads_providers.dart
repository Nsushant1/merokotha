import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/shared/models/ad_model.dart';
import 'package:merokotha/features/admin/data/ads_repository.dart';

part 'ads_providers.g.dart';

/// Public banner feed for a placement slot: 'landing' | 'home'.
@riverpod
Stream<List<AdModel>> activeAds(Ref ref, String slot) {
  return ref.watch(adsRepositoryProvider).watchActiveAds(slot);
}

@riverpod
Stream<List<AdModel>> allAds(Ref ref) {
  return ref.watch(adsRepositoryProvider).watchAllAds();
}

class AdsActionState {
  final bool isLoading;
  final String? error;
  final bool success;

  const AdsActionState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  AdsActionState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool clearError = false,
  }) => AdsActionState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    success: success ?? this.success,
  );
}

@riverpod
class AdsAction extends _$AdsAction {
  @override
  AdsActionState build() => const AdsActionState();

  Future<String?> create(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = await ref.read(adsRepositoryProvider).createAd(data);
      state = state.copyWith(isLoading: false, success: true);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(adsRepositoryProvider).updateAd(id, data);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleStatus(String id, bool makeActive) async {
    try {
      await ref
          .read(adsRepositoryProvider)
          .setAdStatus(id, makeActive ? 'active' : 'paused');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(adsRepositoryProvider).deleteAd(id);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const AdsActionState();
}
