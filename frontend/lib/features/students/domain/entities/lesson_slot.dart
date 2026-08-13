import 'package:json_annotation/json_annotation.dart';

part 'lesson_slot.g.dart';

/// A recurring lesson time slot within a week.
///
/// Used by [ClassMembership] and [Student] to store per-day lesson schedules.
/// Supports multiple slots per week (e.g., Tue 14:00 + Thu 16:00).
@JsonSerializable()
class LessonSlot {
  final int dayOfWeek; // 0=Mon...6=Sun (matches TimeSlotOption convention)

  final String startTime; // "HH:mm"

  final String endTime; // "HH:mm"

  const LessonSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory LessonSlot.fromJson(Map<String, dynamic> json) =>
      _$LessonSlotFromJson(json);

  Map<String, dynamic> toJson() => _$LessonSlotToJson(this);

  LessonSlot copyWith({int? dayOfWeek, String? startTime, String? endTime}) {
    return LessonSlot(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
