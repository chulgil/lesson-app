import 'package:uuid/uuid.dart';

import '../../../../core/domain/value_objects/clock_time.dart';
import '../entities/notification.dart';
import 'notification_service.dart';

/// Scheduler for practice-related notifications
class PracticeReminderScheduler {
  final NotificationService _notificationService;
  static const _uuid = Uuid();

  PracticeReminderScheduler(this._notificationService);

  /// Schedule daily practice reminder for a user
  Future<void> scheduleDailyReminder({
    required String userId,
    required ClockTime reminderTime,
    String? customMessage,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final notification = AppNotification(
      id: 'practice_reminder_${userId}_${scheduledDate.toIso8601String()}',
      userId: userId,
      type: NotificationType.practiceReminder,
      priority: NotificationPriority.normal,
      title: '연습 시간이에요!',
      body: customMessage ?? '오늘의 연습을 시작해보세요',
      createdAt: DateTime.now(),
      scheduledAt: scheduledDate,
    );

    await _notificationService.scheduleNotification(notification);
  }

  /// Schedule streak warning notification
  /// Only sends if user hasn't practiced today
  Future<void> scheduleStreakWarning({
    required String userId,
    required ClockTime warningTime,
    required int currentStreak,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      warningTime.hour,
      warningTime.minute,
    );

    // If time has passed today, don't schedule (only warn for today)
    if (scheduledDate.isBefore(now)) {
      return;
    }

    final nextStreak = currentStreak + 1;
    final message =
        currentStreak == 0 ? '오늘 연습을 시작하세요!' : '오늘 연습하면 $nextStreak일 스트릭 달성!';

    final notification = AppNotification(
      id: 'streak_warning_${userId}_${scheduledDate.toIso8601String()}',
      userId: userId,
      type: NotificationType.streakWarning,
      priority: NotificationPriority.normal,
      title: '스트릭 위험!',
      body: message,
      data: {'currentStreak': currentStreak},
      createdAt: DateTime.now(),
      scheduledAt: scheduledDate,
    );

    await _notificationService.scheduleNotification(notification);
  }

  /// Schedule streak milestone celebration
  Future<void> showStreakMilestone({
    required String userId,
    required int streakDays,
  }) async {
    String message;

    if (streakDays == 7) {
      message = '일주일 연속 연습! 대단해요!';
    } else if (streakDays == 14) {
      message = '2주 연속 연습! 정말 멋져요!';
    } else if (streakDays == 30) {
      message = '한 달 연속 연습! 놀라워요!';
    } else if (streakDays == 100) {
      message = '100일 연속 연습! 전설적이에요!';
    } else if (streakDays % 7 == 0) {
      final weeks = streakDays ~/ 7;
      message = '$weeks주 연속 연습! 잘하고 있어요!';
    } else {
      message = '$streakDays일 연속 연습! 계속 이어가세요!';
    }

    final notification = AppNotification(
      id: 'streak_milestone_${userId}_${_uuid.v4()}',
      userId: userId,
      type: NotificationType.streakMilestone,
      priority: NotificationPriority.low,
      title: '스트릭 달성!',
      body: message,
      data: {'streakDays': streakDays},
      createdAt: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }

  /// Cancel all daily reminders for a user
  Future<void> cancelDailyReminders(String userId) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Cancel practice reminder
    await _notificationService.cancelNotification(
      'practice_reminder_${userId}_$dateStr',
    );

    // Cancel streak warning
    await _notificationService.cancelNotification(
      'streak_warning_${userId}_$dateStr',
    );
  }

  /// Notify about new practice assignment
  Future<void> notifyPracticeAssigned({
    required String userId,
    required String teacherName,
    required String assignmentName,
  }) async {
    final notification = AppNotification(
      id: 'practice_assigned_${userId}_${_uuid.v4()}',
      userId: userId,
      type: NotificationType.practiceAssigned,
      priority: NotificationPriority.normal,
      title: '새 연습 과제',
      body: '$teacherName 선생님이 "$assignmentName" 과제를 등록했습니다',
      data: {'teacherName': teacherName, 'assignmentName': assignmentName},
      createdAt: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }

  /// Notify weekly goal achievement
  Future<void> notifyWeeklyGoalAchieved({
    required String userId,
    required int practiceDays,
    required int totalMinutes,
  }) async {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final timeStr = hours > 0 ? '$hours시간 $minutes분' : '$minutes분';

    final notification = AppNotification(
      id: 'weekly_goal_${userId}_${_uuid.v4()}',
      userId: userId,
      type: NotificationType.weeklyGoalAchieved,
      priority: NotificationPriority.low,
      title: '주간 목표 달성!',
      body: '이번 주 $practiceDays일, 총 $timeStr 연습했어요!',
      data: {'practiceDays': practiceDays, 'totalMinutes': totalMinutes},
      createdAt: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }
}
