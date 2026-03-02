import '../entities/notification.dart';

/// Repository interface for app notifications.
abstract class NotificationRepository {
  /// Get notifications for the current user.
  Future<List<AppNotification>> getNotifications();

  /// Mark a single notification as read.
  Future<void> markAsRead(String id);

  /// Mark all notifications as read.
  Future<void> markAllAsRead();

  /// Get unread notification count.
  Future<int> getUnreadCount();
}
