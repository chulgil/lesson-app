// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProposalSettingsAdapter extends TypeAdapter<ProposalSettings> {
  @override
  final int typeId = 98;

  @override
  ProposalSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProposalSettings(
      teacherId: fields[0] as String,
      autoProposalEnabled: fields[1] as bool,
      autoProposalTemplateIds: (fields[2] as List).cast<String>(),
      recommendedTemplateId: fields[3] as String?,
      goldenTimeDiscountPercent: fields[4] as int,
      goldenTimeHours: fields[5] as int,
      autoReminderEnabled: fields[6] as bool,
      reminderHours: (fields[7] as List).cast<int>(),
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProposalSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.teacherId)
      ..writeByte(1)
      ..write(obj.autoProposalEnabled)
      ..writeByte(2)
      ..write(obj.autoProposalTemplateIds)
      ..writeByte(3)
      ..write(obj.recommendedTemplateId)
      ..writeByte(4)
      ..write(obj.goldenTimeDiscountPercent)
      ..writeByte(5)
      ..write(obj.goldenTimeHours)
      ..writeByte(6)
      ..write(obj.autoReminderEnabled)
      ..writeByte(7)
      ..write(obj.reminderHours)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProposalSettings _$ProposalSettingsFromJson(Map<String, dynamic> json) =>
    ProposalSettings(
      teacherId: json['teacherId'] as String,
      autoProposalEnabled: json['autoProposalEnabled'] as bool? ?? true,
      autoProposalTemplateIds:
          (json['autoProposalTemplateIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      recommendedTemplateId: json['recommendedTemplateId'] as String?,
      goldenTimeDiscountPercent:
          (json['goldenTimeDiscountPercent'] as num?)?.toInt() ?? 10,
      goldenTimeHours: (json['goldenTimeHours'] as num?)?.toInt() ?? 24,
      autoReminderEnabled: json['autoReminderEnabled'] as bool? ?? true,
      reminderHours: (json['reminderHours'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [24, 48, 72],
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProposalSettingsToJson(ProposalSettings instance) =>
    <String, dynamic>{
      'teacherId': instance.teacherId,
      'autoProposalEnabled': instance.autoProposalEnabled,
      'autoProposalTemplateIds': instance.autoProposalTemplateIds,
      'recommendedTemplateId': instance.recommendedTemplateId,
      'goldenTimeDiscountPercent': instance.goldenTimeDiscountPercent,
      'goldenTimeHours': instance.goldenTimeHours,
      'autoReminderEnabled': instance.autoReminderEnabled,
      'reminderHours': instance.reminderHours,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
