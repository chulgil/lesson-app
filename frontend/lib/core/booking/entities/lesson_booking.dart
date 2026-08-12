// Lesson booking domain entities
// Moved from lib/features/schedule/domain/entities/lesson_booking.dart for Clean Architecture

import '../../domain/value_objects/clock_time.dart';
import 'time_slot.dart';

/// Lesson type enum
enum LessonType {
  trial, // 체험 레슨
  regular, // 정규 레슨
  oneTime, // 1회 레슨
}

/// Schedule type for regular lessons
enum ScheduleType {
  fixed, // 고정 시간
  flexible, // 유동 시간
}

/// Booking status enum
enum BookingStatus {
  pending, // 대기 중 (신청 완료)
  confirmed, // 확정 (선생님 승인)
  changeRequested, // 변경 요청 중
  completed, // 완료
  cancelled, // 취소
  unavailable, // 일정 조율 필요 (선생님이 해당 시간 불가)
  expired; // 응답 대기 만료 (48시간 초과)

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

/// Lesson goal enum (for trial lessons)
enum LessonGoal {
  hobby, // 취미
  exam, // 입시
  major, // 전공
}

/// Experience level enum (for trial lessons)
enum ExperienceLevel {
  none, // 처음
  beginner, // 1년 미만
  some, // 1-3년
  experienced; // 3년 이상

  /// Map from StudentLevel to ExperienceLevel
  /// Used when existing student requests trial lesson for new instrument
  static ExperienceLevel fromStudentLevel(dynamic studentLevel) {
    // Handle StudentLevel enum from student.dart
    final levelName = studentLevel.toString().split('.').last;
    switch (levelName) {
      case 'beginner': // 입문 → 1년 미만
      case 'elementary': // 초급 → 1년 미만
        return ExperienceLevel.beginner;
      case 'intermediate': // 중급 → 1-3년
        return ExperienceLevel.some;
      case 'advanced': // 고급 → 3년 이상
        return ExperienceLevel.experienced;
      default:
        return ExperienceLevel.none;
    }
  }
}

/// Schedule option for multi-option booking system
/// Students can propose 1-3 options with priority ranking
///
/// **DEPRECATED**: Part of the old multi-option scheduling system.
/// The new system uses [AvailabilitySlot] for single time slot selection.
/// Kept for backward compatibility with existing bookings.
@Deprecated('Use AvailabilitySlot for new bookings. Will be removed in v2.0.')
class ScheduleOption {
  final String id;
  final int priority; // 1 = highest priority, 2, 3

  // For single lessons (trial, one-time)
  final DateTime? date;
  final ClockTime? startTime;
  final ClockTime? endTime;

  // For regular lessons (weekly schedule)
  final int? dayOfWeek; // 1 = Monday, 7 = Sunday
  final DateTime? startDate; // When regular lessons start

  // For weekly 2x lessons (second slot)
  final int? secondDayOfWeek;
  final ClockTime? secondStartTime;
  final ClockTime? secondEndTime;

  const ScheduleOption({
    required this.id,
    required this.priority,
    this.date,
    this.startTime,
    this.endTime,
    this.dayOfWeek,
    this.startDate,
    this.secondDayOfWeek,
    this.secondStartTime,
    this.secondEndTime,
  });

  /// Check if this is a single lesson option (trial/one-time)
  bool get isSingleLesson => date != null;

  /// Check if this is a regular lesson option
  bool get isRegularLesson => dayOfWeek != null;

  /// Check if this is a weekly 2x lesson option
  bool get isWeekly2x => secondDayOfWeek != null;

  ScheduleOption copyWith({
    String? id,
    int? priority,
    DateTime? date,
    ClockTime? startTime,
    ClockTime? endTime,
    int? dayOfWeek,
    DateTime? startDate,
    int? secondDayOfWeek,
    ClockTime? secondStartTime,
    ClockTime? secondEndTime,
  }) {
    return ScheduleOption(
      id: id ?? this.id,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      secondDayOfWeek: secondDayOfWeek ?? this.secondDayOfWeek,
      secondStartTime: secondStartTime ?? this.secondStartTime,
      secondEndTime: secondEndTime ?? this.secondEndTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
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
  final ClockTime startTime;
  final ClockTime endTime;
  final int durationMinutes;
  final int fee;
  final ScheduleType? scheduleType; // For regular lessons
  final TimeSlot? fixedTimeSlot; // For fixed schedule
  final int? lessonsPerWeek; // 1 or 2 for regular lessons
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
  final DateTime? requestedDate; // Requested new date
  final ClockTime? requestedStartTime; // Requested new start time
  final ClockTime? requestedEndTime; // Requested new end time
  final DateTime? changeRequestedAt; // When change was requested
  // Unavailable fields (for unavailable status - replaces rejected)
  final String? unavailableMessage; // Free text reason
  final List<TimeSlot>? suggestedTimeSlots; // Teacher's alternative suggestions
  final DateTime? unavailableAt; // When marked unavailable
  final DateTime? expiredAt; // When auto-expired (48h timeout)
  // Multi-option schedule fields (Phase 1)
  final List<ScheduleOption>?
  scheduleOptions; // 1-3 options proposed by student
  final String? selectedOptionId; // ID of option selected by teacher
  // Link to UnifiedLessonRequest (for trial → request detail navigation)
  final String? requestId;
  // #301: standalone 주N회 등록 시 교사 기존 일정과 충돌해 건너뛴 회차 수 (응답 전용).
  final int recurringSkippedCount;
  // student_direct_booking_spec.md §6 — 예약이 연결된 수강권. BE 가 없으면
  // teacher-student 활성 수강권을 자동 연결(생성은 하지 않음). null 이면 정규권 외 예약.
  final String? subscriptionId;

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
    this.lessonsPerWeek,
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
    this.unavailableMessage,
    this.suggestedTimeSlots,
    this.unavailableAt,
    this.expiredAt,
    this.scheduleOptions,
    this.selectedOptionId,
    this.requestId,
    this.recurringSkippedCount = 0,
    this.subscriptionId,
  });

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

  /// Check if booking has suggested alternatives
  bool get hasSuggestedTimes =>
      suggestedTimeSlots != null && suggestedTimeSlots!.isNotEmpty;

  // Multi-option schedule helpers
  /// Check if booking has schedule options
  bool get hasScheduleOptions =>
      scheduleOptions != null && scheduleOptions!.isNotEmpty;

  /// Get schedule options count
  int get scheduleOptionsCount => scheduleOptions?.length ?? 0;

  /// Get selected option
  ScheduleOption? get selectedOption {
    // isEmpty guard mirrors primaryOption — the orElse below does `.first`,
    // which throws StateError on an empty (non-null) option list (#1243).
    if (selectedOptionId == null || !hasScheduleOptions) return null;
    return scheduleOptions!.firstWhere(
      (opt) => opt.id == selectedOptionId,
      orElse: () => scheduleOptions!.first,
    );
  }

  /// Get schedule options sorted by priority
  List<ScheduleOption> get sortedScheduleOptions {
    if (scheduleOptions == null) return [];
    final sorted = List<ScheduleOption>.from(scheduleOptions!);
    sorted.sort((a, b) => a.priority.compareTo(b.priority));
    return sorted;
  }

  /// Get primary option (priority 1)
  ScheduleOption? get primaryOption {
    if (scheduleOptions == null || scheduleOptions!.isEmpty) return null;
    return scheduleOptions!.firstWhere(
      (opt) => opt.priority == 1,
      orElse: () => scheduleOptions!.first,
    );
  }

  /// Check if teacher has selected an option
  bool get hasSelectedOption => selectedOptionId != null;

  /// Check if booking is awaiting teacher selection
  bool get isAwaitingSelection =>
      status == BookingStatus.pending &&
      hasScheduleOptions &&
      !hasSelectedOption;

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
    ClockTime? startTime,
    ClockTime? endTime,
    int? durationMinutes,
    int? fee,
    ScheduleType? scheduleType,
    TimeSlot? fixedTimeSlot,
    int? lessonsPerWeek,
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
    ClockTime? requestedStartTime,
    ClockTime? requestedEndTime,
    DateTime? changeRequestedAt,
    String? unavailableMessage,
    List<TimeSlot>? suggestedTimeSlots,
    DateTime? unavailableAt,
    DateTime? expiredAt,
    List<ScheduleOption>? scheduleOptions,
    String? selectedOptionId,
    int? recurringSkippedCount,
    String? subscriptionId,
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
      lessonsPerWeek: lessonsPerWeek ?? this.lessonsPerWeek,
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
      unavailableMessage: unavailableMessage ?? this.unavailableMessage,
      suggestedTimeSlots: suggestedTimeSlots ?? this.suggestedTimeSlots,
      unavailableAt: unavailableAt ?? this.unavailableAt,
      expiredAt: expiredAt ?? this.expiredAt,
      scheduleOptions: scheduleOptions ?? this.scheduleOptions,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      recurringSkippedCount:
          recurringSkippedCount ?? this.recurringSkippedCount,
      subscriptionId: subscriptionId ?? this.subscriptionId,
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
/// Now supports multi-option scheduling (1-3 options with priority)
class TrialLessonRequest {
  final String? studentId;
  final String studentName;
  final String? studentPhone;
  final String? studentEmail;
  final LessonGoal goal;
  final ExperienceLevel experience;
  final String? message;
  // Multi-option schedule support
  final List<ScheduleOption> scheduleOptions;
  // Legacy single option (for backward compatibility)
  final DateTime? preferredDate;
  final ClockTime? preferredStartTime;
  final ClockTime? preferredEndTime;

  const TrialLessonRequest({
    this.studentId,
    required this.studentName,
    this.studentPhone,
    this.studentEmail,
    required this.goal,
    required this.experience,
    this.message,
    this.scheduleOptions = const [],
    // Legacy fields (deprecated, use scheduleOptions instead)
    this.preferredDate,
    this.preferredStartTime,
    this.preferredEndTime,
  });

  /// Check if using multi-option scheduling
  bool get hasMultipleOptions => scheduleOptions.isNotEmpty;

  /// Get primary schedule option
  ScheduleOption? get primaryOption {
    if (scheduleOptions.isEmpty) return null;
    return scheduleOptions.firstWhere(
      (opt) => opt.priority == 1,
      orElse: () => scheduleOptions.first,
    );
  }

  /// Get effective date (from primary option or legacy field)
  DateTime get effectiveDate {
    if (hasMultipleOptions && primaryOption?.date != null) {
      return primaryOption!.date!;
    }
    return preferredDate ?? DateTime.now();
  }

  /// Get effective start time (from primary option or legacy field)
  ClockTime get effectiveStartTime {
    if (hasMultipleOptions && primaryOption?.startTime != null) {
      return primaryOption!.startTime!;
    }
    return preferredStartTime ?? const ClockTime(hour: 14, minute: 0);
  }

  /// Get effective end time (from primary option or legacy field)
  ClockTime get effectiveEndTime {
    if (hasMultipleOptions && primaryOption?.endTime != null) {
      return primaryOption!.endTime!;
    }
    return preferredEndTime ?? const ClockTime(hour: 15, minute: 0);
  }

  /// Convert to LessonBooking
  LessonBooking toBooking({
    required String id,
    required String teacherId,
    required String teacherName,
    required int fee,
    String? subscriptionId,
  }) {
    return LessonBooking(
      id: id,
      teacherId: teacherId,
      teacherName: teacherName,
      studentId: studentId,
      studentName: studentName,
      lessonType: LessonType.trial,
      status: BookingStatus.pending,
      lessonDate: effectiveDate,
      startTime: effectiveStartTime,
      endTime: effectiveEndTime,
      fee: fee,
      subscriptionId: subscriptionId,
      studentPhone: studentPhone,
      studentEmail: studentEmail,
      lessonGoal: goal,
      experienceLevel: experience,
      studentMessage: message,
      createdAt: DateTime.now(),
      scheduleOptions: hasMultipleOptions ? scheduleOptions : null,
    );
  }
}

/// Regular lesson registration model
class RegularLessonRegistration {
  final String studentId;
  final ScheduleType scheduleType;
  final List<TimeSlot> fixedTimeSlots; // 주N회: N concurrent weekly slots
  final int lessonsPerWeek;
  final int monthlyFee;
  final DateTime startDate;
  final String?
  academyId; // Optional: academy ID if lesson is linked to academy
  final bool isAcademyPrivate; // If true, set visibility to academyBusyOnly

  const RegularLessonRegistration({
    required this.studentId,
    required this.scheduleType,
    this.fixedTimeSlots = const [],
    this.lessonsPerWeek = 1,
    required this.monthlyFee,
    required this.startDate,
    this.academyId,
    this.isAcademyPrivate = false,
  });

  TimeSlot? get primaryTimeSlot =>
      fixedTimeSlots.isEmpty ? null : fixedTimeSlots.first;
}

/// Regular lesson request model (student-initiated, requires teacher approval)
/// Supports multi-option scheduling with day-of-week based schedule
class RegularLessonRequest {
  final String studentId;
  final String studentName;
  final String? studentPhone;
  final String? studentEmail;
  final int lessonsPerWeek; // 1 or 2
  final List<ScheduleOption> scheduleOptions; // 1-3 options with priority
  final DateTime preferredStartDate;
  final String? message;

  const RegularLessonRequest({
    required this.studentId,
    required this.studentName,
    this.studentPhone,
    this.studentEmail,
    this.lessonsPerWeek = 1,
    this.scheduleOptions = const [],
    required this.preferredStartDate,
    this.message,
  });

  /// Check if using multi-option scheduling
  bool get hasMultipleOptions => scheduleOptions.length > 1;

  /// Get primary schedule option
  ScheduleOption? get primaryOption {
    if (scheduleOptions.isEmpty) return null;
    return scheduleOptions.firstWhere(
      (opt) => opt.priority == 1,
      orElse: () => scheduleOptions.first,
    );
  }

  /// Convert to LessonBooking (pending status for teacher approval)
  LessonBooking toBooking({
    required String id,
    required String teacherId,
    required String teacherName,
    int monthlyFee = 200000,
  }) {
    final primary = primaryOption;

    // Calculate first lesson date based on preferred start and day of week
    DateTime firstLessonDate = preferredStartDate;
    if (primary?.dayOfWeek != null) {
      while (firstLessonDate.weekday != primary!.dayOfWeek) {
        firstLessonDate = firstLessonDate.add(const Duration(days: 1));
      }
    }

    return LessonBooking(
      id: id,
      teacherId: teacherId,
      teacherName: teacherName,
      studentId: studentId,
      studentName: studentName,
      lessonType: LessonType.regular,
      status: BookingStatus.pending,
      lessonDate: firstLessonDate,
      startTime: primary?.startTime ?? const ClockTime(hour: 14, minute: 0),
      endTime: primary?.endTime ?? const ClockTime(hour: 15, minute: 0),
      fee: monthlyFee,
      studentPhone: studentPhone,
      studentEmail: studentEmail,
      studentMessage: message,
      scheduleType: ScheduleType.fixed,
      lessonsPerWeek: lessonsPerWeek,
      createdAt: DateTime.now(),
      scheduleOptions: scheduleOptions.isNotEmpty ? scheduleOptions : null,
    );
  }
}
