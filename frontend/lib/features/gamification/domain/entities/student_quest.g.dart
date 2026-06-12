// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_quest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuest _$StudentQuestFromJson(Map<String, dynamic> json) => StudentQuest(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      origin: $enumDecode(_$QuestOriginEnumMap, json['origin']),
      title: json['title'] as String,
      type: $enumDecodeNullable(_$ChallengeTypeEnumMap, json['type']),
      targetValue: (json['target_value'] as num).toInt(),
      currentValue: (json['current_value'] as num).toInt(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$StudentQuestToJson(StudentQuest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'origin': _$QuestOriginEnumMap[instance.origin]!,
      'title': instance.title,
      'type': _$ChallengeTypeEnumMap[instance.type],
      'target_value': instance.targetValue,
      'current_value': instance.currentValue,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt?.toIso8601String(),
    };

const _$QuestOriginEnumMap = {
  QuestOrigin.ambient: 'ambient',
  QuestOrigin.selfCreated: 'selfCreated',
  QuestOrigin.systemRoutine: 'systemRoutine',
  QuestOrigin.lessonDerived: 'lessonDerived',
  QuestOrigin.teacherRec: 'teacherRec',
  QuestOrigin.seasonEvent: 'seasonEvent',
};

const _$ChallengeTypeEnumMap = {
  ChallengeType.practiceDays: 'practiceDays',
  ChallengeType.practiceMinutes: 'practiceMinutes',
  ChallengeType.recordings: 'recordings',
  ChallengeType.lessons: 'lessons',
  ChallengeType.streak: 'streak',
  ChallengeType.pointsEarned: 'pointsEarned',
};
