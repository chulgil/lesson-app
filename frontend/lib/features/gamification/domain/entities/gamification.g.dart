// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentGamification _$StudentGamificationFromJson(Map<String, dynamic> json) =>
    StudentGamification(
      studentId: json['student_id'] as String,
      totalPoints: (json['total_points'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      levelTitle: json['level_title'] as String,
      pointsToNextLevel: (json['points_to_next_level'] as num).toInt(),
      currentLevelMinPoints: (json['current_level_min_points'] as num).toInt(),
      nextLevelMinPoints: (json['next_level_min_points'] as num).toInt(),
      earnedBadges: (json['earned_badges'] as List<dynamic>?)
              ?.map((e) => PracticeBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentHistory: (json['recent_history'] as List<dynamic>?)
              ?.map((e) => PointHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$StudentGamificationToJson(
        StudentGamification instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'total_points': instance.totalPoints,
      'level': instance.level,
      'level_title': instance.levelTitle,
      'points_to_next_level': instance.pointsToNextLevel,
      'current_level_min_points': instance.currentLevelMinPoints,
      'next_level_min_points': instance.nextLevelMinPoints,
      'earned_badges': instance.earnedBadges.map((e) => e.toJson()).toList(),
      'recent_history': instance.recentHistory.map((e) => e.toJson()).toList(),
    };

PointHistory _$PointHistoryFromJson(Map<String, dynamic> json) => PointHistory(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      points: (json['points'] as num).toInt(),
      type: $enumDecode(_$PointTypeEnumMap, json['type']),
      description: json['description'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );

Map<String, dynamic> _$PointHistoryToJson(PointHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'points': instance.points,
      'type': _$PointTypeEnumMap[instance.type]!,
      'description': instance.description,
      'earned_at': instance.earnedAt.toIso8601String(),
    };

const _$PointTypeEnumMap = {
  PointType.practiceComplete: 'practiceComplete',
  PointType.streakBonus: 'streakBonus',
  PointType.lessonAttendance: 'lessonAttendance',
  PointType.goalAchieved: 'goalAchieved',
  PointType.badgeEarned: 'badgeEarned',
};

PracticeBadge _$PracticeBadgeFromJson(Map<String, dynamic> json) =>
    PracticeBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      rarity: $enumDecode(_$BadgeRarityEnumMap, json['rarity']),
      earnedAt: json['earned_at'] == null
          ? null
          : DateTime.parse(json['earned_at'] as String),
      isEarned: json['is_earned'] as bool? ?? false,
    );

Map<String, dynamic> _$PracticeBadgeToJson(PracticeBadge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'rarity': _$BadgeRarityEnumMap[instance.rarity]!,
      'earned_at': instance.earnedAt?.toIso8601String(),
      'is_earned': instance.isEarned,
    };

const _$BadgeRarityEnumMap = {
  BadgeRarity.common: 'common',
  BadgeRarity.rare: 'rare',
  BadgeRarity.epic: 'epic',
  BadgeRarity.legendary: 'legendary',
};

LevelDefinition _$LevelDefinitionFromJson(Map<String, dynamic> json) =>
    LevelDefinition(
      level: (json['level'] as num).toInt(),
      title: json['title'] as String,
      minPoints: (json['min_points'] as num).toInt(),
    );

Map<String, dynamic> _$LevelDefinitionToJson(LevelDefinition instance) =>
    <String, dynamic>{
      'level': instance.level,
      'title': instance.title,
      'min_points': instance.minPoints,
    };
