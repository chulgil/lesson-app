import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_request.g.dart';

/// Preferred timing for starting lessons
@HiveType(typeId: 98)
enum PreferredStartTiming {
  /// Next week
  @HiveField(0)
  nextWeek,

  /// Next month
  @HiveField(1)
  nextMonth,

  /// After consultation with teacher
  @HiveField(2)
  afterConsultation,
}

/// Extension for PreferredStartTiming
extension PreferredStartTimingExtension on PreferredStartTiming {
  String get label {
    switch (this) {
      case PreferredStartTiming.nextWeek:
        return '다음 주';
      case PreferredStartTiming.nextMonth:
        return '다음 달';
      case PreferredStartTiming.afterConsultation:
        return '상담 후 결정';
    }
  }
}

/// Status of a lesson request
@HiveType(typeId: 99)
enum LessonRequestStatus {
  /// Request sent, waiting for teacher response
  @HiveField(0)
  pending,

  /// Teacher sent a subscription proposal
  @HiveField(1)
  proposalSent,

  /// Student accepted and payment completed
  @HiveField(2)
  accepted,

  /// Teacher declined the request
  @HiveField(3)
  declined,

  /// Request expired (7 days)
  @HiveField(4)
  expired,

  /// Student cancelled the request
  @HiveField(5)
  cancelled,
}

/// Extension for LessonRequestStatus
extension LessonRequestStatusExtension on LessonRequestStatus {
  String get label {
    switch (this) {
      case LessonRequestStatus.pending:
        return '요청 대기';
      case LessonRequestStatus.proposalSent:
        return '수강권 제안됨';
      case LessonRequestStatus.accepted:
        return '수락됨';
      case LessonRequestStatus.declined:
        return '레슨 불가';
      case LessonRequestStatus.expired:
        return '만료됨';
      case LessonRequestStatus.cancelled:
        return '취소됨';
    }
  }

  bool get isActive =>
      this == LessonRequestStatus.pending ||
      this == LessonRequestStatus.proposalSent;

  bool get isTerminal =>
      this == LessonRequestStatus.accepted ||
      this == LessonRequestStatus.declined ||
      this == LessonRequestStatus.expired ||
      this == LessonRequestStatus.cancelled;
}

/// Lesson request from student to previous teacher.
///
/// Used when a student (past status) wants to resume lessons with a teacher.
/// Flow:
/// 1. Student creates request with message and schedule preference
/// 2. Teacher receives notification
/// 3. Teacher sends subscription proposal (or declines)
/// 4. Student accepts and makes payment
/// 5. Teacher confirms → subscription issued with schedule restoration
@HiveType(typeId: 100)
@JsonSerializable()
class LessonRequest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String teacherId;

  /// Optional message from student
  @HiveField(3)
  final String? message;

  /// Preferred timing for starting lessons
  @HiveField(4)
  final PreferredStartTiming preferredTiming;

  /// Whether to keep the previous schedule
  @HiveField(5)
  final bool keepPreviousSchedule;

  /// Previous schedule day (1=Mon to 7=Sun)
  @HiveField(6)
  final int? previousLessonDay;

  /// Previous schedule time (HH:mm)
  @HiveField(7)
  final String? previousLessonTime;

  /// Previous lesson duration in minutes
  @HiveField(8)
  final int? previousLessonDuration;

  /// Current status
  @HiveField(9)
  final LessonRequestStatus status;

  /// When the request was created
  @HiveField(10)
  final DateTime createdAt;

  /// When the request expires (7 days after creation)
  @HiveField(11)
  final DateTime expiresAt;

  /// Linked subscription proposal ID (when teacher responds)
  @HiveField(12)
  final String? proposalId;

  /// Teacher's decline reason (if declined)
  @HiveField(13)
  final String? declineReason;

  /// When the status was last updated
  @HiveField(14)
  final DateTime? statusUpdatedAt;

  LessonRequest({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.message,
    this.preferredTiming = PreferredStartTiming.nextWeek,
    this.keepPreviousSchedule = true,
    this.previousLessonDay,
    this.previousLessonTime,
    this.previousLessonDuration,
    this.status = LessonRequestStatus.pending,
    required this.createdAt,
    required this.expiresAt,
    this.proposalId,
    this.declineReason,
    this.statusUpdatedAt,
  });

  factory LessonRequest.fromJson(Map<String, dynamic> json) =>
      _$LessonRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LessonRequestToJson(this);

  /// Whether the request has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the request is still active
  bool get isActive => status.isActive && !isExpired;

  /// Whether the request has a previous schedule
  bool get hasPreviousSchedule =>
      previousLessonDay != null && previousLessonTime != null;

  /// Time remaining until expiration
  Duration get timeUntilExpiration => expiresAt.difference(DateTime.now());

  /// Formatted expiration time
  String get formattedExpiration {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) {
      return '만료됨';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 후 만료';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 후 만료';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 후 만료';
    }
    return '곧 만료';
  }

  LessonRequest copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? message,
    PreferredStartTiming? preferredTiming,
    bool? keepPreviousSchedule,
    int? previousLessonDay,
    String? previousLessonTime,
    int? previousLessonDuration,
    LessonRequestStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? proposalId,
    String? declineReason,
    DateTime? statusUpdatedAt,
  }) {
    return LessonRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      message: message ?? this.message,
      preferredTiming: preferredTiming ?? this.preferredTiming,
      keepPreviousSchedule: keepPreviousSchedule ?? this.keepPreviousSchedule,
      previousLessonDay: previousLessonDay ?? this.previousLessonDay,
      previousLessonTime: previousLessonTime ?? this.previousLessonTime,
      previousLessonDuration:
          previousLessonDuration ?? this.previousLessonDuration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      proposalId: proposalId ?? this.proposalId,
      declineReason: declineReason ?? this.declineReason,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    );
  }

  @override
  String toString() =>
      'LessonRequest(id: $id, status: $status, student: $studentId, teacher: $teacherId)';
}
