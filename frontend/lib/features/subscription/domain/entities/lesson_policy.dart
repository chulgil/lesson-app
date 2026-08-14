import 'package:json_annotation/json_annotation.dart';

part 'lesson_policy.g.dart';

/// Lesson policy settings for teachers/academies.
@JsonSerializable()
class LessonPolicy {
  final String id;

  /// Associated lesson class ID. Null means teacher's default policy.
  final String? lessonClassId;

  final String teacherId;

  // ===== 변경/취소 정책 =====

  /// Minimum hours before lesson to cancel (e.g., 4 = 4시간 전까지)
  final int minCancelHours;

  /// Maximum schedule changes per month (e.g., 2 = 월 2회)
  final int maxChangesPerMonth;

  /// Allow same-day cancellation
  final bool allowSameDayCancel;

  /// Late cancel deadline time (e.g., "20:00" = 전날 20:00까지)
  final String? lateCancelDeadline;

  // ===== 노쇼 정책 =====

  /// Deduct lesson count on no-show
  final bool deductLessonOnNoShow;

  /// Grace period for lateness in minutes (e.g., 15 = 15분 지각 허용)
  final int gracePeriodMinutes;

  // ===== 이월 정책 (월정액) =====

  /// Allow carryover of unused lessons
  final bool allowCarryover;

  /// Maximum lessons to carry over
  final int maxCarryoverLessons;

  /// Carryover validity period in months
  final int carryoverPeriodMonths;

  // ===== 환불 정책 =====
  // #1271 환불 요청 플로우에서 참고용 예상 환불액 산정에 사용 (외부 이체
  // 수기 처리 — 인앱 결제/PG 자동 환불은 여전히 범위 외).
  // 산식: features/subscription/presentation/utils/refund_estimate_calculator.dart

  final int fullRefundDays;

  final double partialRefundRatio;

  final double halfwayRefundRatio;

  final double noShowRefundRatio;

  // ===== 메타 =====

  final DateTime createdAt;

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

  factory LessonPolicy.fromJson(Map<String, dynamic> json) =>
      _$LessonPolicyFromJson(json);

  Map<String, dynamic> toJson() => _$LessonPolicyToJson(this);
}
