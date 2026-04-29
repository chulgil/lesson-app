import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/l10n/app_strings.dart';

part 'subscription_usage.g.dart';

/// Usage type for subscription deduction
@HiveType(typeId: 77)
enum UsageType {
  @HiveField(0)
  normal, // 정상 레슨 완료

  @HiveField(1)
  lateCancellation, // 당일 취소 (24시간 이내)

  @HiveField(2)
  studentAbsent, // 학생 결석/노쇼

  @HiveField(3)
  rescheduled; // 변경/보충 레슨

  String get label {
    switch (this) {
      case UsageType.normal:
        return AppStrings.usageTypeNormal;
      case UsageType.lateCancellation:
        return AppStrings.usageTypeLateCancellation;
      case UsageType.studentAbsent:
        return AppStrings.usageTypeStudentAbsent;
      case UsageType.rescheduled:
        return AppStrings.usageTypeRescheduled;
    }
  }

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
@HiveType(typeId: 63)
@JsonSerializable()
class SubscriptionUsage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subscriptionId; // FK -> Subscription

  @HiveField(2)
  final String? lessonId; // FK -> Lesson (optional, for linking)

  @HiveField(3)
  final DateTime usedAt; // Usage date/time

  @HiveField(4)
  final String? teacherName; // Teacher name at time of usage

  @HiveField(5)
  final String? instrument; // Instrument at time of usage

  @HiveField(6)
  final String? note; // Additional note

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final UsageType usageType; // Usage type (normal, lateCancellation, etc.)

  @HiveField(9)
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
      note: note ?? AppStrings.usageNoteLateCancellation,
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
      note: note ?? AppStrings.usageTypeStudentAbsent,
      createdAt: DateTime.now(),
      usageType: UsageType.studentAbsent,
      deducted: true,
    );
  }
}
