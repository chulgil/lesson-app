import 'package:json_annotation/json_annotation.dart';

import 'lesson_slot.dart';

part 'class_membership.g.dart';

/// Membership status in a class.
enum MembershipStatus {
  trial, // Trial period

  active, // Active regular enrollment

  paused, // On hold

  terminated, // Terminated
}

/// Student's membership in a class (LessonClass) with lesson information.
@JsonSerializable()
class ClassMembership {
  final String id;

  final String lessonClassId; // Class ID (FK -> LessonClass)

  final String studentId; // Student ID (FK -> Student)

  // Lesson info for this class
  final String instrument; // Instrument (piano, violin, etc.)

  final MembershipStatus status; // trial/active/paused/terminated

  final String? level; // Level (beginner/elementary/intermediate/advanced)

  // Fee info
  final int monthlyFee; // Monthly tuition fee

  final int lessonsPerWeek; // Lessons per week (1 or 2)

  // Lesson schedule
  final List<LessonSlot> lessonSlots;

  final int lessonDuration; // Lesson duration in minutes (default 60)

  // Notes
  final String? notes; // Special notes

  // Location & travel
  final String? lessonLocationId; // Default lesson location for this membership

  final int travelTimeMinutes; // Teacher's travel time to this student (minutes)

  // Meta
  final DateTime createdAt;

  final DateTime? updatedAt;

  ClassMembership({
    required this.id,
    required this.lessonClassId,
    required this.studentId,
    required this.instrument,
    required this.status,
    this.level,
    required this.monthlyFee,
    this.lessonsPerWeek = 1,
    this.lessonSlots = const [],
    this.lessonDuration = 60,
    this.notes,
    this.lessonLocationId,
    this.travelTimeMinutes = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClassMembership.fromJson(Map<String, dynamic> json) =>
      _$ClassMembershipFromJson(json);

  Map<String, dynamic> toJson() => _$ClassMembershipToJson(this);

  /// Calculated monthly lesson count.
  int get monthlyLessonCount => lessonsPerWeek * 4;

  /// Calculated fee per lesson.
  int get lessonFee =>
      monthlyLessonCount > 0 ? (monthlyFee / monthlyLessonCount).round() : 0;

  /// Check if membership is currently active (trial or active).
  bool get isEnrolled =>
      status == MembershipStatus.trial || status == MembershipStatus.active;

  LessonSlot? get primarySlot =>
      lessonSlots.isNotEmpty ? lessonSlots.first : null;

  String? get scheduleDisplay =>
      lessonSlots.isNotEmpty
          ? lessonSlots.map((s) => s.shortLabel).join(', ')
          : null;

  ClassMembership copyWith({
    String? id,
    String? lessonClassId,
    String? studentId,
    String? instrument,
    MembershipStatus? status,
    String? level,
    int? monthlyFee,
    int? lessonsPerWeek,
    List<LessonSlot>? lessonSlots,
    int? lessonDuration,
    String? notes,
    String? lessonLocationId,
    int? travelTimeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassMembership(
      id: id ?? this.id,
      lessonClassId: lessonClassId ?? this.lessonClassId,
      studentId: studentId ?? this.studentId,
      instrument: instrument ?? this.instrument,
      status: status ?? this.status,
      level: level ?? this.level,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      lessonsPerWeek: lessonsPerWeek ?? this.lessonsPerWeek,
      lessonSlots: lessonSlots ?? this.lessonSlots,
      lessonDuration: lessonDuration ?? this.lessonDuration,
      notes: notes ?? this.notes,
      lessonLocationId: lessonLocationId ?? this.lessonLocationId,
      travelTimeMinutes: travelTimeMinutes ?? this.travelTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ClassMembership(id: $id, studentId: $studentId, instrument: $instrument, status: $status)';
}
