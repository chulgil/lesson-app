// Connection notification service
// Handles notifications for teacher-student connection events

import '../../domain/entities/notification.dart';
import '../../../../features/notifications/domain/services/notification_service.dart';
import '../../../../core/router/app_routes.dart';

/// Service for sending connection-related notifications
///
/// Separates notification logic from provider for:
/// - Reusability across different features
/// - Easier testing
/// - Single responsibility principle
class ConnectionNotificationService {
  final NotificationService _notificationService;

  ConnectionNotificationService(this._notificationService);

  /// Send notification when connection request is received
  Future<void> sendConnectionRequestReceivedNotification({
    required String targetId,
    required String requesterName,
    required String requestId,
  }) async {
    try {
      final notification = AppNotification(
        id: 'conn_request_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetId,
        type: NotificationType.connectionRequestReceived,
        priority: NotificationPriority.high,
        title: '새 연결 요청',
        body: '$requesterName님이 연결을 요청했습니다',
        createdAt: DateTime.now(),
        actionUrl: AppRoutes
            .pendingRequests, // Navigate to invite/requests — where teacher reviews incoming connection requests
        actionLabel: '요청 확인',
        data: {'requestId': requestId, 'requesterName': requesterName},
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  /// Send notification when connection is established (to teacher)
  Future<void> sendConnectionEstablishedNotification({
    required String teacherId,
    required String studentName,
    required String connectionId,
  }) async {
    try {
      final notification = AppNotification(
        id: 'conn_established_${DateTime.now().millisecondsSinceEpoch}',
        userId: teacherId,
        type: NotificationType.connectionEstablished,
        priority: NotificationPriority.high,
        title: '새 학생 연결',
        body: '$studentName님과 연결되었습니다',
        createdAt: DateTime.now(),
        data: {'connectionId': connectionId, 'studentName': studentName},
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }
}
