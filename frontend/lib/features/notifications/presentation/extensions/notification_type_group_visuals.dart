import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/notification_type_group.dart';

/// Presentation-only display label for [NotificationTypeGroup].
///
/// SSOT: docs/specs/notification/push_notification_settings_spec.md Phase 2
/// addendum (#1272 §2 IA). Kept out of the domain enum per
/// flutter-architecture.md (no `label` getter on domain types).
extension NotificationTypeGroupVisuals on NotificationTypeGroup {
  String get label => switch (this) {
    NotificationTypeGroup.lessonReminder => AppStrings.notifGroupLessonReminder,
    NotificationTypeGroup.lessonStarting => AppStrings.notifGroupLessonStarting,
    NotificationTypeGroup.lessonCancelChange =>
      AppStrings.notifGroupLessonCancelChange,
    NotificationTypeGroup.lessonCompletedNote =>
      AppStrings.notifGroupLessonCompletedNote,
    NotificationTypeGroup.scheduleChange => AppStrings.notifGroupScheduleChange,
    NotificationTypeGroup.makeupAndAllowance =>
      AppStrings.notifGroupMakeupAndAllowance,
    NotificationTypeGroup.paymentPending => AppStrings.notifGroupPaymentPending,
    NotificationTypeGroup.subscriptionExpiry =>
      AppStrings.notifGroupSubscriptionExpiry,
    NotificationTypeGroup.proposalReminder =>
      AppStrings.notifGroupProposalReminder,
    NotificationTypeGroup.refundProgress =>
      AppStrings.notifGroupRefundProgress,
    NotificationTypeGroup.connectionRequest =>
      AppStrings.notifGroupConnectionRequest,
    NotificationTypeGroup.connectionDisconnect =>
      AppStrings.notifGroupConnectionDisconnect,
    NotificationTypeGroup.generalAnnouncement =>
      AppStrings.notifGroupGeneralAnnouncement,
    NotificationTypeGroup.practiceReminder =>
      AppStrings.notifGroupPracticeReminder,
    NotificationTypeGroup.streakAndGoal => AppStrings.notifGroupStreakAndGoal,
    NotificationTypeGroup.recordingFeedback =>
      AppStrings.notifGroupRecordingFeedback,
  };
}
