import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_slot.g.dart';

/// A recurring lesson time slot within a week.
///
/// Used by [ClassMembership] and [Student] to store per-day lesson schedules.
/// Supports multiple slots per week (e.g., Tue 14:00 + Thu 16:00).
@HiveType(typeId: 130)
@JsonSerializable()
class LessonSlot {
  @HiveField(0)
  final int dayOfWeek; // 0=Mon...6=Sun (matches TimeSlotOption convention)

  @HiveField(1)
  final String startTime; // "HH:mm"

  @HiveField(2)
  final String endTime; // "HH:mm"

  const LessonSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory LessonSlot.fromJson(Map<String, dynamic> json) =>
      _$LessonSlotFromJson(json);

  Map<String, dynamic> toJson() => _$LessonSlotToJson(this);

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  /// Short day label: "화"
  String get dayLabel => _dayLabels[dayOfWeek.clamp(0, 6)];

  /// Short display: "화 14:00"
  String get shortLabel => '$dayLabel $startTime';

  LessonSlot copyWith({int? dayOfWeek, String? startTime, String? endTime}) {
    return LessonSlot(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
