// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_sticker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JourneySticker _$JourneyStickerFromJson(Map<String, dynamic> json) =>
    JourneySticker(
      key: json['key'] as String,
      family: $enumDecode(_$StickerFamilyEnumMap, json['family']),
      metric: json['metric'] as String,
      tier: (json['tier'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      current: (json['current'] as num).toInt(),
      achieved: json['achieved'] as bool,
      unit: $enumDecode(_$StickerUnitEnumMap, json['unit']),
    );

Map<String, dynamic> _$JourneyStickerToJson(JourneySticker instance) =>
    <String, dynamic>{
      'key': instance.key,
      'family': _$StickerFamilyEnumMap[instance.family]!,
      'metric': instance.metric,
      'tier': instance.tier,
      'target': instance.target,
      'current': instance.current,
      'achieved': instance.achieved,
      'unit': _$StickerUnitEnumMap[instance.unit]!,
    };

const _$StickerFamilyEnumMap = {
  StickerFamily.practice: 'practice',
  StickerFamily.journey: 'journey',
  StickerFamily.streak: 'streak',
  StickerFamily.growth: 'growth',
};

const _$StickerUnitEnumMap = {
  StickerUnit.minutes: 'minutes',
  StickerUnit.days: 'days',
  StickerUnit.count: 'count',
};

JourneyStickerCatalog _$JourneyStickerCatalogFromJson(
        Map<String, dynamic> json) =>
    JourneyStickerCatalog(
      studentId: json['student_id'] as String,
      stickers: (json['stickers'] as List<dynamic>?)
              ?.map((e) => JourneySticker.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$JourneyStickerCatalogToJson(
        JourneyStickerCatalog instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'stickers': instance.stickers.map((e) => e.toJson()).toList(),
    };
