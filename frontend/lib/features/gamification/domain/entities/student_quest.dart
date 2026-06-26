import 'package:json_annotation/json_annotation.dart';

import 'challenge.dart';
import 'quest_origin.dart';

part 'student_quest.g.dart';

/// 학생 자가 quest — 학생이 작성/채택한 연습 목표.
///
/// 스펙 §5.1.b / 플랜 Job 1 Task 1.2. 선생님 quest 와 별 시스템.
@JsonSerializable()
class StudentQuest {
  final String id;
  final String studentId;
  final QuestOrigin origin;
  final String title;
  final ActivityType? type;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final DateTime? completedAt;

  const StudentQuest({
    required this.id,
    required this.studentId,
    required this.origin,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.completedAt,
  });

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  StudentQuest copyWith({
    int? currentValue,
    bool? isCompleted,
    DateTime? completedAt,
  }) => StudentQuest(
    id: id,
    studentId: studentId,
    origin: origin,
    title: title,
    type: type,
    targetValue: targetValue,
    currentValue: currentValue ?? this.currentValue,
    startDate: startDate,
    endDate: endDate,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
  );

  factory StudentQuest.fromJson(Map<String, dynamic> json) =>
      _$StudentQuestFromJson(json);

  Map<String, dynamic> toJson() => _$StudentQuestToJson(this);
}
