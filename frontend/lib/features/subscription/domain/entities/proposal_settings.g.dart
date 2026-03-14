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
      autoRenewalEnabled: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProposalSettings obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.autoRenewalEnabled);
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
      teacherId: json['teacher_id'] as String,
      autoProposalEnabled: json['auto_proposal_enabled'] as bool? ?? true,
      autoProposalTemplateIds:
          (json['auto_proposal_template_ids'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      recommendedTemplateId: json['recommended_template_id'] as String?,
      goldenTimeDiscountPercent:
          (json['golden_time_discount_percent'] as num?)?.toInt() ?? 10,
      goldenTimeHours: (json['golden_time_hours'] as num?)?.toInt() ?? 24,
      autoReminderEnabled: json['auto_reminder_enabled'] as bool? ?? true,
      reminderHours: (json['reminder_hours'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [24, 48, 72],
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      autoRenewalEnabled: json['auto_renewal_enabled'] as bool? ?? false,
    );

Map<String, dynamic> _$ProposalSettingsToJson(ProposalSettings instance) =>
    <String, dynamic>{
      'teacher_id': instance.teacherId,
      'auto_proposal_enabled': instance.autoProposalEnabled,
      'auto_proposal_template_ids': instance.autoProposalTemplateIds,
      'recommended_template_id': instance.recommendedTemplateId,
      'golden_time_discount_percent': instance.goldenTimeDiscountPercent,
      'golden_time_hours': instance.goldenTimeHours,
      'auto_reminder_enabled': instance.autoReminderEnabled,
      'reminder_hours': instance.reminderHours,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'auto_renewal_enabled': instance.autoRenewalEnabled,
    };
