// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_evidence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeEvidence _$PracticeEvidenceFromJson(Map<String, dynamic> json) =>
    PracticeEvidence(
      source: $enumDecode(_$PracticeSourceEnumMap, json['source']),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      videoId: json['video_id'] as String?,
      sectionId: json['section_id'] as String?,
    );

Map<String, dynamic> _$PracticeEvidenceToJson(PracticeEvidence instance) =>
    <String, dynamic>{
      'source': _$PracticeSourceEnumMap[instance.source]!,
      'duration_minutes': instance.durationMinutes,
      'video_id': instance.videoId,
      'section_id': instance.sectionId,
      'metadata': instance.metadata,
      'occurred_at': instance.occurredAt.toIso8601String(),
    };

const _$PracticeSourceEnumMap = {
  PracticeSource.metronome: 'metronome',
  PracticeSource.tuner: 'tuner',
  PracticeSource.youtube: 'youtube',
  PracticeSource.recording: 'recording',
  PracticeSource.manual: 'manual',
};
