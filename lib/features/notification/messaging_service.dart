import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:merokotha/features/notification/notification_service.dart';

/// Data keys carried by a chat push. Must stay in sync with
/// `functions/index.js` (`onMessageCreated`).
class PushKeys {
  static const type = 'type';
  static const chatId = 'chatId';
  static const messageId = 'messageId';
  static const senderName = 'senderName';
  static const senderId = 'senderId';
  static const listingTitle = 'listingTitle';

  /// `chat_message` — the only type this client acts on.
  static const chatMessage = 'chat_message';
}

/// A chat the user asked to open by tapping a notification.
class ChatNotificationPayload {
  final String chatId;
  final String? messageId;
  final String senderName;
  final String? listingTitle;

  const ChatNotificationPayload({
    required this.chatId,
    required this.senderName,
    this.messageId,
    this.listingTitle,
  });

  static ChatNotificationPayload? fromRemoteMessage(RemoteMessage? m) {
    final data = m?.data;
    if (data == null) return null;
    final chatId = data[PushKeys.chatId];
    if (chatId == null || chatId.isEmpty) return null;
    if (data[PushKeys.type] != PushKeys.chatMessage) return null;

    return ChatNotificationPayload(
      chatId: chatId,
      messageId: data[PushKeys.messageId],
      senderName:
          data[PushKeys.senderName] ?? m?.notification?.title ?? 'New message',
      listingTitle: data[PushKeys.listingTitle],
    );
  }
}

/// Firebase Cloud Messaging plumbing.
///
/// Handles the three delivery contexts:
///   * foreground — [FirebaseMessaging.onMessage] → local notification
///   * background / terminated — the OS displays the notification itself
///     (Cloud Functions send a `notification` payload), and the tap arrives
///     via [getInitialMessage] (terminated) or `onMessageOpenedApp`.
///
/// Everything here is deliberately free of Riverpod and navigation concerns;
/// `notification_providers.dart` wires it to auth and the router.
class MessagingService {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final _openRequests = StreamController<ChatNotificationPayload>.broadcast();

  final List<StreamSubscription<dynamic>> _subs = [];

  bool _started = false;

  /// Emits whenever a notification tap asks the app to open a conversation.
  Stream<ChatNotificationPayload> get onOpenChatRequest => _openRequests.stream;

  /// Conversation currently on screen. Notifications for it are suppressed.
  String? activeChatId;

  /// Background / terminated isolate entry point. The OS has already displayed
  /// the notification (the payload carries a `notification` block); this hook
  /// exists so the isolate is warmed and the payload is traceable.
  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    developer.log(
      'FCM background message: ${message.messageId}',
      name: 'merokotha.push',
    );
  }

  /// Start foreground handling and request the notification permission.
  /// Safe to call more than once; subsequent calls are no-ops.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final messaging = FirebaseMessaging.instance;

    _subs.add(FirebaseMessaging.onMessage.listen(_onForegroundMessage));

    _subs.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _emitOpenRequest(message);
      }),
    );

    // Taps on foreground local notifications (shown via
    // flutter_local_notifications) carry no RemoteMessage, so they arrive
    // through NotificationService instead. Route them identically.
    _subs.add(
      NotificationService().onChatOpened.listen((chatId) {
        if (_openRequests.isClosed) return;
        _openRequests.add(
          ChatNotificationPayload(chatId: chatId, senderName: 'New message'),
        );
      }),
    );

    // Tap on a notification that cold-started the app.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _emitOpenRequest(initial);

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    developer.log(
      'FCM permission: ${settings.authorizationStatus}',
      name: 'merokotha.push',
    );
  }

  void stop() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _started = false;
    activeChatId = null;
  }

  /// Register/refresh this device's token. Returns the token, or null if the
  /// platform declined (web, emulator without Play Services, denied).
  Future<String?> deviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      developer.log('FCM getToken failed: $e', name: 'merokotha.push');
      return null;
    }
  }

  /// Fires on every token rotation — the old token must be dropped server-side.
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final payload = ChatNotificationPayload.fromRemoteMessage(message);
    if (payload == null) return;

    // Do not notify about a conversation the user is already reading.
    if (activeChatId == payload.chatId) return;

    await NotificationService().showChatMessage(
      senderName: payload.senderName,
      message: message.notification?.body ?? message.data['body'] ?? '',
      chatId: payload.chatId,
    );
  }

  void _emitOpenRequest(RemoteMessage message) {
    final payload = ChatNotificationPayload.fromRemoteMessage(message);
    if (payload == null) return;
    if (_openRequests.isClosed) return;
    _openRequests.add(payload);
  }
}

/// Top-level background isolate handler referenced from `main.dart`.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    MessagingService.backgroundHandler(message);
