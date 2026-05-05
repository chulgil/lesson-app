import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification.dart';
import '../../domain/services/notification_service.dart';

/// Top-level handler for background FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are automatically shown as system notifications by FCM.
}

/// FCM push notification adapter.
///
/// Owns Firebase Messaging, device token registration, foreground/background
/// message handling, and bridges FCM messages to the domain notification port.
class FcmService {
  FcmService({
    required this.notificationDelivery,
    required this.apiClient,
    required this.useMockData,
  });

  final NotificationService notificationDelivery;
  final ApiClient apiClient;
  final bool useMockData;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final StreamController<AppNotification> _foregroundMessageController =
      StreamController<AppNotification>.broadcast();

  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  Stream<AppNotification> get onForegroundMessage =>
      _foregroundMessageController.stream;

  String? get currentToken => _currentToken;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    _currentToken = await _messaging.getToken();
    if (_currentToken != null) {
      await _registerToken(_currentToken!);
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _registerToken,
    );
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;

    if (useMockData) return;

    try {
      await apiClient.post(
        '/device-tokens',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (_) {
      // Token registration failure is non-blocking.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = _convertToAppNotification(message);
    if (notification == null) return;

    notificationDelivery.showNotification(notification);
    _foregroundMessageController.add(notification);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final notification = _convertToAppNotification(message);
    if (notification == null) return;

    _foregroundMessageController.add(notification);
  }

  AppNotification? _convertToAppNotification(RemoteMessage message) {
    try {
      final data = message.data;
      final remoteNotification = message.notification;

      return AppNotification(
        id: message.messageId ?? data['notification_id'] ?? '',
        userId: data['user_id'] ?? '',
        type: NotificationType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => NotificationType.lessonReminder,
        ),
        priority: NotificationPriority.values.firstWhere(
          (p) => p.name == data['priority'],
          orElse: () => NotificationPriority.normal,
        ),
        title: remoteNotification?.title ?? data['title'] ?? '',
        body: remoteNotification?.body ?? data['body'] ?? '',
        data:
            data.containsKey('extra')
                ? jsonDecode(data['extra'] as String) as Map<String, dynamic>?
                : null,
        createdAt: DateTime.now(),
        sentAt: DateTime.now(),
        actionUrl: data['action_url'],
        actionLabel: data['action_label'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> unregisterToken() async {
    if (_currentToken == null) return;

    if (!useMockData) {
      try {
        await apiClient.delete('/device-tokens/$_currentToken');
      } catch (_) {
        // Non-blocking.
      }
    }

    _currentToken = null;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _foregroundMessageController.close();
  }
}
