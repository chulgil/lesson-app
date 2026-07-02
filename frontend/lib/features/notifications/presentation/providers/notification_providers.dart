import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../features/notifications/domain/entities/notification_settings.dart';
import '../../../../features/notifications/domain/services/practice_reminder_scheduler.dart';
import '../../../auth/auth_facade.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/local_notification_service.dart';
import '../../data/repositories/remote_notification_repository.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/services/connection_notification_service.dart';
import '../../domain/services/notification_delivery_gate.dart';
import '../../domain/services/notification_scheduler_service.dart';
import '../../domain/services/proposal_notification_service.dart';

import 'notification_preferences_provider.dart';

part 'notification_providers.g.dart';

const _notificationSettingsBoxName = 'notification_settings';
const _studentSettingsKey = 'student_settings';
const _teacherSettingsKey = 'teacher_settings';

@Riverpod(keepAlive: true)
String notificationViewerRole(Ref ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.teacher
      ? 'teacher'
      : role == UserRole.parent
      ? 'parent'
      : 'student';
}

/// Notification repository provider (only used for remote mode).
@Riverpod(keepAlive: true)
NotificationRepository? notificationApiRepository(Ref ref) {
  if (ref.watch(mockDataModeProvider)) return null;
  return RemoteNotificationRepository(ref.read(apiClientProvider));
}

/// Provider for the notification service.
@Riverpod(keepAlive: true)
LocalNotificationService notificationService(Ref ref) {
  // #501: every delivery path (show/schedule, incl. FCM foreground and the
  // scheduler/stub services that wrap this one) passes the preference gate.
  final service = LocalNotificationService(
    shouldDeliver: (notification) => shouldDeliverNotification(
      ref.read(notificationPreferencesNotifierProvider),
      notification,
    ),
  );
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
  final useMockData = ref.watch(mockDataModeProvider);
  final service = FcmService(
    notificationDelivery: localService,
    apiClient: apiClient,
    useMockData: useMockData,
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
      practiceReminderTime: ClockTime(hour: hour, minute: minute),
    );
    _saveToHive(state);
  }

  void setStreakWarningTime(int hour, int minute) {
    state = state.copyWith(
      streakWarningTime: ClockTime(hour: hour, minute: minute),
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
      dndStart: ClockTime(
        hour: startHour ?? state.dndStart.hour,
        minute: startMinute ?? state.dndStart.minute,
      ),
      dndEnd: ClockTime(
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
  final isTeacher = role == UserRole.teacher;
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
      title: AppStrings.notifProposalTitle,
      body: AppStrings.notifProposalBody,
      createdAt: now.subtract(const Duration(hours: 1)),
      sentAt: now.subtract(const Duration(hours: 1)),
      actionUrl: '/proposals/proposal_auto_1',
      actionLabel: AppStrings.notifProposalAction,
      data: {
        'proposalId': 'proposal_auto_1',
        'teacherId': 'teacher_1',
        'isAutoProposal': true,
      },
    ),

    // ============================================================
    // Student-only: 수강권 잔여 회차 부족 알림
    // ============================================================
    AppNotification(
      id: 'n_lessons_low_1',
      userId: 'current_user',
      type: NotificationType.lessonsRunningLow,
      priority: NotificationPriority.high,
      title: AppStrings.notifLessonsRunningLowTitle(2),
      body: AppStrings.notifLessonsRunningLowBody,
      createdAt: now.subtract(const Duration(hours: 3)),
      sentAt: now.subtract(const Duration(hours: 3)),
      actionUrl: '/subscriptions/sub_mon_04',
      actionLabel: AppStrings.notifSubExpiringAction,
      data: {
        'subscriptionId': 'sub_mon_04',
        'remainingLessons': 2,
        'studentId': 'student_1',
      },
    ),

    // ============================================================
    // Both: 연결 알림 (역할별 메시지)
    // ============================================================
    if (isTeacher)
      AppNotification(
        id: 'n1_t',
        userId: 'current_user',
        type: NotificationType.connectionRequestAccepted,
        priority: NotificationPriority.high,
        title: AppStrings.notifConnectionComplete,
        body: AppStrings.notifConnectionTeacher('박지호'),
        createdAt: now.subtract(const Duration(minutes: 5)),
        sentAt: now.subtract(const Duration(minutes: 5)),
        actionUrl: '/students/student_1',
        actionLabel: AppStrings.notifViewStudent,
      ),
    if (!isTeacher)
      AppNotification(
        id: 'n1_s',
        userId: 'current_user',
        type: NotificationType.connectionRequestAccepted,
        priority: NotificationPriority.high,
        title: AppStrings.notifConnectionComplete,
        body: AppStrings.notifConnectionStudent('김선생님'),
        createdAt: now.subtract(const Duration(minutes: 5)),
        sentAt: now.subtract(const Duration(minutes: 5)),
        actionUrl: '/teachers/teacher_1?name=${Uri.encodeComponent('김선생님')}',
        actionLabel: AppStrings.notifViewTeacher,
      ),

    // ============================================================
    // Both: 레슨 알림 (역할별 메시지)
    // ============================================================
    AppNotification(
      id: 'n2',
      userId: 'current_user',
      type: NotificationType.lessonReminder,
      priority: NotificationPriority.normal,
      title: AppStrings.notifLessonReminderTitle,
      body:
          isTeacher
              ? AppStrings.notifLessonReminderTeacher('박지호 바이올린', '내일 오후 3시')
              : AppStrings.notifLessonReminderStudent('김선생님', '내일 오후 3시'),
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
      title: AppStrings.notifTrialRequestTitle,
      body: AppStrings.notifTrialRequestBody('박지호', '첼로'),
      createdAt: now.subtract(const Duration(hours: 4)),
      sentAt: now.subtract(const Duration(hours: 4)),
      actionUrl: '/schedule/request/ulr_11',
      actionLabel: AppStrings.notifTrialRequestAction,
      data: {'requestId': 'ulr_11', 'studentId': 'student_3'},
    ),

    // ============================================================
    // Teacher-only: 입금 완료 알림
    // ============================================================
    AppNotification(
      id: 'n_payment_1',
      userId: 'current_user',
      type: NotificationType.paymentReceived,
      priority: NotificationPriority.normal,
      title: AppStrings.notifPaymentReceivedTitle,
      body: AppStrings.notifPaymentReceivedBody('김민수'),
      createdAt: now.subtract(const Duration(hours: 6)),
      sentAt: now.subtract(const Duration(hours: 6)),
      actionUrl: '/subscriptions/sub_pkg_01',
      actionLabel: AppStrings.notifPaymentReceivedAction,
    ),

    // ============================================================
    // Student-only: 연습 알림
    // ============================================================
    AppNotification(
      id: 'n3',
      userId: 'current_user',
      type: NotificationType.practiceReminder,
      priority: NotificationPriority.normal,
      title: AppStrings.notifPracticeReminderTitle,
      body: AppStrings.notifPracticeReminderBody,
      createdAt: now.subtract(const Duration(days: 1)),
      sentAt: now.subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'n4',
      userId: 'current_user',
      type: NotificationType.streakMilestone,
      priority: NotificationPriority.low,
      title: AppStrings.notifStreakTitle,
      body: AppStrings.notifStreakBody(7),
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
      title: AppStrings.notifScheduleChangeTitle,
      body: AppStrings.notifScheduleChangeBody('김민수', 3),
      createdAt: now.subtract(const Duration(hours: 8)),
      sentAt: now.subtract(const Duration(hours: 8)),
      actionUrl: '/subscriptions/sub_pkg_01',
      actionLabel: AppStrings.notifScheduleChangeAction,
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
      try {
        await apiRepo.markAsRead(notificationId);
      } catch (_) {
        // Best-effort: server error must not prevent local list refresh.
      }
    }
    ref.invalidate(userNotificationsProvider);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final apiRepo = ref.read(notificationApiRepositoryProvider);
    if (apiRepo != null) {
      try {
        await apiRepo.markAllAsRead();
      } catch (_) {
        // Best-effort: refresh the list regardless.
      }
    }
    ref.invalidate(userNotificationsProvider);
  }

  /// Delete a notification — wired to DELETE /notifications/{id} (#629).
  Future<void> deleteNotification(String notificationId) async {
    final apiRepo = ref.read(notificationApiRepositoryProvider);
    if (apiRepo != null) {
      try {
        await apiRepo.delete(notificationId);
      } catch (_) {
        // Best-effort: server error must not prevent local list refresh.
      }
    }
    ref.invalidate(userNotificationsProvider);
  }
}
