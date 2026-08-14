import '../entities/notification.dart';
import '../entities/notification_preferences.dart';

/// Maps every [NotificationType] to its user-facing settings category.
///
/// SSOT: docs/specs/notification/push_notification_settings_spec.md §2.1.
/// Kept as an exhaustive switch so adding a new type forces a mapping here.
extension NotificationTypeCategory on NotificationType {
  NotificationCategory get category {
    switch (this) {
      case NotificationType.lessonBooked:
      case NotificationType.lessonReminder:
      case NotificationType.lessonCancelled:
      case NotificationType.lessonRescheduled:
      case NotificationType.lessonStarting:
      case NotificationType.lessonCompleted:
      case NotificationType.lessonNoteShared:
      case NotificationType.noshowWarning:
      case NotificationType.noshowConfirmed:
      case NotificationType.teacherNoshow:
      case NotificationType.compensationApplied:
      case NotificationType.cancellationDeadline:
        return NotificationCategory.lesson;

      case NotificationType.scheduleChangeRequested:
      case NotificationType.scheduleChangeApproved:
      case NotificationType.scheduleChangeRejected:
      case NotificationType.scheduleChangeAlternative:
      case NotificationType.makeupLessonCreated:
      case NotificationType.makeupLessonExpiring:
      case NotificationType.makeupLessonExpired:
      case NotificationType.rescheduleAllowanceUsed:
      case NotificationType.rescheduleAllowanceDepleted:
      case NotificationType.scheduleConfirmationRequired:
        return NotificationCategory.schedule;

      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
      case NotificationType.paymentReceived:
      case NotificationType.paymentConfirmed:
      case NotificationType.lessonsRunningLow:
      case NotificationType.subscriptionExpiringSoon:
      case NotificationType.subscriptionExpired:
      case NotificationType.proposalReceived:
      case NotificationType.proposalReminder24h:
      case NotificationType.proposalReminder48h:
      case NotificationType.proposalReminder72h:
      case NotificationType.proposalAccepted:
      case NotificationType.proposalExpired:
      case NotificationType.paymentReminderSentNotice:
      case NotificationType.renewalReminderSentNotice:
      case NotificationType.paymentPendingD1:
      case NotificationType.paymentPendingD3:
      case NotificationType.paymentPendingD7Final:
      case NotificationType.refundRequested:
      case NotificationType.refundCompleted:
      case NotificationType.refundRejected:
        return NotificationCategory.subscription;

      case NotificationType.newStudentRegistered:
      case NotificationType.trialBookingRequest:
      case NotificationType.lessonRequestReceived:
      case NotificationType.reviewReceived:
      case NotificationType.connectionRequestReceived:
      case NotificationType.connectionRequestAccepted:
      case NotificationType.connectionRequestRejected:
      case NotificationType.connectionEstablished:
      case NotificationType.connectionDisconnected:
      case NotificationType.generalAnnouncement:
      case NotificationType.studentPracticeReport:
      case NotificationType.profileReminder24h:
      case NotificationType.profileReminder3d:
      case NotificationType.profileReminder7d:
        return NotificationCategory.announcement;

      case NotificationType.practiceReminder:
      case NotificationType.practiceAssigned:
      case NotificationType.streakWarning:
      case NotificationType.streakMilestone:
      case NotificationType.weeklyGoalAchieved:
      case NotificationType.recordingFeedbackReceived:
        return NotificationCategory.practice;
    }
  }
}

/// Pure delivery decision for the local notification dispatch chokepoint.
///
/// Precedence (push_notification_settings_spec.md §2.2, §3):
/// 1. Master kill switch off — never deliver.
/// 2. Critical types ([NotificationTypeExtension.bypassDnd]) — always deliver,
///    even when their category toggle is off or quiet hours are active.
/// 3. Category toggle off — drop.
/// 4. Inside the quiet-hours window — drop.
bool shouldDeliverNotification(
  NotificationPreferences prefs,
  AppNotification notification, {
  DateTime? now,
}) {
  if (!prefs.masterEnabled) return false;
  final type = notification.type;
  if (type.bypassDnd) return true;
  if (!prefs.isCategoryEnabled(type.category)) return false;
  if (prefs.isInDndAt(now ?? DateTime.now())) return false;
  return true;
}
