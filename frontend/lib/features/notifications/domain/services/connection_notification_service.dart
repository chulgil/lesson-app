// Connection notification service
// Handles notifications for teacher-student connection events

import '../../domain/entities/notification.dart';
import '../../../../services/notification/notification_service.dart';
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

  /// Send notification when connection request is accepted
  ///
  /// [requesterId] - The user who sent the connection request (receives notification)
  /// [accepterName] - Name of the user who accepted
  /// [connection] - Connection details (teacherId, teacherName, studentId, studentName)
  /// [requesterIsStudent] - Whether the requester is a student
  Future<void> sendConnectionAcceptedNotification({
    required String requesterId,
    required String accepterName,
    required ConnectionInfo connection,
    required bool requesterIsStudent,
  }) async {
    try {
      final notification = AppNotification(
        id: 'conn_accepted_${DateTime.now().millisecondsSinceEpoch}',
        userId: requesterId,
        type: NotificationType.connectionRequestAccepted,
        priority: NotificationPriority.high,
        title: '✅ 연결 완료',
        body: '$accepterName님과 연결되었습니다! 프로필을 확인하고 레슨을 예약해보세요.',
        createdAt: DateTime.now(),
        actionUrl: requesterIsStudent
            ? '${AppRoutes.teacherDetail.replaceFirst(':id', connection.teacherId)}?name=${Uri.encodeComponent(connection.teacherName)}'
            : null,
        actionLabel: requesterIsStudent ? '선생님 보기' : null,
        data: {
          'connectionId': connection.id,
          'teacherId': connection.teacherId,
          'teacherName': connection.teacherName,
          'studentId': connection.studentId,
          'studentName': connection.studentName,
        },
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
      // Connection acceptance should not fail due to notification issues
    }
  }

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
        title: '🔗 새 연결 요청',
        body: '$requesterName님이 연결을 요청했습니다',
        createdAt: DateTime.now(),
        actionUrl: AppRoutes.profile, // Navigate to profile to see pending requests
        actionLabel: '요청 확인',
        data: {
          'requestId': requestId,
          'requesterName': requesterName,
        },
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
        title: '🎉 새 학생 연결',
        body: '$studentName님과 연결되었습니다',
        createdAt: DateTime.now(),
        data: {
          'connectionId': connectionId,
          'studentName': studentName,
        },
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }
}

/// Minimal connection info for notifications
/// Avoids dependency on full Connection entity
class ConnectionInfo {
  final String id;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;

  const ConnectionInfo({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
  });
}
