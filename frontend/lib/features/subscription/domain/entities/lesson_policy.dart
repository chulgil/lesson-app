import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_policy.g.dart';

/// Lesson policy settings for teachers/academies.
@HiveType(typeId: 70)
@JsonSerializable()
class LessonPolicy extends HiveObject {
  @HiveField(0)
  final String id;

  /// Associated lesson class ID. Null means teacher's default policy.
  @HiveField(1)
  final String? lessonClassId;

  @HiveField(2)
  final String teacherId;

  // ===== 변경/취소 정책 =====

  /// Minimum hours before lesson to cancel (e.g., 4 = 4시간 전까지)
  @HiveField(3)
  final int minCancelHours;

  /// Maximum schedule changes per month (e.g., 2 = 월 2회)
  @HiveField(4)
  final int maxChangesPerMonth;

  /// Allow same-day cancellation
  @HiveField(5)
  final bool allowSameDayCancel;

  /// Late cancel deadline time (e.g., "20:00" = 전날 20:00까지)
  @HiveField(6)
  final String? lateCancelDeadline;

  // ===== 노쇼 정책 =====

  /// Deduct lesson count on no-show
  @HiveField(7)
  final bool deductLessonOnNoShow;

  /// Grace period for lateness in minutes (e.g., 15 = 15분 지각 허용)
  @HiveField(8)
  final int gracePeriodMinutes;

  // ===== 이월 정책 (월정액) =====

  /// Allow carryover of unused lessons
  @HiveField(9)
  final bool allowCarryover;

  /// Maximum lessons to carry over
  @HiveField(10)
  final int maxCarryoverLessons;

  /// Carryover validity period in months
  @HiveField(11)
  final int carryoverPeriodMonths;

  // ===== 환불 정책 — 보류 (2026-04-21) =====
  // 앱 내 결제 기능 미구현으로 환불 UI를 연결하지 않는다.
  // 스펙: docs/specs/subscription/lesson_policy_settings.md §4 "보류".
  // Hive typeId 유지를 위해 필드 자체는 삭제하지 않는다 (기존 저장 데이터 호환).

  @HiveField(14)
  final int fullRefundDays;

  @HiveField(15)
  final double partialRefundRatio;

  @HiveField(16)
  final double halfwayRefundRatio;

  @HiveField(17)
  final double noShowRefundRatio;

  // ===== 메타 =====

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime? updatedAt;

  LessonPolicy({
    required this.id,
    this.lessonClassId,
    required this.teacherId,
    this.minCancelHours = 4,
    this.maxChangesPerMonth = 2,
    this.allowSameDayCancel = false,
    this.lateCancelDeadline,
    this.deductLessonOnNoShow = true,
    this.gracePeriodMinutes = 15,
    this.allowCarryover = true,
    this.maxCarryoverLessons = 1,
    this.carryoverPeriodMonths = 1,
    this.fullRefundDays = 1,
    this.partialRefundRatio = 0.67,
    this.halfwayRefundRatio = 0.0,
    this.noShowRefundRatio = 0.67,
    required this.createdAt,
    this.updatedAt,
  });

  /// Default policy for new teachers
  factory LessonPolicy.defaultPolicy({
    required String id,
    required String teacherId,
    String? lessonClassId,
  }) {
    return LessonPolicy(
      id: id,
      teacherId: teacherId,
      lessonClassId: lessonClassId,
      minCancelHours: 4,
      maxChangesPerMonth: 2,
      allowSameDayCancel: false,
      lateCancelDeadline: '20:00',
      deductLessonOnNoShow: true,
      gracePeriodMinutes: 15,
      allowCarryover: true,
      maxCarryoverLessons: 1,
      carryoverPeriodMonths: 1,
      createdAt: DateTime.now(),
    );
  }

  LessonPolicy copyWith({
    String? id,
    String? lessonClassId,
    String? teacherId,
    int? minCancelHours,
    int? maxChangesPerMonth,
    bool? allowSameDayCancel,
    String? lateCancelDeadline,
    bool? deductLessonOnNoShow,
    int? gracePeriodMinutes,
    bool? allowCarryover,
    int? maxCarryoverLessons,
    int? carryoverPeriodMonths,
    int? fullRefundDays,
    double? partialRefundRatio,
    double? halfwayRefundRatio,
    double? noShowRefundRatio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonPolicy(
      id: id ?? this.id,
      lessonClassId: lessonClassId ?? this.lessonClassId,
      teacherId: teacherId ?? this.teacherId,
      minCancelHours: minCancelHours ?? this.minCancelHours,
      maxChangesPerMonth: maxChangesPerMonth ?? this.maxChangesPerMonth,
      allowSameDayCancel: allowSameDayCancel ?? this.allowSameDayCancel,
      lateCancelDeadline: lateCancelDeadline ?? this.lateCancelDeadline,
      deductLessonOnNoShow: deductLessonOnNoShow ?? this.deductLessonOnNoShow,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      allowCarryover: allowCarryover ?? this.allowCarryover,
      maxCarryoverLessons: maxCarryoverLessons ?? this.maxCarryoverLessons,
      carryoverPeriodMonths:
          carryoverPeriodMonths ?? this.carryoverPeriodMonths,
      fullRefundDays: fullRefundDays ?? this.fullRefundDays,
      partialRefundRatio: partialRefundRatio ?? this.partialRefundRatio,
      halfwayRefundRatio: halfwayRefundRatio ?? this.halfwayRefundRatio,
      noShowRefundRatio: noShowRefundRatio ?? this.noShowRefundRatio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===== Display helpers =====

  /// 취소 정책 요약 텍스트
  String get cancelPolicySummary {
    if (allowSameDayCancel) {
      return '당일 취소 가능';
    }
    return '$minCancelHours시간 전까지 취소 가능';
  }

  /// 변경 정책 요약 텍스트
  String get changePolicySummary {
    if (maxChangesPerMonth == 0) {
      return '변경 불가';
    }
    if (maxChangesPerMonth >= 99) {
      return '무제한 변경 가능';
    }
    return '월 $maxChangesPerMonth회 변경 가능';
  }

  /// 노쇼 정책 요약 텍스트
  String get noShowPolicySummary {
    if (deductLessonOnNoShow) {
      return '노쇼 시 횟수 차감';
    }
    return '노쇼 시 횟수 유지';
  }

  /// 이월 정책 요약 텍스트
  String get carryoverPolicySummary {
    if (!allowCarryover) {
      return '이월 불가';
    }
    return '최대 $maxCarryoverLessons회 이월 ($carryoverPeriodMonths개월 내)';
  }

  factory LessonPolicy.fromJson(Map<String, dynamic> json) =>
      _$LessonPolicyFromJson(json);

  Map<String, dynamic> toJson() => _$LessonPolicyToJson(this);
}
