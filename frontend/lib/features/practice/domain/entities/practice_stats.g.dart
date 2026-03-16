// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeStats _$PracticeStatsFromJson(Map<String, dynamic> json) =>
    PracticeStats(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalDays: (json['total_days'] as num).toInt(),
      practicedDays: (json['practiced_days'] as num).toInt(),
      totalMinutes: (json['total_minutes'] as num).toInt(),
      averageMinutesPerDay: (json['average_minutes_per_day'] as num).toDouble(),
    );

Map<String, dynamic> _$PracticeStatsToJson(PracticeStats instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'total_days': instance.totalDays,
      'practiced_days': instance.practicedDays,
      'total_minutes': instance.totalMinutes,
      'average_minutes_per_day': instance.averageMinutesPerDay,
    };
