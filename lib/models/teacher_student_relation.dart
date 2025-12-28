import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Teacher-Student relationship status
enum RelationStatus {
  /// No prior history - first time meeting
  none,
  /// Currently in regular lessons
  active,
  /// Had lessons before but currently inactive
  inactive,
}

/// Available lesson types based on relationship
enum LessonType {
  /// Trial lesson for first meeting
  trial,
  /// Regular recurring lessons
  regular,
  /// One-time additional lesson
  oneTime,
}

extension LessonTypeExtension on LessonType {
  String get label {
    switch (this) {
      case LessonType.trial:
        return '체험 레슨';
      case LessonType.regular:
        return '정기 레슨';
      case LessonType.oneTime:
        return '1회 추가 레슨';
    }
  }

  String get description {
    switch (this) {
      case LessonType.trial:
        return '첫 만남을 위한 1회 레슨';
      case LessonType.regular:
        return '매주 고정 시간 레슨';
      case LessonType.oneTime:
        return '단발성 추가 레슨';
    }
  }

  IconData get icon {
    switch (this) {
      case LessonType.trial:
        return Icons.music_note;
      case LessonType.regular:
        return Icons.calendar_today;
      case LessonType.oneTime:
        return Icons.add_circle_outline;
    }
  }

  Color get color {
    switch (this) {
      case LessonType.trial:
        return AppColors.info;
      case LessonType.regular:
        return AppColors.primary;
      case LessonType.oneTime:
        return AppColors.secondary;
    }
  }
}

/// Teacher-Student relationship model
class TeacherStudentRelation {
  final String teacherId;
  final String studentId;
  final RelationStatus status;
  final DateTime? lastLessonDate;
  final int totalLessonCount;

  const TeacherStudentRelation({
    required this.teacherId,
    required this.studentId,
    required this.status,
    this.lastLessonDate,
    this.totalLessonCount = 0,
  });

  /// Get available lesson types based on relationship status
  List<LessonType> get availableLessonTypes {
    switch (status) {
      case RelationStatus.none:
        return [LessonType.trial];
      case RelationStatus.active:
        return [LessonType.oneTime];
      case RelationStatus.inactive:
        return [LessonType.regular, LessonType.oneTime];
    }
  }

  /// Check if trial lesson is available
  bool get canRequestTrial => status == RelationStatus.none;

  /// Check if regular lesson is available
  bool get canRequestRegular => status == RelationStatus.inactive;

  /// Check if one-time lesson is available
  bool get canRequestOneTime =>
      status == RelationStatus.active || status == RelationStatus.inactive;

  /// Status display label
  String get statusLabel {
    switch (status) {
      case RelationStatus.none:
        return '처음 만남';
      case RelationStatus.active:
        return '정규레슨 진행중';
      case RelationStatus.inactive:
        return '이전 레슨 이력';
    }
  }

  /// Status badge color
  Color get statusColor {
    switch (status) {
      case RelationStatus.none:
        return AppColors.info;
      case RelationStatus.active:
        return AppColors.practiceGood;
      case RelationStatus.inactive:
        return AppColors.textTertiaryLight;
    }
  }

  TeacherStudentRelation copyWith({
    String? teacherId,
    String? studentId,
    RelationStatus? status,
    DateTime? lastLessonDate,
    int? totalLessonCount,
  }) {
    return TeacherStudentRelation(
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      lastLessonDate: lastLessonDate ?? this.lastLessonDate,
      totalLessonCount: totalLessonCount ?? this.totalLessonCount,
    );
  }
}
