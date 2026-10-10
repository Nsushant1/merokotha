import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
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
///
/// The device push token IS removed first: otherwise FCM keeps delivering
/// this account's notifications to the device after sign-out (cross-account
/// leak on shared devices). This must run while still authenticated —
/// Firestore rules reject token writes from signed-out callers.
Future<void> signOutAndClearSession(WidgetRef ref) async {
  final uid = ref.read(authStateProvider).value?.uid;
  if (uid != null) {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(userRepositoryProvider).unregisterFcmToken(uid, token);
      }
    } catch (_) {
      // Best-effort: sign-out must never fail because of token cleanup.
    }
    try {
      // Invalidate the local instance ID so the OS token can never be
      // reused for this account. Next sign-in mints a fresh token.
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Best-effort (e.g. no network) — server-side removal above is what
      // stops the fan-out.
    }
  }
  await ref.read(authRepositoryProvider).signOut();
  ref.read(pendingInquiryProvider.notifier).clear();
  ref.invalidate(currentUserProvider);
  ref.invalidate(googleSignInProvider);
}
