// Subscription proposal notification service
// Handles notifications for subscription proposal events

import '../../domain/entities/notification.dart';
import '../../../../services/notification/notification_service.dart';
import '../../../../core/router/app_routes.dart';

/// Service for sending subscription proposal notifications
///
/// Notifications sent:
/// - proposalReceived: Teacher creates proposal → Student receives
/// - proposalAccepted: Student accepts/pays → Teacher receives
/// - proposalReminder: Auto-reminders at 24h, 48h, 72h
class ProposalNotificationService {
  final NotificationService _notificationService;

  ProposalNotificationService(this._notificationService);

  /// Send notification when teacher creates a proposal
  ///
  /// [studentId] - Student who receives the proposal
  /// [teacherName] - Name of the teacher
  /// [proposalId] - Proposal ID for navigation
  /// [templateName] - Name of the subscription template
  /// [isMultiChoice] - Whether student can choose from multiple options
  Future<void> sendProposalReceivedNotification({
    required String studentId,
    required String teacherName,
    required String proposalId,
    required String templateName,
    bool isMultiChoice = false,
  }) async {
    try {
      final notification = AppNotification(
        id: 'proposal_received_${DateTime.now().millisecondsSinceEpoch}',
        userId: studentId,
        type: NotificationType.proposalReceived,
        priority: NotificationPriority.high,
        title: '🎫 수강권 제안',
        body: isMultiChoice
            ? '$teacherName 선생님이 수강권을 제안했습니다. 옵션을 선택해주세요!'
            : '$teacherName 선생님이 $templateName 수강권을 제안했습니다.',
        createdAt: DateTime.now(),
        actionUrl: '${AppRoutes.proposalDetail}?proposalId=$proposalId',
        actionLabel: '제안 보기',
        data: {
          'proposalId': proposalId,
          'teacherName': teacherName,
          'templateName': templateName,
          'isMultiChoice': isMultiChoice,
        },
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  /// Send notification when student notifies payment (accepts proposal)
  ///
  /// [teacherId] - Teacher who receives the notification
  /// [studentName] - Name of the student
  /// [proposalId] - Proposal ID
  /// [templateName] - Name of the selected template
  Future<void> sendPaymentNotifiedNotification({
    required String teacherId,
    required String studentName,
    required String proposalId,
    required String templateName,
  }) async {
    try {
      final notification = AppNotification(
        id: 'payment_notified_${DateTime.now().millisecondsSinceEpoch}',
        userId: teacherId,
        type: NotificationType.paymentReceived,
        priority: NotificationPriority.high,
        title: '💰 입금 알림',
        body: '$studentName 학생이 $templateName 수강권 입금 완료를 알렸습니다.',
        createdAt: DateTime.now(),
        actionUrl: '${AppRoutes.proposalConfirm}?teacherId=$teacherId',
        actionLabel: '입금 확인',
        data: {
          'proposalId': proposalId,
          'studentName': studentName,
          'templateName': templateName,
        },
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  /// Send notification when teacher confirms payment and issues subscription
  ///
  /// [studentId] - Student who receives the notification
  /// [teacherName] - Name of the teacher
  /// [templateName] - Name of the subscription
  /// [totalLessons] - Number of lessons in subscription
  Future<void> sendProposalAcceptedNotification({
    required String studentId,
    required String teacherName,
    required String templateName,
    required int totalLessons,
  }) async {
    try {
      final notification = AppNotification(
        id: 'proposal_accepted_${DateTime.now().millisecondsSinceEpoch}',
        userId: studentId,
        type: NotificationType.proposalAccepted,
        priority: NotificationPriority.high,
        title: '✅ 수강권 발급 완료',
        body: '$teacherName 선생님의 $templateName($totalLessons회) 수강권이 발급되었습니다!',
        createdAt: DateTime.now(),
        actionUrl: AppRoutes.myBookings,
        actionLabel: '예약하기',
        data: {
          'teacherName': teacherName,
          'templateName': templateName,
          'totalLessons': totalLessons,
        },
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  /// Send reminder notification to student
  ///
  /// [studentId] - Student who receives the reminder
  /// [teacherName] - Name of the teacher
  /// [proposalId] - Proposal ID
  /// [hoursRemaining] - Hours until proposal expires (24, 48, 72)
  Future<void> sendProposalReminderNotification({
    required String studentId,
    required String teacherName,
    required String proposalId,
    required int hoursRemaining,
  }) async {
    try {
      final NotificationType type;
      final String title;
      final String body;

      switch (hoursRemaining) {
        case 24:
          type = NotificationType.proposalReminder24h;
          title = '💬 수강권 제안 알림';
          body = '$teacherName 선생님의 수강권 제안이 있습니다. 확인해주세요!';
          break;
        case 48:
          type = NotificationType.proposalReminder48h;
          title = '💬 수강권 제안 확인';
          body = '$teacherName 선생님의 수강권 제안을 확인해주세요.';
          break;
        case 72:
          type = NotificationType.proposalReminder72h;
          title = '⏰ 수강권 제안 마감 임박';
          body = '$teacherName 선생님의 수강권 제안이 곧 만료됩니다!';
          break;
        default:
          type = NotificationType.proposalReminder24h;
          title = '💬 수강권 제안 알림';
          body = '$teacherName 선생님의 수강권 제안이 있습니다.';
      }

      final notification = AppNotification(
        id: 'proposal_reminder_${hoursRemaining}h_${DateTime.now().millisecondsSinceEpoch}',
        userId: studentId,
        type: type,
        priority: hoursRemaining == 72
            ? NotificationPriority.high
            : NotificationPriority.normal,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        actionUrl: '${AppRoutes.proposalDetail}?proposalId=$proposalId',
        actionLabel: '제안 확인',
        data: {
          'proposalId': proposalId,
          'teacherName': teacherName,
          'hoursRemaining': hoursRemaining,
        },
      );

      await _notificationService.showNotification(notification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  /// Send notification when proposal expires
  ///
  /// [studentId] - Student who receives the notification
  /// [teacherId] - Teacher who receives the notification
  /// [teacherName] - Name of the teacher (for student)
  /// [studentName] - Name of the student (for teacher)
  Future<void> sendProposalExpiredNotification({
    required String studentId,
    required String teacherId,
    required String teacherName,
    required String studentName,
  }) async {
    try {
      // Notification to student
      final studentNotification = AppNotification(
        id: 'proposal_expired_student_${DateTime.now().millisecondsSinceEpoch}',
        userId: studentId,
        type: NotificationType.proposalExpired,
        priority: NotificationPriority.normal,
        title: '⌛ 수강권 제안 만료',
        body: '$teacherName 선생님의 수강권 제안이 만료되었습니다.',
        createdAt: DateTime.now(),
        data: {
          'teacherName': teacherName,
        },
      );

      await _notificationService.showNotification(studentNotification);

      // Notification to teacher
      final teacherNotification = AppNotification(
        id: 'proposal_expired_teacher_${DateTime.now().millisecondsSinceEpoch}',
        userId: teacherId,
        type: NotificationType.proposalExpired,
        priority: NotificationPriority.low,
        title: '⌛ 수강권 제안 만료',
        body: '$studentName 학생에게 보낸 수강권 제안이 만료되었습니다.',
        createdAt: DateTime.now(),
        data: {
          'studentName': studentName,
        },
      );

      await _notificationService.showNotification(teacherNotification);
    } catch (_) {
      // Silently ignore notification errors
    }
  }
}
