import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/notifications/domain/entities/notification_settings.dart';
import '../../../../features/notifications/domain/services/notification_service.dart';
import '../../../../features/notifications/domain/services/practice_reminder_scheduler.dart';
import '../../data/repositories/remote_notification_repository.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/services/connection_notification_service.dart';
import '../../domain/services/proposal_notification_service.dart';

part 'notification_providers.g.dart';

/// Notification repository provider (only used for remote mode).
@Riverpod(keepAlive: true)
NotificationRepository? notificationApiRepository(Ref ref) {
  if (EnvironmentConfig.useMockData) return null;
  return RemoteNotificationRepository(ref.read(apiClientProvider));
}

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

/// Provider for connection notification service
@riverpod
ConnectionNotificationService connectionNotificationService(Ref ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return ConnectionNotificationService(notificationService);
}

/// Provider for proposal notification service
@riverpod
ProposalNotificationService proposalNotificationService(Ref ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return ProposalNotificationService(notificationService);
}

/// Provider for student notification settings
/// TODO: Load from Hive storage
@riverpod
class StudentNotificationSettingsNotifier
    extends _$StudentNotificationSettingsNotifier {
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

  void setDndTimes({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
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
class TeacherNotificationSettingsNotifier
    extends _$TeacherNotificationSettingsNotifier {
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

// ============================================================
// Notification List & Actions Providers (for UI)
// ============================================================

/// Provider for user's notifications list
@riverpod
Future<List<AppNotification>> userNotifications(Ref ref) async {
  // Use remote repository if available
  final apiRepo = ref.watch(notificationApiRepositoryProvider);
  if (apiRepo != null) {
    return apiRepo.getNotifications();
  }

  // Mock data fallback
  await Future.delayed(const Duration(milliseconds: 300));

  final now = DateTime.now();
  return [
    // ============================================================
    // 🎁 수강권 제안 알림
    // 학생별로 1개의 제안만 존재 (시스템 자동 또는 선생님 수동)
    // ============================================================

    // student_1: 체험레슨 후 시스템 자동 제안
    AppNotification(
      id: 'n_proposal_1',
      userId: 'current_user',
      type: NotificationType.proposalReceived,
      priority: NotificationPriority.high,
      title: '수강권 제안이 도착했어요!',
      body: '체험레슨 후 72시간 골든타임 할인 혜택을 확인해보세요',
      createdAt: now.subtract(const Duration(hours: 1)),
      sentAt: now.subtract(const Duration(hours: 1)),
      actionUrl: '/proposals/proposal_auto_1',
      actionLabel: '제안 확인하기',
      data: {
        'proposalId': 'proposal_auto_1',
        'teacherId': 'teacher_1',
        'isAutoProposal': true,
      },
    ),

    // ============================================================
    // 🔔 수강권 만료 임박 알림
    // ============================================================
    AppNotification(
      id: 'n_sub_expiring_1',
      userId: 'current_user',
      type: NotificationType.subscriptionExpiringSoon,
      priority: NotificationPriority.high,
      title: '수강권이 3일 후 만료됩니다',
      body: '남은 횟수 2회 · 갱신 요청을 보내보세요',
      createdAt: now.subtract(const Duration(hours: 3)),
      sentAt: now.subtract(const Duration(hours: 3)),
      actionUrl: '/subscriptions/sub_1',
      actionLabel: '수강권 확인',
      data: {
        'subscriptionId': 'sub_1',
        'daysLeft': 3,
        'studentId': 'student_1',
      },
    ),

    // ============================================================
    // 기존 알림
    // ============================================================
    AppNotification(
      id: 'n1',
      userId: 'current_user',
      type: NotificationType.connectionRequestAccepted,
      priority: NotificationPriority.high,
      title: '연결 완료',
      body: '김선생님과 연결되었습니다! 지금 체험레슨을 예약해보세요.',
      createdAt: now.subtract(const Duration(minutes: 5)),
      sentAt: now.subtract(const Duration(minutes: 5)),
      actionUrl: '/teachers/teacher_1?name=${Uri.encodeComponent('김선생님')}',
      actionLabel: '선생님 보기',
    ),
    AppNotification(
      id: 'n2',
      userId: 'current_user',
      type: NotificationType.lessonReminder,
      priority: NotificationPriority.normal,
      title: '레슨 알림',
      body: '내일 오후 3시 김선생님과 레슨이 있습니다',
      createdAt: now.subtract(const Duration(hours: 2)),
      sentAt: now.subtract(const Duration(hours: 2)),
      readAt: now.subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n3',
      userId: 'current_user',
      type: NotificationType.practiceReminder,
      priority: NotificationPriority.normal,
      title: '연습 시간이에요!',
      body: '오늘의 연습 목표를 달성해보세요',
      createdAt: now.subtract(const Duration(days: 1)),
      sentAt: now.subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'n4',
      userId: 'current_user',
      type: NotificationType.streakMilestone,
      priority: NotificationPriority.low,
      title: '🔥 연속 연습 달성!',
      body: '7일 연속 연습을 달성했어요!',
      createdAt: now.subtract(const Duration(days: 2)),
      sentAt: now.subtract(const Duration(days: 2)),
      readAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}

/// Provider for unread notification count (for badge)
@riverpod
int unreadNotificationCount(Ref ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
}

/// Notifier for notification actions (mark as read, delete, etc.)
@riverpod
class NotificationActions extends _$NotificationActions {
  @override
  void build() {
    // No state needed, just actions
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    final apiRepo = ref.read(notificationApiRepositoryProvider);
    if (apiRepo != null) {
      await apiRepo.markAsRead(notificationId);
    }
    ref.invalidate(userNotificationsProvider);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final apiRepo = ref.read(notificationApiRepositoryProvider);
    if (apiRepo != null) {
      await apiRepo.markAllAsRead();
    }
    ref.invalidate(userNotificationsProvider);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    // Server-side delete not yet supported; just refresh
    ref.invalidate(userNotificationsProvider);
  }
}
