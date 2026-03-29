// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklyRankingEntry _$WeeklyRankingEntryFromJson(Map<String, dynamic> json) =>
    WeeklyRankingEntry(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      weeklyPoints: (json['weekly_points'] as num).toInt(),
      tier: $enumDecode(_$RankingTierEnumMap, json['tier']),
      rank: (json['rank'] as num).toInt(),
    );

Map<String, dynamic> _$WeeklyRankingEntryToJson(WeeklyRankingEntry instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'student_name': instance.studentName,
      'weekly_points': instance.weeklyPoints,
      'tier': _$RankingTierEnumMap[instance.tier]!,
      'rank': instance.rank,
    };

const _$RankingTierEnumMap = {
  RankingTier.gold: 'gold',
  RankingTier.silver: 'silver',
  RankingTier.bronze: 'bronze',
};

WeeklyRanking _$WeeklyRankingFromJson(Map<String, dynamic> json) =>
    WeeklyRanking(
      classId: json['class_id'] as String,
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => WeeklyRankingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WeeklyRankingToJson(WeeklyRanking instance) =>
    <String, dynamic>{
      'class_id': instance.classId,
      'week_start_date': instance.weekStartDate.toIso8601String(),
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };
