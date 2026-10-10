import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Notification channel IDs ──
  static const String inquiryChannelId = 'inquiries';
  static const String chatChannelId = 'chat_messages';
  static const String generalChannelId = 'general';

  // Retained for source compatibility with older call sites.
  static const String _inquiryChannelId = inquiryChannelId;
  static const String _chatChannelId = chatChannelId;
  static const String _generalChannelId = generalChannelId;

  /// Android notification ids must be a 32-bit int. Chat notifications use a
  /// deterministic id derived from the conversation so that repeated pushes
  /// for the same chat replace one another in the tray instead of stacking up.
  static int chatNotificationId(String chatId) => chatId.hashCode & 0x3FFFFFFF;

  final _chatOpenedController = StreamController<String>.broadcast();

  /// Emits the chat id whenever a foreground local notification is tapped.
  /// Wired into [MessagingService] so foreground taps route exactly like
  /// background / terminated FCM taps.
  Stream<String> get onChatOpened => _chatOpenedController.stream;

  /// Payload prefix carried by foreground chat notifications.
  static String chatPayload(String chatId) => 'chat:$chatId';

  static String? chatIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith('chat:')) return null;
    final id = payload.substring('chat:'.length);
    return id.isEmpty ? null : id;
  }

  // ── Initialize ──
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final chatId = chatIdFromPayload(response.payload);
        if (chatId != null && !_chatOpenedController.isClosed) {
          _chatOpenedController.add(chatId);
        }
      },
    );

    await _createChannels();
  }

  Future<void> _createChannels() async {
    const inquiryChannel = AndroidNotificationChannel(
      _inquiryChannelId,
      'Inquiries',
      description: 'Notifications for new inquiries and status updates',
      importance: Importance.high,
      playSound: true,
    );

    const chatChannel = AndroidNotificationChannel(
      _chatChannelId,
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
    );

    const generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      'General',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(inquiryChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(generalChannel);
  }

  // ── Request permissions ──
  Future<bool> requestPermission() async {
    // Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidResult = await androidPlugin?.requestNotificationsPermission();

    // iOS
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosResult = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidResult ?? iosResult ?? true;
  }

  // ── Show a notification ──
  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    bool tapToNavigate = false,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // Chat notifications hand the tap back to the app so it can route to the
      // conversation; inquiry notices simply open the launcher activity.
      autoCancel: true,
      ongoing: false,
      onlyAlertOnce: channelId == _chatChannelId,
    );

    final details = tapToNavigate
        ? NotificationDetails(
            android: androidDetails,
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              threadIdentifier: 'chat',
            ),
          )
        : NotificationDetails(
            android: androidDetails,
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ────────────────────────────────────────────────────────────────
  // PUBLIC METHODS
  // ────────────────────────────────────────────────────────────────

  // ── Inquiry accepted (shown to customer) ──
  Future<void> showInquiryAccepted({required String listingTitle}) async {
    await _show(
      id: 1002,
      title: 'Inquiry accepted! 🎉',
      body:
          'Your inquiry for "$listingTitle" was accepted. Open the app to chat with the owner.',
      channelId: _inquiryChannelId,
      channelName: 'Inquiries',
    );
  }

  /// Foreground chat push. [chatId] keys the notification so successive
  /// messages from the same conversation replace one another. The payload
  /// carries the conversation so a tap deep-links into it.
  Future<void> showChatMessage({
    required String senderName,
    required String message,
    required String chatId,
    String? listingTitle,
  }) async {
    await _show(
      id: chatNotificationId(chatId),
      title: senderName,
      body: message.trim().isEmpty ? '📷 Photo' : message,
      channelId: _chatChannelId,
      channelName: 'Chat Messages',
      tapToNavigate: true,
      payload: chatPayload(chatId),
    );
  }

  // ── Cancel all notifications ──
  Future<void> cancelAll() async => await _plugin.cancelAll();

  // ── Cancel a specific notification ──
  Future<void> cancel(int id) async => await _plugin.cancel(id);
}
