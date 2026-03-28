import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'lesson_slot.dart';

part 'class_membership.g.dart';

/// Membership status in a class.
@HiveType(typeId: 53)
enum MembershipStatus {
  @HiveField(0)
  trial, // Trial period

  @HiveField(1)
  active, // Active regular enrollment

  @HiveField(2)
  paused, // On hold

  @HiveField(3)
  terminated, // Terminated
}

/// Student's membership in a class (LessonClass) with lesson information.
@HiveType(typeId: 54)
@JsonSerializable()
class ClassMembership extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String lessonClassId; // Class ID (FK -> LessonClass)

  @HiveField(2)
  final String studentId; // Student ID (FK -> Student)

  // Lesson info for this class
  @HiveField(3)
  final String instrument; // Instrument (piano, violin, etc.)

  @HiveField(4)
  final MembershipStatus status; // trial/active/paused/terminated

  @HiveField(5)
  final String? level; // Level (beginner/elementary/intermediate/advanced)

  // Fee info
  @HiveField(6)
  final int monthlyFee; // Monthly tuition fee

  @HiveField(7)
  final int lessonsPerWeek; // Lessons per week (1 or 2)

  // Lesson schedule
  @HiveField(8)
  final List<LessonSlot> lessonSlots;

  @HiveField(10)
  final int lessonDuration; // Lesson duration in minutes (default 60)

  // Notes
  @HiveField(11)
  final String? notes; // Special notes

  // Location & travel
  @HiveField(14)
  final String? lessonLocationId; // Default lesson location for this membership

  @HiveField(15)
  final int travelTimeMinutes; // Teacher's travel time to this student (minutes)

  // Meta
  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
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

  /// Status display label in Korean.
  String get statusLabel {
    switch (status) {
      case MembershipStatus.trial:
        return '체험중';
      case MembershipStatus.active:
        return '수강중';
      case MembershipStatus.paused:
        return '휴강';
      case MembershipStatus.terminated:
        return '종료';
    }
  }

  LessonSlot? get primarySlot => lessonSlots.isNotEmpty ? lessonSlots.first : null;

  String? get scheduleDisplay => lessonSlots.isNotEmpty
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
