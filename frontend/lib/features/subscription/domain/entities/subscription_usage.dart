import 'package:json_annotation/json_annotation.dart';

part 'subscription_usage.g.dart';

/// Usage type for subscription deduction
enum UsageType {
  normal, // 정상 레슨 완료

  lateCancellation, // 당일 취소 (24시간 이내)

  studentAbsent, // 학생 결석/노쇼

  rescheduled; // 변경/보충 레슨

  /// Whether this usage type results in subscription deduction
  bool get isDeducted {
    switch (this) {
      case UsageType.normal:
      case UsageType.lateCancellation:
      case UsageType.studentAbsent:
        return true;
      case UsageType.rescheduled:
        return false; // 변경 수업은 별도 차감 없음 (원래 레슨에서 차감됨)
    }
  }
}

/// Subscription usage record entity.
/// Tracks each lesson usage from a subscription.
@JsonSerializable()
class SubscriptionUsage {
  final String id;

  final String subscriptionId; // FK -> Subscription

  final String? lessonId; // FK -> Lesson (optional, for linking)

  final DateTime usedAt; // Usage date/time

  final String? teacherName; // Teacher name at time of usage

  final String? instrument; // Instrument at time of usage

  final String? note; // Additional note

  final DateTime createdAt;

  final UsageType usageType; // Usage type (normal, lateCancellation, etc.)

  final bool deducted; // Whether this usage was deducted from subscription

  SubscriptionUsage({
    required this.id,
    required this.subscriptionId,
    this.lessonId,
    required this.usedAt,
    this.teacherName,
    this.instrument,
    this.note,
    required this.createdAt,
    this.usageType = UsageType.normal,
    this.deducted = true,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionUsageFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionUsageToJson(this);

  SubscriptionUsage copyWith({
    String? id,
    String? subscriptionId,
    String? lessonId,
    DateTime? usedAt,
    String? teacherName,
    String? instrument,
    String? note,
    DateTime? createdAt,
    UsageType? usageType,
    bool? deducted,
  }) {
    return SubscriptionUsage(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      lessonId: lessonId ?? this.lessonId,
      usedAt: usedAt ?? this.usedAt,
      teacherName: teacherName ?? this.teacherName,
      instrument: instrument ?? this.instrument,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      usageType: usageType ?? this.usageType,
      deducted: deducted ?? this.deducted,
    );
  }

  @override
  String toString() {
    return 'SubscriptionUsage(id: $id, subscriptionId: $subscriptionId, usedAt: $usedAt, usageType: $usageType, deducted: $deducted)';
  }

  /// Create usage for normal lesson completion
  factory SubscriptionUsage.forLesson({
    required String id,
    required String subscriptionId,
    required String lessonId,
    required DateTime usedAt,
    String? teacherName,
    String? instrument,
    String? note,
  }) {
    return SubscriptionUsage(
      id: id,
      subscriptionId: subscriptionId,
      lessonId: lessonId,
      usedAt: usedAt,
      teacherName: teacherName,
      instrument: instrument,
      note: note,
      createdAt: DateTime.now(),
      usageType: UsageType.normal,
      deducted: true,
    );
  }

  /// Create usage for late cancellation (within 24 hours)
  factory SubscriptionUsage.forLateCancellation({
    required String id,
    required String subscriptionId,
    required String lessonId,
    required DateTime usedAt,
    String? teacherName,
    String? instrument,
    String? note,
  }) {
    return SubscriptionUsage(
      id: id,
      subscriptionId: subscriptionId,
      lessonId: lessonId,
      usedAt: usedAt,
      teacherName: teacherName,
      instrument: instrument,
      note: note,
      createdAt: DateTime.now(),
      usageType: UsageType.lateCancellation,
      deducted: true,
    );
  }

  /// Create usage for student absence/no-show
  factory SubscriptionUsage.forAbsence({
    required String id,
    required String subscriptionId,
    required String lessonId,
    required DateTime usedAt,
    String? teacherName,
    String? instrument,
    String? note,
  }) {
    return SubscriptionUsage(
      id: id,
      subscriptionId: subscriptionId,
      lessonId: lessonId,
      usedAt: usedAt,
      teacherName: teacherName,
      instrument: instrument,
      note: note,
      createdAt: DateTime.now(),
      usageType: UsageType.studentAbsent,
      deducted: true,
    );
  }
}
