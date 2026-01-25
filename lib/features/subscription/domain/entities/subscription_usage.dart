import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_usage.g.dart';

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

  SubscriptionUsage({
    required this.id,
    required this.subscriptionId,
    this.lessonId,
    required this.usedAt,
    this.teacherName,
    this.instrument,
    this.note,
    required this.createdAt,
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
    );
  }

  @override
  String toString() {
    return 'SubscriptionUsage(id: $id, subscriptionId: $subscriptionId, usedAt: $usedAt)';
  }
}
