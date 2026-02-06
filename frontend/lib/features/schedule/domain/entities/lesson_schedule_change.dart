// Lesson Schedule Change entity for tracking regular lesson time changes
// Spec: docs/specs/lesson/lesson_schedule.md - 정기 레슨 일괄 시간 변경

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_schedule_change.g.dart';

/// 스케줄 변경 유형
@HiveType(typeId: 90)
enum ScheduleChangeType {
  @HiveField(0)
  singleLesson, // 1회성 변경 (이번 주만)

  @HiveField(1)
  bulkChange; // 일괄 변경 (앞으로 모든 레슨)

  String get label {
    switch (this) {
      case ScheduleChangeType.singleLesson:
        return '이번 주만';
      case ScheduleChangeType.bulkChange:
        return '앞으로 모두';
    }
  }

  String get description {
    switch (this) {
      case ScheduleChangeType.singleLesson:
        return '이번 주 레슨만 시간을 변경합니다';
      case ScheduleChangeType.bulkChange:
        return '앞으로 모든 레슨 시간을 변경합니다';
    }
  }
}

/// 변경 요청 상태
@HiveType(typeId: 91)
enum ScheduleChangeStatus {
  @HiveField(0)
  pending, // 대기 중

  @HiveField(1)
  approved, // 승인됨

  @HiveField(2)
  rejected, // 거절됨

  @HiveField(3)
  alternativeProposed, // 대안 제시됨

  @HiveField(4)
  cancelled; // 취소됨

  String get label {
    switch (this) {
      case ScheduleChangeStatus.pending:
        return '대기 중';
      case ScheduleChangeStatus.approved:
        return '승인됨';
      case ScheduleChangeStatus.rejected:
        return '거절됨';
      case ScheduleChangeStatus.alternativeProposed:
        return '대안 제시';
      case ScheduleChangeStatus.cancelled:
        return '취소됨';
    }
  }

  bool get isPending => this == ScheduleChangeStatus.pending;
  bool get isResolved =>
      this == ScheduleChangeStatus.approved ||
      this == ScheduleChangeStatus.rejected ||
      this == ScheduleChangeStatus.cancelled;
}

/// 정기 레슨 시간 변경 요청/이력
@HiveType(typeId: 92)
@JsonSerializable()
class LessonScheduleChange extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String teacherId;

  /// 변경 유형 (1회성 / 일괄)
  @HiveField(3)
  final ScheduleChangeType changeType;

  /// 기존 요일 (0=월, 6=일)
  @HiveField(4)
  final int? previousDayOfWeek;

  /// 기존 시간 (HH:mm 형식)
  @HiveField(5)
  final String? previousTime;

  /// 새 요일
  @HiveField(6)
  final int? newDayOfWeek;

  /// 새 시간
  @HiveField(7)
  final String? newTime;

  /// 적용 시작일
  @HiveField(8)
  final DateTime effectiveFrom;

  /// 요청 상태
  @HiveField(9)
  final ScheduleChangeStatus status;

  /// 요청 시각
  @HiveField(10)
  final DateTime requestedAt;

  /// 처리 시각
  @HiveField(11)
  final DateTime? processedAt;

  /// 요청 사유
  @HiveField(12)
  final String? requestReason;

  /// 거절/대안 사유
  @HiveField(13)
  final String? responseMessage;

  /// 대안 시간들 (alternativeProposed 상태일 때)
  @HiveField(14)
  final List<String>? alternativeTimes;

  /// 요청자 (student 또는 teacher)
  @HiveField(15)
  final String requestedBy;

  LessonScheduleChange({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.changeType,
    this.previousDayOfWeek,
    this.previousTime,
    this.newDayOfWeek,
    this.newTime,
    required this.effectiveFrom,
    this.status = ScheduleChangeStatus.pending,
    required this.requestedAt,
    this.processedAt,
    this.requestReason,
    this.responseMessage,
    this.alternativeTimes,
    required this.requestedBy,
  });

  /// 요일 표시 (0=월 → "월요일")
  static String dayOfWeekLabel(int day) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    if (day < 0 || day > 6) return '';
    return '${days[day]}요일';
  }

  /// 기존 스케줄 문자열
  String get previousScheduleLabel {
    if (previousDayOfWeek == null || previousTime == null) return '-';
    return '${dayOfWeekLabel(previousDayOfWeek!)} $previousTime';
  }

  /// 새 스케줄 문자열
  String get newScheduleLabel {
    if (newDayOfWeek == null || newTime == null) return '-';
    return '${dayOfWeekLabel(newDayOfWeek!)} $newTime';
  }

  /// 변경 요약
  String get changeSummary {
    return '$previousScheduleLabel → $newScheduleLabel';
  }

  LessonScheduleChange copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    ScheduleChangeType? changeType,
    int? previousDayOfWeek,
    String? previousTime,
    int? newDayOfWeek,
    String? newTime,
    DateTime? effectiveFrom,
    ScheduleChangeStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? requestReason,
    String? responseMessage,
    List<String>? alternativeTimes,
    String? requestedBy,
  }) {
    return LessonScheduleChange(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      changeType: changeType ?? this.changeType,
      previousDayOfWeek: previousDayOfWeek ?? this.previousDayOfWeek,
      previousTime: previousTime ?? this.previousTime,
      newDayOfWeek: newDayOfWeek ?? this.newDayOfWeek,
      newTime: newTime ?? this.newTime,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      requestReason: requestReason ?? this.requestReason,
      responseMessage: responseMessage ?? this.responseMessage,
      alternativeTimes: alternativeTimes ?? this.alternativeTimes,
      requestedBy: requestedBy ?? this.requestedBy,
    );
  }

  factory LessonScheduleChange.fromJson(Map<String, dynamic> json) =>
      _$LessonScheduleChangeFromJson(json);

  Map<String, dynamic> toJson() => _$LessonScheduleChangeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonScheduleChange &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
