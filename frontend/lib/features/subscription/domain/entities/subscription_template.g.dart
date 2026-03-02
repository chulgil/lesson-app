// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionTemplateAdapter extends TypeAdapter<SubscriptionTemplate> {
  @override
  final int typeId = 96;

  @override
  SubscriptionTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionTemplate(
      id: fields[0] as String,
      ownerId: fields[1] as String,
      ownerType: fields[2] as SubscriptionTemplateOwnerType,
      name: fields[3] as String,
      totalLessons: fields[4] as int,
      lessonDurationMinutes: fields[5] as int,
      validityDays: fields[6] as int,
      price: fields[7] as int,
      isActive: fields[8] as bool,
      displayOrder: fields[9] as int,
      description: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime?,
      rescheduleAllowance: fields[13] as int,
      isAutoProposalEnabled: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionTemplate obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerId)
      ..writeByte(2)
      ..write(obj.ownerType)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.totalLessons)
      ..writeByte(5)
      ..write(obj.lessonDurationMinutes)
      ..writeByte(6)
      ..write(obj.validityDays)
      ..writeByte(7)
      ..write(obj.price)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.displayOrder)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.rescheduleAllowance)
      ..writeByte(14)
      ..write(obj.isAutoProposalEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionTemplateOwnerTypeAdapter
    extends TypeAdapter<SubscriptionTemplateOwnerType> {
  @override
  final int typeId = 95;

  @override
  SubscriptionTemplateOwnerType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionTemplateOwnerType.teacher;
      case 1:
        return SubscriptionTemplateOwnerType.academy;
      default:
        return SubscriptionTemplateOwnerType.teacher;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionTemplateOwnerType obj) {
    switch (obj) {
      case SubscriptionTemplateOwnerType.teacher:
        writer.writeByte(0);
        break;
      case SubscriptionTemplateOwnerType.academy:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionTemplateOwnerTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionTemplate _$SubscriptionTemplateFromJson(
        Map<String, dynamic> json) =>
    SubscriptionTemplate(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      ownerType: $enumDecode(
          _$SubscriptionTemplateOwnerTypeEnumMap, json['owner_type']),
      name: json['name'] as String,
      totalLessons: (json['total_lessons'] as num).toInt(),
      lessonDurationMinutes: (json['lesson_duration_minutes'] as num).toInt(),
      validityDays: (json['validity_days'] as num).toInt(),
      price: (json['price'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      rescheduleAllowance: (json['reschedule_allowance'] as num?)?.toInt() ?? 2,
      isAutoProposalEnabled: json['is_auto_proposal_enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$SubscriptionTemplateToJson(
        SubscriptionTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'owner_type': _$SubscriptionTemplateOwnerTypeEnumMap[instance.ownerType]!,
      'name': instance.name,
      'total_lessons': instance.totalLessons,
      'lesson_duration_minutes': instance.lessonDurationMinutes,
      'validity_days': instance.validityDays,
      'price': instance.price,
      'is_active': instance.isActive,
      'display_order': instance.displayOrder,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'reschedule_allowance': instance.rescheduleAllowance,
      'is_auto_proposal_enabled': instance.isAutoProposalEnabled,
    };

const _$SubscriptionTemplateOwnerTypeEnumMap = {
  SubscriptionTemplateOwnerType.teacher: 'teacher',
  SubscriptionTemplateOwnerType.academy: 'academy',
};
