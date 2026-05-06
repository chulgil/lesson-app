// Makeup Lesson entity for tracking makeup/rescheduled lessons
// Spec: docs/specs/lesson/lesson_schedule.md - 보강 추적 시스템

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'makeup_lesson.g.dart';

/// 보강 상태
@HiveType(typeId: 85)
enum MakeupStatus {
  @HiveField(0)
  pending, // 시간 미정

  @HiveField(1)
  scheduled, // 시간 확정

  @HiveField(2)
  completed, // 완료

  @HiveField(3)
  expired, // 만료 (30일)

  @HiveField(4)
  waived; // 선생님이 면제 처리

  bool get isActive =>
      this == MakeupStatus.pending || this == MakeupStatus.scheduled;
}

/// 보강 발생 사유
@HiveType(typeId: 86)
enum MakeupReason {
  @HiveField(0)
  studentCancellation, // 학생 취소 (D-1 이전)

  @HiveField(1)
  teacherCancellation, // 선생님 취소

  @HiveField(2)
  noShowReschedule, // 노쇼 (reschedule 정책)

  @HiveField(3)
  other, // 기타
}

/// 보강 레슨 엔티티
@HiveType(typeId: 87)
@JsonSerializable()
class MakeupLesson extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String teacherId;

  /// 원래 레슨 ID (취소/노쇼된)
  @HiveField(3)
  final String? originalLessonId;

  /// 보강 레슨 ID (예약된)
  @HiveField(4)
  final String? scheduledLessonId;

  @HiveField(5)
  final MakeupStatus status;

  @HiveField(6)
  final MakeupReason reason;

  @HiveField(7)
  final DateTime createdAt;

  /// 보강 만료일 (기본 30일)
  @HiveField(8)
  final DateTime expiresAt;

  /// 보강 예약 완료일
  @HiveField(9)
  final DateTime? scheduledAt;

  /// 보강 완료일
  @HiveField(10)
  final DateTime? completedAt;

  /// 추가 메모
  @HiveField(11)
  final String? note;

  MakeupLesson({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.originalLessonId,
    this.scheduledLessonId,
    this.status = MakeupStatus.pending,
    required this.reason,
    required this.createdAt,
    required this.expiresAt,
    this.scheduledAt,
    this.completedAt,
    this.note,
  });

  /// 30일 만료로 새 보강 생성
  factory MakeupLesson.create({
    required String id,
    required String studentId,
    required String teacherId,
    String? originalLessonId,
    required MakeupReason reason,
    String? note,
  }) {
    final now = DateTime.now();
    return MakeupLesson(
      id: id,
      studentId: studentId,
      teacherId: teacherId,
      originalLessonId: originalLessonId,
      reason: reason,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      note: note,
    );
  }

  /// 남은 일수
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// 만료 임박 여부 (7일 이내)
  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;

  MakeupLesson copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? originalLessonId,
    String? scheduledLessonId,
    MakeupStatus? status,
    MakeupReason? reason,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? note,
  }) {
    return MakeupLesson(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      originalLessonId: originalLessonId ?? this.originalLessonId,
      scheduledLessonId: scheduledLessonId ?? this.scheduledLessonId,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
    );
  }

  factory MakeupLesson.fromJson(Map<String, dynamic> json) =>
      _$MakeupLessonFromJson(json);

  Map<String, dynamic> toJson() => _$MakeupLessonToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MakeupLesson &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
