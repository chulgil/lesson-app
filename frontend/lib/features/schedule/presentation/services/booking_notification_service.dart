import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../notifications/domain/entities/notification.dart';

/// Service for creating and sending booking-related notifications
///
/// Handles notifications for:
/// - New bookings
/// - Booking changes (reschedules)
/// - Booking cancellations
/// - Lesson reminders
class BookingNotificationService {
  static final _uuid = const Uuid();

  /// Create notification for new booking
  static AppNotification createBookingConfirmation({
    required String userId,
    required String teacherName,
    required String instrument,
    required DateTime lessonDate,
    required TimeOfDay startTime,
  }) {
    final dateStr = _formatDate(lessonDate);
    final timeStr = _formatTime(startTime);

    return AppNotification(
      id: _uuid.v4(),
      userId: userId,
      type: NotificationType.lessonBooked,
      priority: NotificationPriority.normal,
      title: '레슨 예약 완료',
      body: '$dateStr $timeStr $teacherName 선생님 $instrument 레슨이 예약되었습니다.',
      data: {
        'lessonDate': lessonDate.toIso8601String(),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'teacherName': teacherName,
        'instrument': instrument,
      },
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
    );
  }

  /// Create notification for booking reschedule
  static AppNotification createRescheduleNotification({
    required String userId,
    required String teacherName,
    required DateTime oldDate,
    required TimeOfDay oldTime,
    required DateTime newDate,
    required TimeOfDay newTime,
    required bool isTeacherInitiated,
  }) {
    final oldDateStr = _formatDate(oldDate);
    final oldTimeStr = _formatTime(oldTime);
    final newDateStr = _formatDate(newDate);
    final newTimeStr = _formatTime(newTime);

    final title = isTeacherInitiated ? '레슨 시간 변경 안내' : '레슨 변경 완료';
    final body =
        isTeacherInitiated
            ? '$teacherName 선생님이 레슨 시간을 변경했습니다.\n$oldDateStr $oldTimeStr → $newDateStr $newTimeStr'
            : '레슨이 $newDateStr $newTimeStr로 변경되었습니다.';

    return AppNotification(
      id: _uuid.v4(),
      userId: userId,
      type: NotificationType.lessonRescheduled,
      priority:
          isTeacherInitiated
              ? NotificationPriority.high
              : NotificationPriority.normal,
      title: title,
      body: body,
      data: {
        'oldDate': oldDate.toIso8601String(),
        'oldTime': '${oldTime.hour}:${oldTime.minute}',
        'newDate': newDate.toIso8601String(),
        'newTime': '${newTime.hour}:${newTime.minute}',
        'teacherName': teacherName,
        'isTeacherInitiated': isTeacherInitiated,
      },
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
    );
  }

  /// Create notification for booking cancellation
  static AppNotification createCancellationNotification({
    required String userId,
    required String teacherName,
    required DateTime lessonDate,
    required TimeOfDay startTime,
    required bool isTeacherInitiated,
    String? reason,
  }) {
    final dateStr = _formatDate(lessonDate);
    final timeStr = _formatTime(startTime);

    final title = isTeacherInitiated ? '레슨 취소 안내' : '레슨 취소 완료';
    final body =
        isTeacherInitiated
            ? '$teacherName 선생님이 $dateStr $timeStr 레슨을 취소했습니다.${reason != null ? '\n${AppStrings.reasonPrefix}$reason' : ''}'
            : '$dateStr $timeStr 레슨이 취소되었습니다.';

    return AppNotification(
      id: _uuid.v4(),
      userId: userId,
      type: NotificationType.lessonCancelled,
      priority: NotificationPriority.high,
      title: title,
      body: body,
      data: {
        'lessonDate': lessonDate.toIso8601String(),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'teacherName': teacherName,
        'isTeacherInitiated': isTeacherInitiated,
        if (reason != null) 'reason': reason,
      },
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
    );
  }

  /// Create lesson reminder notification
  static AppNotification createLessonReminder({
    required String userId,
    required String teacherName,
    required String instrument,
    required DateTime lessonDate,
    required TimeOfDay startTime,
    required int minutesBefore,
  }) {
    final title =
        minutesBefore >= 60
            ? '레슨 ${minutesBefore ~/ 60}시간 전'
            : '레슨 $minutesBefore분 전';

    final dateStr = _formatDate(lessonDate);
    final timeStr = _formatTime(startTime);

    return AppNotification(
      id: _uuid.v4(),
      userId: userId,
      type: NotificationType.lessonReminder,
      priority:
          minutesBefore <= 30
              ? NotificationPriority.high
              : NotificationPriority.normal,
      title: title,
      body: '$dateStr $timeStr $teacherName 선생님 $instrument 레슨이 있습니다.',
      data: {
        'lessonDate': lessonDate.toIso8601String(),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'teacherName': teacherName,
        'instrument': instrument,
        'minutesBefore': minutesBefore,
      },
      createdAt: DateTime.now(),
      scheduledAt: lessonDate.subtract(Duration(minutes: minutesBefore)),
    );
  }

  /// Create notification for lesson starting soon
  static AppNotification createLessonStartingNotification({
    required String userId,
    required String teacherName,
    required String instrument,
  }) {
    return AppNotification(
      id: _uuid.v4(),
      userId: userId,
      type: NotificationType.lessonStarting,
      priority: NotificationPriority.urgent,
      title: '레슨이 곧 시작됩니다',
      body: '$teacherName 선생님 $instrument 레슨이 시작됩니다.',
      data: {'teacherName': teacherName, 'instrument': instrument},
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
    );
  }

  /// Create notification for new booking request (for teacher)
  static AppNotification createNewBookingRequestNotification({
    required String teacherId,
    required String studentName,
    required DateTime lessonDate,
    required TimeOfDay startTime,
    required String instrument,
  }) {
    final dateStr = _formatDate(lessonDate);
    final timeStr = _formatTime(startTime);

    return AppNotification(
      id: _uuid.v4(),
      userId: teacherId,
      type: NotificationType.trialBookingRequest,
      priority: NotificationPriority.normal,
      title: '새로운 레슨 예약',
      body: '$studentName 학생이 $dateStr $timeStr $instrument 레슨을 예약했습니다.',
      data: {
        'studentName': studentName,
        'lessonDate': lessonDate.toIso8601String(),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'instrument': instrument,
      },
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
    );
  }

  // Helper methods
  static String _formatDate(DateTime date) {
    const weekdays = AppStrings.dayNamesShort;
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}($weekday)';
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Extension to add booking notification templates
extension BookingNotificationTemplates on NotificationTemplate {
  static const lessonBooked = NotificationTemplate(
    type: NotificationType.lessonBooked,
    titleTemplate: '레슨 예약 완료',
    bodyTemplate:
        '{{date}} {{time}} {{teacherName}} 선생님 {{instrument}} 레슨이 예약되었습니다.',
    priority: NotificationPriority.normal,
  );

  static const lessonRescheduled = NotificationTemplate(
    type: NotificationType.lessonRescheduled,
    titleTemplate: '레슨 변경 {{status}}',
    bodyTemplate: '레슨이 {{newDate}} {{newTime}}로 변경되었습니다.',
    priority: NotificationPriority.high,
  );

  static const lessonCancelled = NotificationTemplate(
    type: NotificationType.lessonCancelled,
    titleTemplate: '레슨 취소 {{status}}',
    bodyTemplate: '{{date}} {{time}} 레슨이 취소되었습니다.',
    priority: NotificationPriority.high,
  );
}
