// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spotlight_prompt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpotlightPrompt _$SpotlightPromptFromJson(Map<String, dynamic> json) =>
    SpotlightPrompt(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      type: $enumDecode(_$SpotlightTypeEnumMap, json['type']),
      title: json['title'] as String,
      videoId: json['video_id'] as String?,
      ctaRoute: json['cta_route'] as String?,
      queuedAt: DateTime.parse(json['queued_at'] as String),
      declineCount: (json['decline_count'] as num?)?.toInt() ?? 0,
      hideUntil: json['hide_until'] == null
          ? null
          : DateTime.parse(json['hide_until'] as String),
      permanentlyHidden: json['permanently_hidden'] as bool? ?? false,
      lastShownAt: json['last_shown_at'] == null
          ? null
          : DateTime.parse(json['last_shown_at'] as String),
      isMandatory: json['is_mandatory'] as bool? ?? false,
    );

Map<String, dynamic> _$SpotlightPromptToJson(SpotlightPrompt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'type': _$SpotlightTypeEnumMap[instance.type]!,
      'title': instance.title,
      'video_id': instance.videoId,
      'cta_route': instance.ctaRoute,
      'queued_at': instance.queuedAt.toIso8601String(),
      'decline_count': instance.declineCount,
      'hide_until': instance.hideUntil?.toIso8601String(),
      'permanently_hidden': instance.permanentlyHidden,
      'last_shown_at': instance.lastShownAt?.toIso8601String(),
      'is_mandatory': instance.isMandatory,
    };

const _$SpotlightTypeEnumMap = {
  SpotlightType.teacherRec: 'teacherRec',
  SpotlightType.seasonEvent: 'seasonEvent',
  SpotlightType.routineSuggestion: 'routineSuggestion',
};
