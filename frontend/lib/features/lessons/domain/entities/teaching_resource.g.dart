// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teaching_resource.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachingResource _$TeachingResourceFromJson(Map<String, dynamic> json) =>
    TeachingResource(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      type: $enumDecode(_$TeachingResourceTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      youtubeVideoId: json['youtube_video_id'] as String?,
      youtubeThumbnail: json['youtube_thumbnail'] as String?,
      youtubeStartSeconds: (json['youtube_start_seconds'] as num?)?.toInt(),
      youtubeEndSeconds: (json['youtube_end_seconds'] as num?)?.toInt(),
      audioUrl: json['audio_url'] as String?,
      audioDurationSeconds: (json['audio_duration_seconds'] as num?)?.toInt(),
      externalUrl: json['external_url'] as String?,
      instrument: json['instrument'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TeachingResourceToJson(TeachingResource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'type': _$TeachingResourceTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'youtube_url': instance.youtubeUrl,
      'youtube_video_id': instance.youtubeVideoId,
      'youtube_thumbnail': instance.youtubeThumbnail,
      'youtube_start_seconds': instance.youtubeStartSeconds,
      'youtube_end_seconds': instance.youtubeEndSeconds,
      'audio_url': instance.audioUrl,
      'audio_duration_seconds': instance.audioDurationSeconds,
      'external_url': instance.externalUrl,
      'instrument': instance.instrument,
      'tags': instance.tags,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$TeachingResourceTypeEnumMap = {
  TeachingResourceType.teacherRecording: 'teacherRecording',
  TeachingResourceType.youtube: 'youtube',
  TeachingResourceType.externalLink: 'externalLink',
};
