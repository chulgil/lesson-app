// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_confirmation_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleConfirmationCard _$ScheduleConfirmationCardFromJson(
        Map<String, dynamic> json) =>
    ScheduleConfirmationCard(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      instrument: json['instrument'] as String?,
      subscriptionId: json['subscription_id'] as String,
      suggestedDay: (json['suggested_day'] as num?)?.toInt(),
      suggestedTime: json['suggested_time'] as String?,
      lessonDuration: (json['lesson_duration'] as num?)?.toInt(),
      cardType: $enumDecode(_$ScheduleCardTypeEnumMap, json['card_type']),
      status:
          $enumDecodeNullable(_$ScheduleCardStatusEnumMap, json['status']) ??
              ScheduleCardStatus.pending,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
      totalLessons: (json['total_lessons'] as num?)?.toInt(),
      lessonRequestId: json['lesson_request_id'] as String?,
      suggestedDay2: (json['suggested_day2'] as num?)?.toInt(),
      suggestedTime2: json['suggested_time2'] as String?,
      suggestedDay3: (json['suggested_day3'] as num?)?.toInt(),
      suggestedTime3: json['suggested_time3'] as String?,
    );

Map<String, dynamic> _$ScheduleConfirmationCardToJson(
        ScheduleConfirmationCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'teacher_id': instance.teacherId,
      'teacher_name': instance.teacherName,
      'instrument': instance.instrument,
      'subscription_id': instance.subscriptionId,
      'suggested_day': instance.suggestedDay,
      'suggested_time': instance.suggestedTime,
      'lesson_duration': instance.lessonDuration,
      'card_type': _$ScheduleCardTypeEnumMap[instance.cardType]!,
      'status': _$ScheduleCardStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'responded_at': instance.respondedAt?.toIso8601String(),
      'total_lessons': instance.totalLessons,
      'lesson_request_id': instance.lessonRequestId,
      'suggested_day2': instance.suggestedDay2,
      'suggested_time2': instance.suggestedTime2,
      'suggested_day3': instance.suggestedDay3,
      'suggested_time3': instance.suggestedTime3,
    };

const _$ScheduleCardTypeEnumMap = {
  ScheduleCardType.afterTrial: 'afterTrial',
  ScheduleCardType.reEnrollment: 'reEnrollment',
  ScheduleCardType.additionalInstrument: 'additionalInstrument',
};

const _$ScheduleCardStatusEnumMap = {
  ScheduleCardStatus.pending: 'pending',
  ScheduleCardStatus.confirmed: 'confirmed',
  ScheduleCardStatus.changedTime: 'changedTime',
  ScheduleCardStatus.dismissed: 'dismissed',
};
