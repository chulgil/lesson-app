import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../models/notification_settings.dart';
import '../../../../services/notification/notification_service.dart';
import '../../../../services/notification/practice_reminder_scheduler.dart';

part 'notification_providers.g.dart';

/// Provider for the notification service
@riverpod
LocalNotificationService notificationService(Ref ref) {
  final service = LocalNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider for practice reminder scheduler
@riverpod
PracticeReminderScheduler practiceReminderScheduler(Ref ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return PracticeReminderScheduler(notificationService);
}

/// Provider for student notification settings
/// TODO: Load from Hive storage
@riverpod
class StudentNotificationSettingsNotifier extends _$StudentNotificationSettingsNotifier {
  @override
  StudentNotificationSettings build() {
    // Return default settings for now
    // TODO: Load from storage based on current user
    return StudentNotificationSettings.defaultSettings;
  }

  void updateSettings(StudentNotificationSettings newSettings) {
    state = newSettings;
    // TODO: Save to storage
  }

  void toggleLessonReminder(bool enabled) {
    state = state.copyWith(lessonReminderEnabled: enabled);
  }

  void togglePracticeReminder(bool enabled) {
    state = state.copyWith(practiceReminderEnabled: enabled);
  }

  void toggleStreakWarning(bool enabled) {
    state = state.copyWith(streakWarningEnabled: enabled);
  }

  void setPracticeReminderTime(int hour, int minute) {
    state = state.copyWith(
      practiceReminderTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  void setStreakWarningTime(int hour, int minute) {
    state = state.copyWith(
      streakWarningTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  void toggleDnd(bool enabled) {
    state = state.copyWith(dndEnabled: enabled);
  }

  void setDndTimes({int? startHour, int? startMinute, int? endHour, int? endMinute}) {
    state = state.copyWith(
      dndStart: TimeOfDay(
        hour: startHour ?? state.dndStart.hour,
        minute: startMinute ?? state.dndStart.minute,
      ),
      dndEnd: TimeOfDay(
        hour: endHour ?? state.dndEnd.hour,
        minute: endMinute ?? state.dndEnd.minute,
      ),
    );
  }
}

/// Provider for teacher notification settings
/// TODO: Load from Hive storage
@riverpod
class TeacherNotificationSettingsNotifier extends _$TeacherNotificationSettingsNotifier {
  @override
  TeacherNotificationSettings build() {
    // Return default settings for now
    // TODO: Load from storage based on current user
    return TeacherNotificationSettings.defaultSettings;
  }

  void updateSettings(TeacherNotificationSettings newSettings) {
    state = newSettings;
    // TODO: Save to storage
  }

  void toggleLessonReminder(bool enabled) {
    state = state.copyWith(lessonReminderEnabled: enabled);
  }

  void toggleNewStudentAlert(bool enabled) {
    state = state.copyWith(newStudentAlert: enabled);
  }

  void toggleTrialBookingAlert(bool enabled) {
    state = state.copyWith(trialBookingAlert: enabled);
  }

  void togglePaymentReceivedAlert(bool enabled) {
    state = state.copyWith(paymentReceivedAlert: enabled);
  }

  void toggleStudentPracticeReport(bool enabled) {
    state = state.copyWith(studentPracticeReport: enabled);
  }

  void toggleReviewReceivedAlert(bool enabled) {
    state = state.copyWith(reviewReceivedAlert: enabled);
  }

  void toggleDnd(bool enabled) {
    state = state.copyWith(dndEnabled: enabled);
  }
}
