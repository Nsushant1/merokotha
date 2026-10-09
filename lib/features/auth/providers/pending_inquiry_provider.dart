import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/models/listing_model.dart';

/// Room a logged-out guest tapped "Message Owner" on.
///
/// Set before prompting Google sign-in so that after successful
/// authentication the app can resume the intended action and open the
/// inquiry flow for the same room. Keep-alive (must survive the
/// login/onboarding navigation); cleared when consumed, when the room
/// is left, or on logout — never persisted to the backend.
class PendingInquiryNotifier extends Notifier<ListingModel?> {
  @override
  ListingModel? build() => null;

  void set(ListingModel listing) => state = listing;

  void clear() => state = null;
}

final pendingInquiryProvider =
    NotifierProvider<PendingInquiryNotifier, ListingModel?>(
      PendingInquiryNotifier.new,
    );

/// Signs out and clears session-scoped state only.
///
/// The Firestore user profile (including the saved role) and account
/// data are left untouched so the next sign-in restores them.
Future<void> signOutAndClearSession(WidgetRef ref) async {
  await ref.read(authRepositoryProvider).signOut();
  ref.read(pendingInquiryProvider.notifier).clear();
  ref.invalidate(currentUserProvider);
  ref.invalidate(googleSignInProvider);
}
