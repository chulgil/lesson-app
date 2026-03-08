// Provider for notification settings state management.

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_settings_provider.g.dart';

/// Notification settings state (in-memory for Phase A, Hive persistence planned).
class NotificationSettingsState {
  final bool allNotifications;
  final bool lessonReminder;
  final bool lessonChange;
  final bool subscriptionProposal;
  final bool subscriptionExpiry;
  final bool practiceReminder;
  final bool teacherFeedback;

  const NotificationSettingsState({
    this.allNotifications = true,
    this.lessonReminder = true,
    this.lessonChange = true,
    this.subscriptionProposal = true,
    this.subscriptionExpiry = true,
    this.practiceReminder = true,
    this.teacherFeedback = true,
  });

  NotificationSettingsState copyWith({
    bool? allNotifications,
    bool? lessonReminder,
    bool? lessonChange,
    bool? subscriptionProposal,
    bool? subscriptionExpiry,
    bool? practiceReminder,
    bool? teacherFeedback,
  }) {
    return NotificationSettingsState(
      allNotifications: allNotifications ?? this.allNotifications,
      lessonReminder: lessonReminder ?? this.lessonReminder,
      lessonChange: lessonChange ?? this.lessonChange,
      subscriptionProposal: subscriptionProposal ?? this.subscriptionProposal,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      practiceReminder: practiceReminder ?? this.practiceReminder,
      teacherFeedback: teacherFeedback ?? this.teacherFeedback,
    );
  }
}

@Riverpod(keepAlive: true)
class NotificationSettings extends _$NotificationSettings {
  @override
  NotificationSettingsState build() {
    return const NotificationSettingsState();
  }

  void toggleAll(bool value) {
    state = state.copyWith(allNotifications: value);
  }

  void toggleLessonReminder(bool value) {
    state = state.copyWith(lessonReminder: value);
  }

  void toggleLessonChange(bool value) {
    state = state.copyWith(lessonChange: value);
  }

  void toggleSubscriptionProposal(bool value) {
    state = state.copyWith(subscriptionProposal: value);
  }

  void toggleSubscriptionExpiry(bool value) {
    state = state.copyWith(subscriptionExpiry: value);
  }

  void togglePracticeReminder(bool value) {
    state = state.copyWith(practiceReminder: value);
  }

  void toggleTeacherFeedback(bool value) {
    state = state.copyWith(teacherFeedback: value);
  }
}
