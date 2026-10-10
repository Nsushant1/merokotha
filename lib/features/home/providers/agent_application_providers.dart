import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/home/data/agent_application_repository.dart';
import 'package:merokotha/shared/models/agent_application_model.dart';

part 'agent_application_providers.g.dart';

/// The signed-in user's own agent application, if any.
@riverpod
Stream<AgentApplicationModel?> myAgentApplication(Ref ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref
      .watch(agentApplicationRepositoryProvider)
      .watchMyApplication(user.uid);
}

/// Any single application by uid (admin review).
@riverpod
Stream<AgentApplicationModel?> agentApplication(Ref ref, String uid) {
  return ref.watch(agentApplicationRepositoryProvider).watchApplication(uid);
}

class AgentApplicationFormState {
  final bool isLoading;
  final String? error;
  final bool success;

  const AgentApplicationFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  AgentApplicationFormState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool clearError = false,
  }) => AgentApplicationFormState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    success: success ?? this.success,
  );
}

/// Files the signed-in user's application. Never grants privileges —
/// approval is an admin decision (see [AgentDecisionNotifier]).
@riverpod
class AgentApplicationFormNotifier extends _$AgentApplicationFormNotifier {
  @override
  AgentApplicationFormState build() => const AgentApplicationFormState();

  Future<bool> submit({
    required String fullName,
    required String phone,
    required String location,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Not signed in.');
        return false;
      }
      await ref
          .read(agentApplicationRepositoryProvider)
          .submitApplication(
            uid: user.id,
            fullName: fullName,
            phone: phone,
            location: location,
            notes: notes,
          );
      state = state.copyWith(isLoading: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit application. Please try again.',
      );
      return false;
    }
  }

  void reset() => state = const AgentApplicationFormState();
}

class AgentDecisionState {
  final bool isLoading;
  final String? error;

  const AgentDecisionState({this.isLoading = false, this.error});

  AgentDecisionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => AgentDecisionState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Admin approve/reject. Writes the verdict and the applicant's
/// `agentStatus` atomically via the repository.
@riverpod
class AgentDecisionNotifier extends _$AgentDecisionNotifier {
  @override
  AgentDecisionState build() => const AgentDecisionState();

  Future<bool> decide({
    required String uid,
    required bool approved,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final admin = await ref.read(currentUserProvider.future);
      if (admin == null) {
        state = state.copyWith(isLoading: false, error: 'Not signed in.');
        return false;
      }
      await ref
          .read(agentApplicationRepositoryProvider)
          .decideApplication(
            uid: uid,
            approved: approved,
            decidedBy: admin.id,
            reason: reason,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save decision. Please try again.',
      );
      return false;
    }
  }
}
