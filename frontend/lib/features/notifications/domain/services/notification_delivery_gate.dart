import '../entities/notification.dart';
import '../entities/notification_preferences.dart';
import '../entities/notification_type_group.dart';

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

/// Maps every [NotificationType] to its user-facing settings group — a
/// finer-grained sub-division nested under [NotificationTypeCategory].
///
/// SSOT: docs/specs/notification/push_notification_settings_spec.md Phase 2
/// addendum (#1272). Kept as an exhaustive switch so adding a new type
/// forces a mapping here.
extension NotificationTypeGroupMapping on NotificationType {
  NotificationTypeGroup get group {
    switch (this) {
      // lesson category
      case NotificationType.lessonBooked:
      case NotificationType.lessonReminder:
        return NotificationTypeGroup.lessonReminder;
      case NotificationType.lessonStarting:
        return NotificationTypeGroup.lessonStarting;
      case NotificationType.lessonCancelled:
      case NotificationType.lessonRescheduled:
      case NotificationType.noshowWarning:
      case NotificationType.noshowConfirmed:
      case NotificationType.teacherNoshow:
      case NotificationType.compensationApplied:
      case NotificationType.cancellationDeadline:
        return NotificationTypeGroup.lessonCancelChange;
      case NotificationType.lessonCompleted:
      case NotificationType.lessonNoteShared:
        return NotificationTypeGroup.lessonCompletedNote;

      // schedule category
      case NotificationType.scheduleChangeRequested:
      case NotificationType.scheduleChangeApproved:
      case NotificationType.scheduleChangeRejected:
      case NotificationType.scheduleChangeAlternative:
      case NotificationType.scheduleConfirmationRequired:
        return NotificationTypeGroup.scheduleChange;
      case NotificationType.makeupLessonCreated:
      case NotificationType.makeupLessonExpiring:
      case NotificationType.makeupLessonExpired:
      case NotificationType.rescheduleAllowanceUsed:
      case NotificationType.rescheduleAllowanceDepleted:
        return NotificationTypeGroup.makeupAndAllowance;

      // subscription category
      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
      case NotificationType.paymentReceived:
      case NotificationType.paymentConfirmed:
      case NotificationType.paymentReminderSentNotice:
      case NotificationType.paymentPendingD1:
      case NotificationType.paymentPendingD3:
      case NotificationType.paymentPendingD7Final:
        return NotificationTypeGroup.paymentPending;
      case NotificationType.lessonsRunningLow:
      case NotificationType.subscriptionExpiringSoon:
      case NotificationType.subscriptionExpired:
        return NotificationTypeGroup.subscriptionExpiry;
      case NotificationType.proposalReceived:
      case NotificationType.proposalReminder24h:
      case NotificationType.proposalReminder48h:
      case NotificationType.proposalReminder72h:
      case NotificationType.proposalAccepted:
      case NotificationType.proposalExpired:
      case NotificationType.renewalReminderSentNotice:
        return NotificationTypeGroup.proposalReminder;

      // announcement category
      case NotificationType.connectionRequestReceived:
      case NotificationType.connectionRequestAccepted:
      case NotificationType.connectionRequestRejected:
      case NotificationType.connectionEstablished:
        return NotificationTypeGroup.connectionRequest;
      case NotificationType.connectionDisconnected:
        return NotificationTypeGroup.connectionDisconnect;
      case NotificationType.newStudentRegistered:
      case NotificationType.trialBookingRequest:
      case NotificationType.lessonRequestReceived:
      case NotificationType.reviewReceived:
      case NotificationType.generalAnnouncement:
      case NotificationType.studentPracticeReport:
      case NotificationType.profileReminder24h:
      case NotificationType.profileReminder3d:
      case NotificationType.profileReminder7d:
        return NotificationTypeGroup.generalAnnouncement;

      // practice category
      case NotificationType.practiceReminder:
      case NotificationType.practiceAssigned:
        return NotificationTypeGroup.practiceReminder;
      case NotificationType.streakWarning:
      case NotificationType.streakMilestone:
      case NotificationType.weeklyGoalAchieved:
        return NotificationTypeGroup.streakAndGoal;
      case NotificationType.recordingFeedbackReceived:
        return NotificationTypeGroup.recordingFeedback;
    }
  }
}

/// Maps every [NotificationTypeGroup] back to its parent
/// [NotificationCategory]. Kept as an exhaustive switch alongside
/// [NotificationTypeGroupMapping] so the two stay in lockstep.
extension NotificationTypeGroupCategory on NotificationTypeGroup {
  NotificationCategory get category {
    switch (this) {
      case NotificationTypeGroup.lessonReminder:
      case NotificationTypeGroup.lessonStarting:
      case NotificationTypeGroup.lessonCancelChange:
      case NotificationTypeGroup.lessonCompletedNote:
        return NotificationCategory.lesson;
      case NotificationTypeGroup.scheduleChange:
      case NotificationTypeGroup.makeupAndAllowance:
        return NotificationCategory.schedule;
      case NotificationTypeGroup.paymentPending:
      case NotificationTypeGroup.subscriptionExpiry:
      case NotificationTypeGroup.proposalReminder:
        return NotificationCategory.subscription;
      case NotificationTypeGroup.connectionRequest:
      case NotificationTypeGroup.connectionDisconnect:
      case NotificationTypeGroup.generalAnnouncement:
        return NotificationCategory.announcement;
      case NotificationTypeGroup.practiceReminder:
      case NotificationTypeGroup.streakAndGoal:
      case NotificationTypeGroup.recordingFeedback:
        return NotificationCategory.practice;
    }
  }
}

/// The ordered list of [NotificationTypeGroup]s nested under this category,
/// for the settings screen's expand section. Empty for categories with no
/// sub-groups (currently `marketing`).
extension NotificationCategoryGroups on NotificationCategory {
  List<NotificationTypeGroup> get groups => NotificationTypeGroup.values
      .where((group) => group.category == this)
      .toList(growable: false);
}

/// Whether [group] is effectively enabled, mirroring the category →
/// group-override precedence [shouldDeliverNotification] applies — minus the
/// quiet-hours check, since this reflects a settings-screen toggle position
/// rather than a single delivery decision.
bool isGroupEffectivelyEnabled(
  NotificationPreferences prefs,
  NotificationTypeGroup group,
) {
  if (!prefs.isCategoryEnabled(group.category)) return false;
  return prefs.groupOverrides[group] ?? true;
}

/// Pure delivery decision for the local notification dispatch chokepoint.
///
/// Precedence (push_notification_settings_spec.md §2.2, §3 + Phase 2
/// addendum #1272 §3):
/// 1. Master kill switch off — never deliver.
/// 2. Critical types ([NotificationTypeExtension.bypassDnd]) — always deliver,
///    even when their category toggle is off or quiet hours are active.
/// 3. Category toggle off — drop (this also silences every group beneath it,
///    regardless of that group's own override).
/// 4. Group override explicitly off — drop. An unset override inherits the
///    category's (already-on) value and falls through.
/// 5. Inside the quiet-hours window — drop.
bool shouldDeliverNotification(
  NotificationPreferences prefs,
  AppNotification notification, {
  DateTime? now,
}) {
  if (!prefs.masterEnabled) return false;
  final type = notification.type;
  if (type.bypassDnd) return true;
  if (!prefs.isCategoryEnabled(type.category)) return false;
  if (prefs.groupOverrides[type.group] == false) return false;
  if (prefs.isInDndAt(now ?? DateTime.now())) return false;
  return true;
}
