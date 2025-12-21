import 'package:flutter/material.dart';
import 'time_slot.dart';

/// Lesson type enum
enum LessonType {
  trial,   // 체험 레슨
  regular; // 정규 레슨

  String get label {
    switch (this) {
      case LessonType.trial:
        return '체험';
      case LessonType.regular:
        return '정규';
    }
  }

  Color get color {
    switch (this) {
      case LessonType.trial:
        return const Color(0xFFFF9800); // Orange
      case LessonType.regular:
        return const Color(0xFF4CAF50); // Green
    }
  }
}

/// Schedule type for regular lessons
enum ScheduleType {
  fixed,    // 고정 시간
  flexible; // 유동 시간

  String get label {
    switch (this) {
      case ScheduleType.fixed:
        return '고정';
      case ScheduleType.flexible:
        return '유동';
    }
  }

  String get description {
    switch (this) {
      case ScheduleType.fixed:
        return '매주 같은 요일/시간에 레슨';
      case ScheduleType.flexible:
        return '매주 가능한 시간 협의';
    }
  }
}

/// Booking status enum
enum BookingStatus {
  pending,          // 대기 중 (신청 완료)
  confirmed,        // 확정 (선생님 승인)
  changeRequested,  // 변경 요청 중
  completed,        // 완료
  cancelled,        // 취소
  unavailable,      // 일정 조율 필요 (선생님이 해당 시간 불가)
  expired;          // 응답 대기 만료 (48시간 초과)

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return '신청완료';
      case BookingStatus.confirmed:
        return '확정';
      case BookingStatus.changeRequested:
        return '변경요청';
      case BookingStatus.completed:
        return '완료';
      case BookingStatus.cancelled:
        return '취소';
      case BookingStatus.unavailable:
        return '일정조율';
      case BookingStatus.expired:
        return '만료';
    }
  }

  /// Student-friendly message for unavailable/expired statuses
  String get studentMessage {
    switch (this) {
      case BookingStatus.pending:
        return '선생님 확인 중이에요';
      case BookingStatus.confirmed:
        return '레슨이 확정되었어요';
      case BookingStatus.changeRequested:
        return '일정 변경 요청 중';
      case BookingStatus.completed:
        return '레슨 완료';
      case BookingStatus.cancelled:
        return '취소되었습니다';
      case BookingStatus.unavailable:
        return '다른 시간을 확인해주세요';
      case BookingStatus.expired:
        return '응답 대기 시간이 지났어요';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case BookingStatus.confirmed:
        return const Color(0xFF2196F3); // Blue
      case BookingStatus.changeRequested:
        return const Color(0xFF9C27B0); // Purple
      case BookingStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case BookingStatus.cancelled:
        return const Color(0xFF9E9E9E); // Grey
      case BookingStatus.unavailable:
        return const Color(0xFFFF7043); // Deep Orange (softer than red)
      case BookingStatus.expired:
        return const Color(0xFF78909C); // Blue Grey
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.changeRequested:
        return Icons.swap_horiz;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.unavailable:
        return Icons.event_busy;
      case BookingStatus.expired:
        return Icons.timer_off;
    }
  }

  /// Check if booking is active
  bool get isActive =>
      this != BookingStatus.cancelled &&
      this != BookingStatus.unavailable &&
      this != BookingStatus.expired;

  /// Check if student can modify the booking
  bool get canStudentModify => this == BookingStatus.pending;

  /// Check if student can request schedule change
  bool get canRequestChange => this == BookingStatus.confirmed;

  /// Check if booking can be cancelled
  bool get canCancel =>
      this == BookingStatus.pending ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.changeRequested;

  /// Check if student can try again with different time
  bool get canRetry =>
      this == BookingStatus.unavailable || this == BookingStatus.expired;
}

/// Reason for unavailability (predefined, neutral options)
enum UnavailableReason {
  timeSlotFull,     // 해당 시간 마감
  scheduleConflict, // 일정 조율 필요
  temporaryBreak;   // 잠시 레슨 쉬는 중

  String get label {
    switch (this) {
      case UnavailableReason.timeSlotFull:
        return '해당 시간 마감';
      case UnavailableReason.scheduleConflict:
        return '일정 조율 필요';
      case UnavailableReason.temporaryBreak:
        return '잠시 레슨 쉬는 중';
    }
  }

  /// Student-friendly message
  String get studentMessage {
    switch (this) {
      case UnavailableReason.timeSlotFull:
        return '요청하신 시간이 마감되었어요';
      case UnavailableReason.scheduleConflict:
        return '해당 시간 조율이 필요해요';
      case UnavailableReason.temporaryBreak:
        return '선생님이 잠시 쉬고 계세요';
    }
  }
}

/// Lesson goal enum (for trial lessons)
enum LessonGoal {
  hobby,  // 취미
  exam,   // 입시
  major;  // 전공

  String get label {
    switch (this) {
      case LessonGoal.hobby:
        return '취미';
      case LessonGoal.exam:
        return '입시';
      case LessonGoal.major:
        return '전공';
    }
  }

  String get description {
    switch (this) {
      case LessonGoal.hobby:
        return '즐겁게 음악을 배우고 싶어요';
      case LessonGoal.exam:
        return '입시 준비가 필요해요';
      case LessonGoal.major:
        return '전공자로 실력을 키우고 싶어요';
    }
  }
}

/// Experience level enum (for trial lessons)
enum ExperienceLevel {
  none,       // 처음
  beginner,   // 1년 미만
  some,       // 1-3년
  experienced; // 3년 이상

  String get label {
    switch (this) {
      case ExperienceLevel.none:
        return '처음';
      case ExperienceLevel.beginner:
        return '1년 미만';
      case ExperienceLevel.some:
        return '1-3년';
      case ExperienceLevel.experienced:
        return '3년 이상';
    }
  }

  /// Map from StudentLevel to ExperienceLevel
  /// Used when existing student requests trial lesson for new instrument
  static ExperienceLevel fromStudentLevel(dynamic studentLevel) {
    // Handle StudentLevel enum from student.dart
    final levelName = studentLevel.toString().split('.').last;
    switch (levelName) {
      case 'beginner':    // 입문 → 1년 미만
      case 'elementary':  // 초급 → 1년 미만
        return ExperienceLevel.beginner;
      case 'intermediate': // 중급 → 1-3년
        return ExperienceLevel.some;
      case 'advanced':    // 고급 → 3년 이상
        return ExperienceLevel.experienced;
      default:
        return ExperienceLevel.none;
    }
  }
}

/// Lesson booking model
class LessonBooking {
  final String id;
  final String teacherId;
  final String teacherName;
  final String? studentId;
  final String studentName;
  final String? instrument; // For teachers who teach multiple instruments
  final LessonType lessonType;
  final BookingStatus status;
  final DateTime lessonDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final int fee;
  final ScheduleType? scheduleType; // For regular lessons
  final TimeSlot? fixedTimeSlot;     // For fixed schedule
  final String? studentPhone;
  final String? studentEmail;
  final LessonGoal? lessonGoal;
  final ExperienceLevel? experienceLevel;
  final String? studentMessage; // Message from student when requesting
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  // Change request fields (for changeRequested status)
  final DateTime? requestedDate;      // Requested new date
  final TimeOfDay? requestedStartTime; // Requested new start time
  final TimeOfDay? requestedEndTime;   // Requested new end time
  final DateTime? changeRequestedAt;   // When change was requested
  // Unavailable fields (for unavailable status - replaces rejected)
  final UnavailableReason? unavailableReason;   // Predefined reason (no free text)
  final List<TimeSlot>? suggestedTimeSlots;     // Teacher's alternative suggestions
  final DateTime? unavailableAt;                // When marked unavailable
  final DateTime? expiredAt;                    // When auto-expired (48h timeout)

  const LessonBooking({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    this.studentId,
    required this.studentName,
    this.instrument,
    required this.lessonType,
    required this.status,
    required this.lessonDate,
    required this.startTime,
    required this.endTime,
    this.durationMinutes = 60,
    required this.fee,
    this.scheduleType,
    this.fixedTimeSlot,
    this.studentPhone,
    this.studentEmail,
    this.lessonGoal,
    this.experienceLevel,
    this.studentMessage,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.requestedDate,
    this.requestedStartTime,
    this.requestedEndTime,
    this.changeRequestedAt,
    this.unavailableReason,
    this.suggestedTimeSlots,
    this.unavailableAt,
    this.expiredAt,
  });

  /// Get formatted time range
  String get timeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  /// Get formatted date
  String get formattedDate {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[lessonDate.weekday - 1];
    return '${lessonDate.month}/${lessonDate.day}($weekday)';
  }

  /// Get full formatted date
  String get fullFormattedDate {
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[lessonDate.weekday - 1];
    return '${lessonDate.year}년 ${lessonDate.month}월 ${lessonDate.day}일 $weekday';
  }

  /// Get formatted fee
  String get formattedFee {
    final formatter = fee.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatter원';
  }

  /// Check if booking is trial lesson
  bool get isTrial => lessonType == LessonType.trial;

  /// Check if booking is pending approval
  bool get isPending => status == BookingStatus.pending;

  /// Check if booking can be cancelled
  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  /// Check if lesson is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final lessonDateTime = DateTime(
      lessonDate.year,
      lessonDate.month,
      lessonDate.day,
      startTime.hour,
      startTime.minute,
    );
    return lessonDateTime.isAfter(now) && status.isActive;
  }

  /// Get days until lesson
  int get daysUntilLesson {
    final now = DateTime.now();
    final lessonDay = DateTime(
      lessonDate.year,
      lessonDate.month,
      lessonDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return lessonDay.difference(today).inDays;
  }

  /// Check if there is a pending change request
  bool get hasChangeRequest => status == BookingStatus.changeRequested;

  /// Get formatted requested time range (for change requests)
  String? get requestedTimeRange {
    if (requestedStartTime == null || requestedEndTime == null) return null;
    final startHour = requestedStartTime!.hour.toString().padLeft(2, '0');
    final startMinute = requestedStartTime!.minute.toString().padLeft(2, '0');
    final endHour = requestedEndTime!.hour.toString().padLeft(2, '0');
    final endMinute = requestedEndTime!.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  /// Get formatted requested date (for change requests)
  String? get formattedRequestedDate {
    if (requestedDate == null) return null;
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[requestedDate!.weekday - 1];
    return '${requestedDate!.month}/${requestedDate!.day}($weekday)';
  }

  /// Check if booking has suggested alternatives
  bool get hasSuggestedTimes =>
      suggestedTimeSlots != null && suggestedTimeSlots!.isNotEmpty;

  /// Get student-friendly unavailable message
  String? get unavailableMessage {
    if (status == BookingStatus.unavailable && unavailableReason != null) {
      return unavailableReason!.studentMessage;
    }
    if (status == BookingStatus.expired) {
      return status.studentMessage;
    }
    return null;
  }

  LessonBooking copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? studentId,
    String? studentName,
    String? instrument,
    LessonType? lessonType,
    BookingStatus? status,
    DateTime? lessonDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? durationMinutes,
    int? fee,
    ScheduleType? scheduleType,
    TimeSlot? fixedTimeSlot,
    String? studentPhone,
    String? studentEmail,
    LessonGoal? lessonGoal,
    ExperienceLevel? experienceLevel,
    String? studentMessage,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? requestedDate,
    TimeOfDay? requestedStartTime,
    TimeOfDay? requestedEndTime,
    DateTime? changeRequestedAt,
    UnavailableReason? unavailableReason,
    List<TimeSlot>? suggestedTimeSlots,
    DateTime? unavailableAt,
    DateTime? expiredAt,
  }) {
    return LessonBooking(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      instrument: instrument ?? this.instrument,
      lessonType: lessonType ?? this.lessonType,
      status: status ?? this.status,
      lessonDate: lessonDate ?? this.lessonDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      fee: fee ?? this.fee,
      scheduleType: scheduleType ?? this.scheduleType,
      fixedTimeSlot: fixedTimeSlot ?? this.fixedTimeSlot,
      studentPhone: studentPhone ?? this.studentPhone,
      studentEmail: studentEmail ?? this.studentEmail,
      lessonGoal: lessonGoal ?? this.lessonGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      studentMessage: studentMessage ?? this.studentMessage,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      requestedDate: requestedDate ?? this.requestedDate,
      requestedStartTime: requestedStartTime ?? this.requestedStartTime,
      requestedEndTime: requestedEndTime ?? this.requestedEndTime,
      changeRequestedAt: changeRequestedAt ?? this.changeRequestedAt,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      suggestedTimeSlots: suggestedTimeSlots ?? this.suggestedTimeSlots,
      unavailableAt: unavailableAt ?? this.unavailableAt,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonBooking &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Trial lesson request model (before becoming a booking)
class TrialLessonRequest {
  final String studentName;
  final String? studentPhone;
  final String? studentEmail;
  final LessonGoal goal;
  final ExperienceLevel experience;
  final String? message;
  final DateTime preferredDate;
  final TimeOfDay preferredStartTime;
  final TimeOfDay preferredEndTime;

  const TrialLessonRequest({
    required this.studentName,
    this.studentPhone,
    this.studentEmail,
    required this.goal,
    required this.experience,
    this.message,
    required this.preferredDate,
    required this.preferredStartTime,
    required this.preferredEndTime,
  });

  /// Convert to LessonBooking
  LessonBooking toBooking({
    required String id,
    required String teacherId,
    required String teacherName,
    required int fee,
  }) {
    return LessonBooking(
      id: id,
      teacherId: teacherId,
      teacherName: teacherName,
      studentName: studentName,
      lessonType: LessonType.trial,
      status: BookingStatus.pending,
      lessonDate: preferredDate,
      startTime: preferredStartTime,
      endTime: preferredEndTime,
      fee: fee,
      studentPhone: studentPhone,
      studentEmail: studentEmail,
      lessonGoal: goal,
      experienceLevel: experience,
      studentMessage: message,
      createdAt: DateTime.now(),
    );
  }
}

/// Regular lesson registration model
class RegularLessonRegistration {
  final String studentId;
  final ScheduleType scheduleType;
  final TimeSlot? fixedTimeSlot; // Required for fixed schedule
  final int lessonsPerWeek;
  final int monthlyFee;
  final DateTime startDate;

  const RegularLessonRegistration({
    required this.studentId,
    required this.scheduleType,
    this.fixedTimeSlot,
    this.lessonsPerWeek = 1,
    required this.monthlyFee,
    required this.startDate,
  });
}
