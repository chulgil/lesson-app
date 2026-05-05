import '../../domain/entities/notification.dart';

class NotificationNavigationTarget {
  const NotificationNavigationTarget({required this.location, this.extra});

  final String location;
  final Object? extra;
}

NotificationNavigationTarget? resolveNotificationNavigationTarget(
  AppNotification notification, {
  required String viewerRole,
}) {
  final actionUrl = notification.actionUrl;
  if (actionUrl == null || actionUrl.isEmpty) return null;

  if (_shouldCarryViewerRole(actionUrl, notification.type)) {
    return NotificationNavigationTarget(
      location: actionUrl,
      extra: {'viewerRole': viewerRole},
    );
  }

  return NotificationNavigationTarget(location: actionUrl);
}

bool _shouldCarryViewerRole(String actionUrl, NotificationType type) {
  if (actionUrl.startsWith('/subscriptions/')) return true;
  if (actionUrl.startsWith('/schedule/request/')) return true;

  return switch (type) {
    NotificationType.scheduleChangeRequested ||
    NotificationType.scheduleChangeApproved ||
    NotificationType.scheduleChangeRejected ||
    NotificationType.scheduleChangeAlternative ||
    NotificationType.subscriptionExpiringSoon ||
    NotificationType.subscriptionExpired ||
    NotificationType.paymentReceived ||
    NotificationType.paymentRequested ||
    NotificationType.paymentReminder ||
    NotificationType.paymentConfirmed => true,
    _ => false,
  };
}
