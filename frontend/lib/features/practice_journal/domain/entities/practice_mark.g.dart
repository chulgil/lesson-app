// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_mark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeMark _$PracticeMarkFromJson(Map<String, dynamic> json) => PracticeMark(
      date: DateTime.parse(json['date'] as String),
      intensity: $enumDecode(_$MarkIntensityEnumMap, json['intensity']),
    );

Map<String, dynamic> _$PracticeMarkToJson(PracticeMark instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'intensity': _$MarkIntensityEnumMap[instance.intensity]!,
    };

const _$MarkIntensityEnumMap = {
  MarkIntensity.short: 'short',
  MarkIntensity.full: 'full',
};
