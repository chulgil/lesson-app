// Subscription refund request notification service (#1271)

import '../../../../core/utils/currency_utils.dart';
import '../entities/notification.dart';
import 'notification_service.dart';

/// Sends notifications for refund request lifecycle events.
///
/// Notifications sent:
/// - refundRequested: Student submits a refund request → Teacher receives
/// - refundCompleted: Teacher completes the refund → Student receives
/// - refundRejected: Teacher rejects the refund → Student receives
class RefundNotificationService {
  final NotificationService _notificationService;

  RefundNotificationService(this._notificationService);

  Future<void> sendRequested({
    required String teacherId,
    required String studentName,
  }) async {
    try {
      final notification = AppNotification(
        id: 'refund_requested_${DateTime.now().millisecondsSinceEpoch}',
        userId: teacherId,
        type: NotificationType.refundRequested,
        priority: NotificationPriority.high,
        title: '환불 요청',
        body: '$studentName 학생이 환불을 요청했습니다.',
        createdAt: DateTime.now(),
        data: {'studentName': studentName},
      );
      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  Future<void> sendCompleted({
    required String studentId,
    required int processedAmount,
  }) async {
    try {
      final notification = AppNotification(
        id: 'refund_completed_${DateTime.now().millisecondsSinceEpoch}',
        userId: studentId,
        type: NotificationType.refundCompleted,
        priority: NotificationPriority.high,
        title: '환불 완료',
        body: '${formatWonWithComma(processedAmount)}이 환불 처리되었습니다.',
        createdAt: DateTime.now(),
        data: {'processedAmount': processedAmount},
      );
      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  Future<void> sendRejected({
    required String studentId,
    required String rejectReason,
  }) async {
    try {
      final notification = AppNotification(
        id: 'refund_rejected_${DateTime.now().millisecondsSinceEpoch}',
        userId: studentId,
        type: NotificationType.refundRejected,
        priority: NotificationPriority.high,
        title: '환불 반려',
        body: '환불 요청이 반려되었습니다. 사유: $rejectReason',
        createdAt: DateTime.now(),
        data: {'rejectReason': rejectReason},
      );
      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }
}
