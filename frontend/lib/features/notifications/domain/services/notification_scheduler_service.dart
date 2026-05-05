import 'package:flutter/material.dart';

import '../entities/notification.dart';
import 'notification_service.dart';

/// Service for scheduling future notifications.
///
/// Handles:
/// - Scheduling notifications for future delivery
/// - Cancelling scheduled notifications
/// - Managing notification queue
///
/// Note: In production, this would integrate with:
/// - flutter_local_notifications for local scheduling
/// - Firebase Cloud Messaging for push notifications
/// - Backend scheduler for reliable delivery
class NotificationSchedulerService {
  final NotificationService _notificationDelivery;

  // In-memory queue for scheduled notifications (mock implementation)
  // In production, this would be persisted to local storage or backend
  final Map<String, AppNotification> _scheduledNotifications = {};

  NotificationSchedulerService(this._notificationDelivery);

  /// Schedule a notification for future delivery.
  ///
  /// The notification will be delivered at [notification.scheduledAt].
  Future<void> scheduleNotification(AppNotification notification) async {
    if (notification.scheduledAt == null) {
      debugPrint(
        '[NotificationScheduler] Cannot schedule notification without scheduledAt',
      );
      return;
    }

    debugPrint(
      '[NotificationScheduler] Scheduling notification: ${notification.id} '
      'for ${notification.scheduledAt}',
    );

    _scheduledNotifications[notification.id] = notification;

    // Calculate delay
    final delay = notification.scheduledAt!.difference(DateTime.now());

    if (delay.isNegative) {
      // Already past scheduled time - send immediately
      await _deliverNotification(notification);
      return;
    }

    // Schedule for future delivery
    // In production, use flutter_local_notifications or backend scheduler
    Future.delayed(delay, () async {
      // Check if still scheduled (not cancelled)
      if (_scheduledNotifications.containsKey(notification.id)) {
        await _deliverNotification(notification);
      }
    });

    debugPrint(
      '[NotificationScheduler] Notification ${notification.id} scheduled '
      'to deliver in ${delay.inMinutes} minutes',
    );
  }

  /// Cancel a scheduled notification by ID.
  Future<void> cancelNotification(String notificationId) async {
    final removed = _scheduledNotifications.remove(notificationId);
    if (removed != null) {
      debugPrint(
        '[NotificationScheduler] Cancelled notification: $notificationId',
      );
    }
  }

  /// Cancel all scheduled notifications for a proposal.
  Future<void> cancelNotificationsByProposalId(String proposalId) async {
    final toRemove = <String>[];

    for (final entry in _scheduledNotifications.entries) {
      final data = entry.value.data;
      if (data != null && data['proposalId'] == proposalId) {
        toRemove.add(entry.key);
      }
    }

    for (final id in toRemove) {
      _scheduledNotifications.remove(id);
    }

    debugPrint(
      '[NotificationScheduler] Cancelled ${toRemove.length} notifications '
      'for proposal: $proposalId',
    );
  }

  /// Get all scheduled notifications for a user.
  List<AppNotification> getScheduledNotifications(String userId) {
    return _scheduledNotifications.values
        .where((n) => n.userId == userId)
        .toList()
      ..sort(
        (a, b) => (a.scheduledAt ?? DateTime.now()).compareTo(
          b.scheduledAt ?? DateTime.now(),
        ),
      );
  }

  /// Deliver a notification immediately.
  Future<void> _deliverNotification(AppNotification notification) async {
    // Remove from scheduled queue
    _scheduledNotifications.remove(notification.id);

    // Mark as sent
    final sentNotification = notification.copyWith(sentAt: DateTime.now());

    // Deliver via NotificationService
    try {
      await _notificationDelivery.showNotification(sentNotification);
      debugPrint(
        '[NotificationScheduler] Delivered notification: ${notification.id}',
      );
    } catch (e) {
      debugPrint('[NotificationScheduler] Failed to deliver notification: $e');
    }
  }

  /// Get count of pending scheduled notifications.
  int get pendingCount => _scheduledNotifications.length;

  /// Clear all scheduled notifications (for testing/cleanup).
  void clearAll() {
    _scheduledNotifications.clear();
    debugPrint('[NotificationScheduler] Cleared all scheduled notifications');
  }
}
