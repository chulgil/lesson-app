import 'dart:convert';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/notifications/domain/entities/notification_settings.dart';
import '../../../../features/notifications/domain/services/practice_reminder_scheduler.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/local_notification_service.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../data/repositories/remote_notification_repository.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/services/connection_notification_service.dart';
import '../../domain/services/notification_scheduler_service.dart';
import '../../domain/services/proposal_notification_service.dart';

part 'notification_providers.g.dart';

const _notificationSettingsBoxName = 'notification_settings';
const _studentSettingsKey = 'student_settings';
const _teacherSettingsKey = 'teacher_settings';

/// Notification repository provider (only used for remote mode).
@Riverpod(keepAlive: true)
NotificationRepository? notificationApiRepository(Ref ref) {
  if (EnvironmentConfig.useMockData) return null;
  return RemoteNotificationRepository(ref.read(apiClientProvider));
}

/// Provider for the notification service.
@Riverpod(keepAlive: true)
LocalNotificationService notificationService(Ref ref) {
  final service = LocalNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider for scheduling future notification delivery.
@Riverpod(keepAlive: true)
NotificationSchedulerService notificationSchedulerService(Ref ref) {
  return NotificationSchedulerService(ref.watch(notificationServiceProvider));
}

/// Provider for FCM push notification service (keepAlive for app lifecycle)
@Riverpod(keepAlive: true)
FcmService fcmService(Ref ref) {
  final localService = ref.read(notificationServiceProvider);
  final apiClient = ref.read(apiClientProvider);
  final service = FcmService(
    notificationDelivery: localService,
    apiClient: apiClient,
    useMockData: EnvironmentConfig.useMockData,
  );
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

/// Provider for student notification settings (persisted to Hive)
@riverpod
class StudentNotificationSettingsNotifier
    extends _$StudentNotificationSettingsNotifier {
  @override
  StudentNotificationSettings build() {
    return _loadFromHive() ?? StudentNotificationSettings.defaultSettings;
  }

  StudentNotificationSettings? _loadFromHive() {
    try {
      final box = Hive.box(_notificationSettingsBoxName);
      final jsonStr = box.get(_studentSettingsKey) as String?;
      if (jsonStr == null) return null;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return StudentNotificationSettings.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToHive(StudentNotificationSettings settings) async {
    try {
      final box = Hive.box(_notificationSettingsBoxName);
      await box.put(_studentSettingsKey, jsonEncode(settings.toJson()));
    } catch (_) {
      // Storage failure is non-blocking
    }
  }

  void updateSettings(StudentNotificationSettings newSettings) {
    state = newSettings;
    _saveToHive(newSettings);
  }

  void toggleLessonReminder(bool enabled) {
    state = state.copyWith(lessonReminderEnabled: enabled);
    _saveToHive(state);
  }

  void togglePracticeReminder(bool enabled) {
    state = state.copyWith(practiceReminderEnabled: enabled);
    _saveToHive(state);
  }

  void toggleStreakWarning(bool enabled) {
    state = state.copyWith(streakWarningEnabled: enabled);
    _saveToHive(state);
  }

  void setPracticeReminderTime(int hour, int minute) {
    state = state.copyWith(
      practiceReminderTime: TimeOfDay(hour: hour, minute: minute),
    );
    _saveToHive(state);
  }

  void setStreakWarningTime(int hour, int minute) {
    state = state.copyWith(
      streakWarningTime: TimeOfDay(hour: hour, minute: minute),
    );
    _saveToHive(state);
  }

  void toggleDnd(bool enabled) {
    state = state.copyWith(dndEnabled: enabled);
    _saveToHive(state);
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
    _saveToHive(state);
  }
}

/// Provider for teacher notification settings (persisted to Hive)
@riverpod
class TeacherNotificationSettingsNotifier
    extends _$TeacherNotificationSettingsNotifier {
  @override
  TeacherNotificationSettings build() {
    return _loadFromHive() ?? TeacherNotificationSettings.defaultSettings;
  }

  TeacherNotificationSettings? _loadFromHive() {
    try {
      final box = Hive.box(_notificationSettingsBoxName);
      final jsonStr = box.get(_teacherSettingsKey) as String?;
      if (jsonStr == null) return null;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TeacherNotificationSettings.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToHive(TeacherNotificationSettings settings) async {
    try {
      final box = Hive.box(_notificationSettingsBoxName);
      await box.put(_teacherSettingsKey, jsonEncode(settings.toJson()));
    } catch (_) {
      // Storage failure is non-blocking
    }
  }

  void updateSettings(TeacherNotificationSettings newSettings) {
    state = newSettings;
    _saveToHive(newSettings);
  }

  void toggleLessonReminder(bool enabled) {
    state = state.copyWith(lessonReminderEnabled: enabled);
    _saveToHive(state);
  }

  void toggleNewStudentAlert(bool enabled) {
    state = state.copyWith(newStudentAlert: enabled);
    _saveToHive(state);
  }

  void toggleTrialBookingAlert(bool enabled) {
    state = state.copyWith(trialBookingAlert: enabled);
    _saveToHive(state);
  }

  void togglePaymentReceivedAlert(bool enabled) {
    state = state.copyWith(paymentReceivedAlert: enabled);
    _saveToHive(state);
  }

  void toggleStudentPracticeReport(bool enabled) {
    state = state.copyWith(studentPracticeReport: enabled);
    _saveToHive(state);
  }

  void toggleReviewReceivedAlert(bool enabled) {
    state = state.copyWith(reviewReceivedAlert: enabled);
    _saveToHive(state);
  }

  void toggleDnd(bool enabled) {
    state = state.copyWith(dndEnabled: enabled);
    _saveToHive(state);
  }
}

// ============================================================
// Notification List & Actions Providers (for UI)
// ============================================================

/// Provider for user's notifications list.
///
/// Filters mock notifications by current user role using
/// [NotificationTypeExtension.targetRole].
@riverpod
Future<List<AppNotification>> userNotifications(Ref ref) async {
  // Use remote repository if available (backend filters by user)
  final apiRepo = ref.watch(notificationApiRepositoryProvider);
  if (apiRepo != null) {
    return apiRepo.getNotifications();
  }

  // Mock data fallback — filter by role
  await Future.delayed(const Duration(milliseconds: 300));
  final role = ref.watch(currentUserRoleProvider);
  final roleStr =
      role == UserRole.teacher
          ? 'teacher'
          : role == UserRole.student
          ? 'student'
          : 'student';

  final now = DateTime.now();
  final allNotifications = [
    // ============================================================
    // Student-only: 수강권 제안 알림
    // ============================================================
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
    // Both: 수강권 만료 임박 알림
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
    // Both: 연결 알림
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

    // ============================================================
    // Both: 레슨 알림
    // ============================================================
    AppNotification(
      id: 'n2',
      userId: 'current_user',
      type: NotificationType.lessonReminder,
      priority: NotificationPriority.normal,
      title: '레슨 알림',
      body: '내일 오후 3시 김민수 바이올린 레슨이 있습니다',
      createdAt: now.subtract(const Duration(hours: 2)),
      sentAt: now.subtract(const Duration(hours: 2)),
      readAt: now.subtract(const Duration(hours: 1)),
    ),

    // ============================================================
    // Teacher-only: 체험 레슨 요청
    // ============================================================
    AppNotification(
      id: 'n_trial_1',
      userId: 'current_user',
      type: NotificationType.trialBookingRequest,
      priority: NotificationPriority.normal,
      title: '새 체험 요청',
      body: '박지호님이 바이올린 체험 레슨을 요청했습니다',
      createdAt: now.subtract(const Duration(hours: 4)),
      sentAt: now.subtract(const Duration(hours: 4)),
      actionUrl: '/schedule/lesson-requests',
      actionLabel: '요청 확인',
    ),

    // ============================================================
    // Teacher-only: 입금 완료 알림
    // ============================================================
    AppNotification(
      id: 'n_payment_1',
      userId: 'current_user',
      type: NotificationType.paymentReceived,
      priority: NotificationPriority.normal,
      title: '입금 완료 알림',
      body: '김민수님이 수강료 입금 완료를 알렸습니다',
      createdAt: now.subtract(const Duration(hours: 6)),
      sentAt: now.subtract(const Duration(hours: 6)),
      actionUrl: '/subscriptions/sub_1',
      actionLabel: '입금 확인',
    ),

    // ============================================================
    // Student-only: 연습 알림
    // ============================================================
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
      title: '연속 연습 달성!',
      body: '7일 연속 연습을 달성했어요!',
      createdAt: now.subtract(const Duration(days: 2)),
      sentAt: now.subtract(const Duration(days: 2)),
      readAt: now.subtract(const Duration(days: 2)),
    ),

    // ============================================================
    // Both: 스케줄 변경 요청
    // ============================================================
    AppNotification(
      id: 'n_schedule_1',
      userId: 'current_user',
      type: NotificationType.scheduleChangeRequested,
      priority: NotificationPriority.high,
      title: '일정 변경 요청',
      body: '김민수 3회차 레슨 일정 변경 요청',
      createdAt: now.subtract(const Duration(hours: 8)),
      sentAt: now.subtract(const Duration(hours: 8)),
      actionUrl: '/subscriptions/sub_1',
      actionLabel: '변경 확인',
    ),
  ];

  // Filter by current user role
  return allNotifications
      .where((n) => n.type.targetRole == 'both' || n.type.targetRole == roleStr)
      .toList();
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
