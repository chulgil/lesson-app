// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Badge _$BadgeFromJson(Map<String, dynamic> json) => Badge(
      id: json['id'] as String,
      type: $enumDecode(_$BadgeTypeEnumMap, json['type']),
      isEarned: json['is_earned'] as bool? ?? false,
      earnedAt: json['earned_at'] == null
          ? null
          : DateTime.parse(json['earned_at'] as String),
    );

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$BadgeTypeEnumMap[instance.type]!,
      'is_earned': instance.isEarned,
      'earned_at': instance.earnedAt?.toIso8601String(),
    };

const _$BadgeTypeEnumMap = {
  BadgeType.firstPractice: 'firstPractice',
  BadgeType.streak3: 'streak3',
  BadgeType.streak7: 'streak7',
  BadgeType.streak30: 'streak30',
  BadgeType.streak100: 'streak100',
  BadgeType.perfectWeek: 'perfectWeek',
  BadgeType.mustMaster: 'mustMaster',
  BadgeType.practiceKing: 'practiceKing',
  BadgeType.firstPiece: 'firstPiece',
  BadgeType.fivePieces: 'fivePieces',
  BadgeType.challengeKing: 'challengeKing',
  BadgeType.practiceRepeat10: 'practiceRepeat10',
  BadgeType.practiceRepeat50: 'practiceRepeat50',
  BadgeType.practiceRepeat100: 'practiceRepeat100',
  BadgeType.firstLike: 'firstLike',
  BadgeType.lovedStudent: 'lovedStudent',
  BadgeType.performance: 'performance',
};
