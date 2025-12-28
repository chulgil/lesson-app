import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/notification.dart';

/// Abstract notification service interface
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> showNotification(AppNotification notification);
  Future<void> scheduleNotification(AppNotification notification);
  Future<void> cancelNotification(String id);
  Future<void> cancelAllNotifications();
  Stream<AppNotification> get onNotificationTapped;
}

/// Local notification service implementation
/// Uses flutter_local_notifications for local scheduling
/// FCM integration is handled separately when backend is ready
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<AppNotification> _notificationTapController =
      StreamController<AppNotification>.broadcast();

  bool _isInitialized = false;

  @override
  Stream<AppNotification> get onNotificationTapped =>
      _notificationTapController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('LocalNotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Parse payload and emit notification
      debugPrint('Notification tapped: ${response.payload}');
      // TODO: Parse payload to AppNotification and emit
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Request iOS permissions
    final iosPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    // Request Android permissions (Android 13+)
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      return result ?? false;
    }

    return true;
  }

  @override
  Future<void> showNotification(AppNotification notification) async {
    if (!_isInitialized) {
      await initialize();
    }

    final details = _getNotificationDetails(notification);

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _encodePayload(notification),
    );

    debugPrint('Notification shown: ${notification.title}');
  }

  @override
  Future<void> scheduleNotification(AppNotification notification) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (notification.scheduledAt == null) {
      await showNotification(notification);
      return;
    }

    final scheduledDate = tz.TZDateTime.from(notification.scheduledAt!, tz.local);

    // Don't schedule if time has passed
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('Skipping past notification: ${notification.title}');
      return;
    }

    final details = _getNotificationDetails(notification);

    await _localNotifications.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: _encodePayload(notification),
    );

    debugPrint(
      'Notification scheduled: ${notification.title} at ${notification.scheduledAt}',
    );
  }

  @override
  Future<void> cancelNotification(String id) async {
    await _localNotifications.cancel(id.hashCode);
    debugPrint('Notification cancelled: $id');
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  NotificationDetails _getNotificationDetails(AppNotification notification) {
    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: _getImportance(notification.priority),
      priority: _getPriority(notification.priority),
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.practiceReminder:
      case NotificationType.streakWarning:
      case NotificationType.streakMilestone:
        return 'practice_channel';
      case NotificationType.lessonReminder:
      case NotificationType.lessonStarting:
      case NotificationType.lessonCancelled:
        return 'lesson_channel';
      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
        return 'payment_channel';
      default:
        return 'default_channel';
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.practiceReminder:
      case NotificationType.streakWarning:
      case NotificationType.streakMilestone:
        return 'Practice Notifications';
      case NotificationType.lessonReminder:
      case NotificationType.lessonStarting:
      case NotificationType.lessonCancelled:
        return 'Lesson Notifications';
      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
        return 'Payment Notifications';
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.practiceReminder:
      case NotificationType.streakWarning:
      case NotificationType.streakMilestone:
        return 'Notifications for practice reminders and streak updates';
      case NotificationType.lessonReminder:
      case NotificationType.lessonStarting:
      case NotificationType.lessonCancelled:
        return 'Notifications for lesson reminders and updates';
      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
        return 'Notifications for payment requests';
      default:
        return 'General app notifications';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  String _encodePayload(AppNotification notification) {
    // Simple payload encoding - just notification ID and type
    return '${notification.id}|${notification.type.name}';
  }

  void dispose() {
    _notificationTapController.close();
  }
}
