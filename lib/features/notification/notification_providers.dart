import 'dart:async';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/router/app_router.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/notification/messaging_service.dart';

part 'notification_providers.g.dart';

/// Bridges [MessagingService] to auth state and navigation.
///
/// Kept alive for the whole session so a notification tap at any point after
/// sign-in can route into the right conversation.
@Riverpod(keepAlive: true)
class NotificationCoordinator extends _$NotificationCoordinator {
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<ChatNotificationPayload>? _openSub;
  String? _uid;
  String? _token;

  @override
  void build() {
    final auth = ref.watch(authStateProvider);
    final uid = auth.value?.uid;

    ref.onDispose(() {
      _tokenRefreshSub?.cancel();
      _openSub?.cancel();
    });

    // Registering the token requires a user doc, so it waits for sign-in.
    if (uid != _uid) {
      _uid = uid;
      unawaited(uid == null ? _onSignOut() : _onSignIn(uid));
    }

    return;
  }

  Future<void> _onSignIn(String uid) async {
    final service = MessagingService.instance;
    await service.start();

    _openSub ??= service.onOpenChatRequest.listen(_openChat);

    final token = await service.deviceToken();
    if (token == null) return;
    _token = token;
    await _saveToken(uid, token);

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = service.onTokenRefresh.listen((fresh) async {
      if (fresh == _token) return;
      final previous = _token;
      _token = fresh;
      await _saveToken(uid, fresh, previousToken: previous);
    });
  }

  Future<void> _saveToken(
    String uid,
    String token, {
    String? previousToken,
  }) async {
    try {
      await ref
          .read(userRepositoryProvider)
          .registerFcmToken(uid, token, previousToken: previousToken);
    } catch (e) {
      // Push simply stays silent for this device; must never break sign-in.
      developer.log('FCM token save failed: $e', name: 'merokotha.push');
    }
  }

  Future<void> _onSignOut() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _token = null;
    // Stop FCM/local-tap listeners so a signed-out device never surfaces the
    // previous account's messages. They are re-registered on next sign-in.
    MessagingService.instance.stop();
  }

  /// Route a notification tap into the conversation it refers to.
  void _openChat(ChatNotificationPayload payload) {
    final uid = _uid;
    if (uid == null) return; // signed out — the tap is meaningless

    try {
      ref
          .read(appRouterProvider)
          .go(AppRoutes.chatThread.replaceAll(':chatId', payload.chatId));
    } catch (e) {
      developer.log('FCM deep link failed: $e', name: 'merokotha.push');
    }
  }

  /// Called by the chat thread so pushes for the open conversation are
  /// suppressed.
  void setActiveChat(String? chatId) {
    MessagingService.instance.activeChatId = chatId;
  }
}
