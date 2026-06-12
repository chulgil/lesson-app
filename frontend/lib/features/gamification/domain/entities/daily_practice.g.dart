// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_practice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyPractice _$DailyPracticeFromJson(Map<String, dynamic> json) =>
    DailyPractice(
      metronomeMinutes: (json['metronome_minutes'] as num?)?.toInt() ?? 0,
      tunerMinutes: (json['tuner_minutes'] as num?)?.toInt() ?? 0,
      youtubeMinutes: (json['youtube_minutes'] as num?)?.toInt() ?? 0,
      recordingCount: (json['recording_count'] as num?)?.toInt() ?? 0,
      manualMinutes: (json['manual_minutes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DailyPracticeToJson(DailyPractice instance) =>
    <String, dynamic>{
      'metronome_minutes': instance.metronomeMinutes,
      'tuner_minutes': instance.tunerMinutes,
      'youtube_minutes': instance.youtubeMinutes,
      'recording_count': instance.recordingCount,
      'manual_minutes': instance.manualMinutes,
    };
