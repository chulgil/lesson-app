import 'dart:async';

import '../entities/notification.dart';

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

/// Weekly-recurring scheduling surface on top of [NotificationService].
///
/// Separate interface (ISP) so existing [NotificationService] test fakes
/// stay unaffected. [scheduleWeeklyNotification] repeats every week at the
/// weekday+time of the notification's `scheduledAt`.
abstract class RecurringNotificationService implements NotificationService {
  Future<void> scheduleWeeklyNotification(AppNotification notification);
}
