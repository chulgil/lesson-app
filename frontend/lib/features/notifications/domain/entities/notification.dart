// Notification domain entity
// Moved from lib/models/notification.dart for Clean Architecture

/// Notification type enumeration
enum NotificationType {
  // Lesson notifications
  lessonBooked,
  lessonReminder,
  lessonCancelled,
  lessonRescheduled,
  lessonStarting,
  lessonCompleted,
  lessonNoteShared,

  // Practice notifications
  practiceReminder,
  streakWarning,
  streakMilestone,
  practiceAssigned,
  weeklyGoalAchieved,

  // Payment notifications
  paymentRequested,
  paymentReminder,
  paymentReceived,
  paymentConfirmed,
  lessonsRunningLow,

  // No-show / cancellation notifications
  noshowWarning,
  noshowConfirmed,
  teacherNoshow,
  compensationApplied,
  cancellationDeadline,

  // Management notifications (for teachers)
  newStudentRegistered,
  trialBookingRequest,
  studentPracticeReport,
  reviewReceived,

  // Connection/Invite notifications
  connectionRequestReceived,
  connectionRequestAccepted,
  connectionRequestRejected,
  connectionEstablished,
  connectionDisconnected,

  // Makeup lesson notifications
  makeupLessonCreated,
  makeupLessonExpiring,
  makeupLessonExpired,

  // Schedule change notifications
  scheduleChangeRequested,
  scheduleChangeApproved,
  scheduleChangeRejected,
  scheduleChangeAlternative,

  // Subscription proposal notifications
  proposalReceived, // New proposal from teacher
  proposalReminder24h, // 24h reminder
  proposalReminder48h, // 48h reminder
  proposalReminder72h, // 72h final reminder (golden time ending)
  proposalAccepted, // Student accepted proposal
  proposalExpired, // Proposal expired without action

  // Subscription expiry notifications
  subscriptionExpiringSoon, // D-7/D-3/D-1 before expiry
  subscriptionExpired, // Subscription has expired

  // Reschedule allowance notifications
  rescheduleAllowanceUsed, // Student used reschedule allowance
  rescheduleAllowanceDepleted, // All reschedule allowances used
}

/// Notification priority levels
enum NotificationPriority {
  low, // Informational (achievements, reports)
  normal, // Regular (reminders)
  high, // Important (payments, cancellations)
  urgent, // Critical (no-show, lesson starting)
}

/// Extension for NotificationType to get additional info
extension NotificationTypeExtension on NotificationType {
  /// Get default priority for this notification type
  NotificationPriority get defaultPriority {
    switch (this) {
      case NotificationType.lessonStarting:
      case NotificationType.noshowWarning:
      case NotificationType.noshowConfirmed:
        return NotificationPriority.urgent;

      case NotificationType.lessonCancelled:
      case NotificationType.lessonRescheduled:
      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
      case NotificationType.cancellationDeadline:
      case NotificationType.connectionRequestReceived:
      case NotificationType.connectionRequestAccepted:
      case NotificationType.connectionEstablished:
      case NotificationType.scheduleChangeRequested:
      case NotificationType.proposalReceived:
      case NotificationType.proposalReminder72h: // Golden time ending
      case NotificationType.subscriptionExpiringSoon:
      case NotificationType.subscriptionExpired:
        return NotificationPriority.high;

      case NotificationType.streakMilestone:
      case NotificationType.weeklyGoalAchieved:
      case NotificationType.lessonCompleted:
      case NotificationType.studentPracticeReport:
      case NotificationType.connectionRequestRejected:
      case NotificationType.connectionDisconnected:
      case NotificationType.makeupLessonExpired:
        return NotificationPriority.low;

      default:
        return NotificationPriority.normal;
    }
  }

  /// Whether this notification should bypass DND
  bool get bypassDnd {
    switch (this) {
      case NotificationType.lessonStarting:
      case NotificationType.lessonCancelled:
      case NotificationType.lessonRescheduled:
      case NotificationType.noshowWarning:
      case NotificationType.noshowConfirmed:
        return true;
      default:
        return false;
    }
  }

  /// Whether this notification should be sent as push
  bool get shouldPush {
    switch (this) {
      case NotificationType.lessonCompleted:
      case NotificationType.studentPracticeReport:
        return false;
      default:
        return true;
    }
  }

  /// Whether this notification should appear in app notification center
  bool get shouldShowInApp => true;
}

/// App notification entity
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? readAt;
  final bool isPush;
  final bool isInApp;

  /// 알림 탭 시 이동할 딥링크 URL (예: /lesson-booking?teacherId=xxx)
  final String? actionUrl;

  /// 액션 버튼 텍스트 (예: "레슨 예약하기")
  final String? actionLabel;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.readAt,
    this.isPush = true,
    this.isInApp = true,
    this.actionUrl,
    this.actionLabel,
  });

  bool get isRead => readAt != null;
  bool get isSent => sentAt != null;
  bool get isScheduled => scheduledAt != null && scheduledAt!.isAfter(DateTime.now());

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? readAt,
    bool? isPush,
    bool? isInApp,
    String? actionUrl,
    String? actionLabel,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      isPush: isPush ?? this.isPush,
      isInApp: isInApp ?? this.isInApp,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }
}

/// Notification template for generating notifications
class NotificationTemplate {
  final NotificationType type;
  final String titleTemplate;
  final String bodyTemplate;
  final NotificationPriority priority;
  final bool bypassDnd;

  const NotificationTemplate({
    required this.type,
    required this.titleTemplate,
    required this.bodyTemplate,
    required this.priority,
    this.bypassDnd = false,
  });

  /// Generate notification title with placeholders replaced
  String generateTitle(Map<String, String> params) {
    var result = titleTemplate;
    params.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  /// Generate notification body with placeholders replaced
  String generateBody(Map<String, String> params) {
    var result = bodyTemplate;
    params.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }
}

/// Default notification templates
const Map<NotificationType, NotificationTemplate> notificationTemplates = {
  NotificationType.lessonReminder: NotificationTemplate(
    type: NotificationType.lessonReminder,
    titleTemplate: 'Lesson Reminder',
    bodyTemplate: '{{when}} lesson with {{teacherName}}',
    priority: NotificationPriority.normal,
  ),
  NotificationType.practiceReminder: NotificationTemplate(
    type: NotificationType.practiceReminder,
    titleTemplate: 'Practice Time!',
    bodyTemplate: 'Time to practice today',
    priority: NotificationPriority.normal,
  ),
  NotificationType.streakWarning: NotificationTemplate(
    type: NotificationType.streakWarning,
    titleTemplate: 'Streak Warning!',
    bodyTemplate: 'Practice today to reach {{streakDays}} day streak!',
    priority: NotificationPriority.normal,
  ),
  NotificationType.streakMilestone: NotificationTemplate(
    type: NotificationType.streakMilestone,
    titleTemplate: 'Streak Achievement!',
    bodyTemplate: '{{streakDays}} day streak! Great job!',
    priority: NotificationPriority.low,
  ),
  NotificationType.lessonStarting: NotificationTemplate(
    type: NotificationType.lessonStarting,
    titleTemplate: 'Lesson Starting',
    bodyTemplate: 'Lesson with {{teacherName}} is about to start',
    priority: NotificationPriority.urgent,
    bypassDnd: true,
  ),
  NotificationType.practiceAssigned: NotificationTemplate(
    type: NotificationType.practiceAssigned,
    titleTemplate: 'New Practice Assignment',
    bodyTemplate: '{{teacherName}} assigned new practice items',
    priority: NotificationPriority.normal,
  ),
  // Connection notifications
  NotificationType.connectionRequestReceived: NotificationTemplate(
    type: NotificationType.connectionRequestReceived,
    titleTemplate: '🔗 새 연결 요청',
    bodyTemplate: '{{userName}}님이 연결을 요청했습니다',
    priority: NotificationPriority.high,
  ),
  NotificationType.connectionRequestAccepted: NotificationTemplate(
    type: NotificationType.connectionRequestAccepted,
    titleTemplate: '✅ 연결 완료',
    bodyTemplate: '{{userName}}님과 연결되었습니다! 지금 체험레슨을 예약해보세요.',
    priority: NotificationPriority.high,
  ),
  NotificationType.connectionEstablished: NotificationTemplate(
    type: NotificationType.connectionEstablished,
    titleTemplate: '🎉 새 학생 연결',
    bodyTemplate: '{{userName}}님과 연결되었습니다',
    priority: NotificationPriority.high,
  ),
  // Makeup lesson notifications
  NotificationType.makeupLessonCreated: NotificationTemplate(
    type: NotificationType.makeupLessonCreated,
    titleTemplate: '🔄 보강 적립',
    bodyTemplate: '보강 1회가 적립되었습니다 ({{reason}})',
    priority: NotificationPriority.normal,
  ),
  NotificationType.makeupLessonExpiring: NotificationTemplate(
    type: NotificationType.makeupLessonExpiring,
    titleTemplate: '⏰ 보강 만료 임박',
    bodyTemplate: '보강 {{count}}회가 {{days}}일 후 만료됩니다',
    priority: NotificationPriority.high,
  ),
  // Schedule change notifications
  NotificationType.scheduleChangeRequested: NotificationTemplate(
    type: NotificationType.scheduleChangeRequested,
    titleTemplate: '🔄 레슨 시간 변경 요청',
    bodyTemplate: '{{userName}}님이 {{change}} 변경을 요청했습니다',
    priority: NotificationPriority.high,
  ),
  NotificationType.scheduleChangeApproved: NotificationTemplate(
    type: NotificationType.scheduleChangeApproved,
    titleTemplate: '✅ 시간 변경 승인',
    bodyTemplate: '레슨 시간이 {{newTime}}으로 변경되었습니다',
    priority: NotificationPriority.high,
  ),
  NotificationType.scheduleChangeAlternative: NotificationTemplate(
    type: NotificationType.scheduleChangeAlternative,
    titleTemplate: '📅 다른 시간 제안',
    bodyTemplate: '{{userName}}님이 다른 시간을 제안했습니다',
    priority: NotificationPriority.normal,
  ),
};
