// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_ledger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeLedger _$PracticeLedgerFromJson(Map<String, dynamic> json) =>
    PracticeLedger(
      childProfileId: json['child_profile_id'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      marks: (json['marks'] as List<dynamic>?)
              ?.map((e) => PracticeMark.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      seals: (json['seals'] as List<dynamic>?)
              ?.map((e) => GuardianSeal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      endorsements: (json['endorsements'] as List<dynamic>?)
              ?.map((e) => Endorsement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PracticeLedgerToJson(PracticeLedger instance) =>
    <String, dynamic>{
      'child_profile_id': instance.childProfileId,
      'year': instance.year,
      'month': instance.month,
      'marks': instance.marks.map((e) => e.toJson()).toList(),
      'seals': instance.seals.map((e) => e.toJson()).toList(),
      'endorsements': instance.endorsements.map((e) => e.toJson()).toList(),
    };
