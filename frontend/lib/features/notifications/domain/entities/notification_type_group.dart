/// User-facing sub-groups of [NotificationType], nested under a
/// [NotificationCategory].
///
/// SSOT: docs/specs/notification/push_notification_settings_spec.md (Phase 2
/// addendum, #1272) — every [NotificationType] maps to exactly one group via
/// an exhaustive switch in `notification_delivery_gate.dart`, and every group
/// belongs to exactly one category via the same file.
enum NotificationTypeGroup {
  // lesson category
  lessonReminder,
  lessonStarting,
  lessonCancelChange,
  lessonCompletedNote,

  // schedule category
  scheduleChange,
  makeupAndAllowance,

  // subscription category
  paymentPending,
  subscriptionExpiry,
  proposalReminder,
  refundProgress,

  // announcement category
  connectionRequest,
  connectionDisconnect,
  generalAnnouncement,

  // practice category
  practiceReminder,
  streakAndGoal,
  recordingFeedback,
}
