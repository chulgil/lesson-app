// No-Show Policy entity
// Spec: docs/specs/lesson/lesson_schedule.md - 노쇼 정책 시스템

import 'package:hive/hive.dart';

part 'no_show_policy.g.dart';

/// 노쇼 정책 - 선생님이 설정
@HiveType(typeId: 88)
enum NoShowPolicy {
  @HiveField(0)
  deductCredit, // 기본값: 회차 차감

  @HiveField(1)
  halfCredit, // 0.5회 차감

  @HiveField(2)
  noDeduction, // 차감 없음 (관대한 정책)

  @HiveField(3)
  reschedule; // 보강으로 전환

  String get label {
    switch (this) {
      case NoShowPolicy.deductCredit:
        return '회차 차감';
      case NoShowPolicy.halfCredit:
        return '0.5회 차감';
      case NoShowPolicy.noDeduction:
        return '차감 없음';
      case NoShowPolicy.reschedule:
        return '보강으로 전환';
    }
  }

  String get description {
    switch (this) {
      case NoShowPolicy.deductCredit:
        return '무단 결석 시 1회 차감됩니다';
      case NoShowPolicy.halfCredit:
        return '무단 결석 시 0.5회 차감됩니다';
      case NoShowPolicy.noDeduction:
        return '무단 결석 시에도 차감되지 않습니다';
      case NoShowPolicy.reschedule:
        return '무단 결석 시 보강 1회로 전환됩니다';
    }
  }

  /// 차감 비율 (회차권 기준)
  double get deductionRate {
    switch (this) {
      case NoShowPolicy.deductCredit:
        return 1.0;
      case NoShowPolicy.halfCredit:
        return 0.5;
      case NoShowPolicy.noDeduction:
        return 0.0;
      case NoShowPolicy.reschedule:
        return 0.0; // 보강으로 전환되므로 차감 없음
    }
  }

  /// 보강 생성 여부
  bool get createsMakeup => this == NoShowPolicy.reschedule;
}

/// 노쇼 기록
@HiveType(typeId: 89)
class NoShowRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String lessonId;

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final String teacherId;

  @HiveField(4)
  final DateTime lessonDate;

  @HiveField(5)
  final NoShowPolicy appliedPolicy;

  /// 차감된 회차 (0, 0.5, 1)
  @HiveField(6)
  final double deductedCredits;

  /// 생성된 보강 ID (reschedule 정책인 경우)
  @HiveField(7)
  final String? makeupLessonId;

  @HiveField(8)
  final DateTime createdAt;

  /// 노쇼 처리 담당자 (자동 또는 선생님 ID)
  @HiveField(9)
  final String processedBy;

  /// 추가 메모
  @HiveField(10)
  final String? note;

  NoShowRecord({
    required this.id,
    required this.lessonId,
    required this.studentId,
    required this.teacherId,
    required this.lessonDate,
    required this.appliedPolicy,
    required this.deductedCredits,
    this.makeupLessonId,
    required this.createdAt,
    required this.processedBy,
    this.note,
  });

  NoShowRecord copyWith({
    String? id,
    String? lessonId,
    String? studentId,
    String? teacherId,
    DateTime? lessonDate,
    NoShowPolicy? appliedPolicy,
    double? deductedCredits,
    String? makeupLessonId,
    DateTime? createdAt,
    String? processedBy,
    String? note,
  }) {
    return NoShowRecord(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      lessonDate: lessonDate ?? this.lessonDate,
      appliedPolicy: appliedPolicy ?? this.appliedPolicy,
      deductedCredits: deductedCredits ?? this.deductedCredits,
      makeupLessonId: makeupLessonId ?? this.makeupLessonId,
      createdAt: createdAt ?? this.createdAt,
      processedBy: processedBy ?? this.processedBy,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoShowRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
