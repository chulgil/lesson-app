import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../entities/notification.dart';
import 'notification_service.dart';

/// Top-level handler for background FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are automatically shown as system notifications
  // by Firebase Messaging on both iOS and Android.
  // No additional handling needed here unless custom processing is required.
}

/// FCM push notification service.
/// Manages device token registration, foreground/background message handling,
/// and bridges FCM messages to the local notification system.
class FcmService {
  FcmService({
    required this.localNotificationService,
    required this.apiClient,
  });

  final LocalNotificationService localNotificationService;
  final ApiClient apiClient;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final StreamController<AppNotification> _foregroundMessageController =
      StreamController<AppNotification>.broadcast();

  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  /// Stream of foreground notifications for UI updates.
  Stream<AppNotification> get onForegroundMessage =>
      _foregroundMessageController.stream;

  /// Current FCM device token.
  String? get currentToken => _currentToken;

  /// Initialize FCM: request permission, get token, set up listeners.
  Future<void> initialize() async {
    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // Get and register device token
    _currentToken = await _messaging.getToken();
    if (_currentToken != null) {
      await _registerToken(_currentToken!);
    }

    // Listen for token refresh
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if the app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Register device token with the backend.
  Future<void> _registerToken(String token) async {
    _currentToken = token;

    if (EnvironmentConfig.useMockData) return;

    try {
      await apiClient.post('/device-tokens', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (_) {
      // Token registration failure is non-blocking
    }
  }

  /// Handle foreground FCM message: show local notification + emit to stream.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = _convertToAppNotification(message);
    if (notification == null) return;

    // Show local notification for foreground messages
    localNotificationService.showNotification(notification);

    // Emit to stream for UI updates
    _foregroundMessageController.add(notification);
  }

  /// Handle notification tap from background/terminated state.
  void _handleMessageOpenedApp(RemoteMessage message) {
    final notification = _convertToAppNotification(message);
    if (notification == null) return;

    // The notification tap stream in LocalNotificationService handles navigation
    // For FCM-opened messages, we emit to the same stream
    _foregroundMessageController.add(notification);
  }

  /// Convert FCM RemoteMessage to AppNotification.
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
        data: data.containsKey('extra')
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

  /// Unregister device token from the backend (e.g., on logout).
  Future<void> unregisterToken() async {
    if (_currentToken == null) return;

    if (!EnvironmentConfig.useMockData) {
      try {
        await apiClient.delete('/device-tokens/$_currentToken');
      } catch (_) {
        // Non-blocking
      }
    }

    _currentToken = null;
  }

  /// Subscribe to a topic (e.g., 'teacher_123' for teacher-specific notifications).
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Clean up resources.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _foregroundMessageController.close();
  }
}
